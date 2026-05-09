import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/live_dot.dart';
import '../../../../data/models/sensor_data_model.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../stations/presentation/providers/station_providers.dart';
import '../providers/active_session_provider.dart';
import '../providers/charging_providers.dart';
import '../widgets/sensor_card_widget.dart';
import '../widgets/power_chart_widget.dart';

class ChargingSessionPage extends ConsumerStatefulWidget {
  final String stationId;
  const ChargingSessionPage({super.key, required this.stationId});

  @override
  ConsumerState<ChargingSessionPage> createState() =>
      _ChargingSessionPageState();
}

class _ChargingSessionPageState extends ConsumerState<ChargingSessionPage> {
  String? _sessionId;
  DateTime? _sessionStart;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  List<double> _history = List.filled(30, 0);
  bool _showStop = false;
  bool _starting = true;
  bool _stopping = false;
  bool _autoStopped = false;
  String? _startError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  Future<void> _initSession() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) {
      setState(() {
        _starting = false;
        _startError = 'Anda belum login.';
      });
      return;
    }

    final existing = ref.read(activeSessionProvider);
    if (existing != null && existing.stationId == widget.stationId) {
      // Resume existing session
      _sessionId = existing.sessionId;
      _sessionStart = existing.startedAt;
      _startTicker();
      setState(() => _starting = false);
      return;
    }
    if (existing != null && existing.stationId != widget.stationId) {
      setState(() {
        _starting = false;
        _startError =
            'Anda memiliki sesi aktif di stasiun ${existing.stationId}. Selesaikan dulu.';
      });
      return;
    }

    try {
      final sessionId =
          await ref.read(chargingServiceProvider).startSession(
                userId: authUser.uid,
                stationId: widget.stationId,
              );
      if (!mounted) return;
      _sessionId = sessionId;
      _sessionStart = DateTime.now();
      _startTicker();
      setState(() => _starting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _startError = 'Gagal memulai sesi: $e';
      });
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sessionStart == null) return;
      setState(() {
        _elapsedSeconds =
            DateTime.now().difference(_sessionStart!).inSeconds;
      });
    });
  }

  Future<void> _autoStop() async {
    if (_stopping || _autoStopped) return;
    _autoStopped = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saldo habis. Sesi dihentikan otomatis.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ));
    }
    await _confirmStop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirmStop() async {
    if (_stopping || _sessionId == null) return;
    final authUser = ref.read(authStateProvider).valueOrNull;
    final station = ref.read(stationByIdProvider(widget.stationId)).valueOrNull;
    if (authUser == null || station == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data sesi tidak lengkap.')),
      );
      return;
    }
    setState(() {
      _stopping = true;
      _showStop = false;
    });
    try {
      final result = await ref.read(chargingServiceProvider).stopSession(
            userId: authUser.uid,
            stationId: widget.stationId,
            sessionId: _sessionId!,
            tariff: station.tariff,
          );
      if (!mounted) return;
      _ticker?.cancel();
      context.go(RouteNames.sessionReceipt, extra: {
        'transactionId': result.transactionId,
        'stationId': widget.stationId,
        'tariff': station.tariff,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stopping = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menghentikan sesi: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_startError != null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 56),
                const SizedBox(height: 12),
                Text(_startError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go(RouteNames.userDashboard),
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    ref.listen(sensorStreamProvider(widget.stationId), (prev, next) {
      next.whenData((sensor) {
        if (!mounted) return;
        if (sensor.power > 0) {
          setState(() {
            _history = [..._history.skip(1), sensor.power];
          });
        }
        // Auto-stop kalau saldo habis
        final user = ref.read(currentUserDataProvider).valueOrNull;
        final st = ref.read(stationByIdProvider(widget.stationId)).valueOrNull;
        if (user == null || st == null) return;
        final cost = sensor.energyKwh * st.tariff;
        if (cost >= user.balance && !_autoStopped && !_stopping) {
          _autoStop();
        }
      });
    });

    final sensor = ref.watch(sensorStreamProvider(widget.stationId)).valueOrNull ??
        SensorDataModel.empty;
    final user = ref.watch(currentUserDataProvider).valueOrNull;
    final station = ref.watch(stationByIdProvider(widget.stationId)).valueOrNull;

    final tariff = station?.tariff ?? 0;
    final cost = sensor.energyKwh * tariff;
    final balance = (user?.balance ?? 0).toDouble();
    final remaining = balance - cost;
    final usedFraction =
        balance > 0 ? (cost / balance).clamp(0.0, 1.0).toDouble() : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: _StationBanner(
                            id: widget.stationId,
                            slot: station?.slot ?? '',
                            address: station?.address ?? '',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                            children: [
                              SensorCardWidget(
                                icon: Icons.bolt_rounded,
                                value: sensor.voltage.toStringAsFixed(1),
                                unit: 'Volt',
                                label: 'Tegangan',
                                tone: SensorTone.warn,
                              ),
                              SensorCardWidget(
                                icon: Icons.waves_rounded,
                                value: sensor.current.toStringAsFixed(2),
                                unit: 'Ampere',
                                label: 'Arus',
                                tone: SensorTone.info,
                              ),
                              SensorCardWidget(
                                icon: Icons.power_settings_new_rounded,
                                value:
                                    (sensor.power / 1000).toStringAsFixed(2),
                                unit: 'kW',
                                label: 'Daya',
                                tone: SensorTone.primary,
                              ),
                              SensorCardWidget(
                                icon: Icons.battery_charging_full_rounded,
                                value: sensor.energyKwh.toStringAsFixed(3),
                                unit: 'kWh',
                                label: 'Energi',
                                tone: SensorTone.success,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: PowerChartWidget(
                              history: _history, currentWatt: sensor.power),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _SessionInfoCard(
                            elapsed: _elapsedSeconds,
                            cost: cost,
                            remaining: remaining,
                            usedFraction: usedFraction,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _stopping
                                      ? null
                                      : () =>
                                          setState(() => _showStop = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppSizes.rLg),
                                    ),
                                  ),
                                  child: _stopping
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : const Text('Hentikan Pengisian',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pastikan kendaraan Anda sudah cukup terisi',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showStop)
              _StopDialog(
                energy: sensor.energyKwh,
                cost: cost,
                onCancel: () => setState(() => _showStop = false),
                onConfirm: _confirmStop,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppColors.bgLight,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showStop = true),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.rMd),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LiveDot(color: AppColors.primary, size: 8),
                SizedBox(width: 8),
                Text('Sedang Mengisi',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _StationBanner extends StatelessWidget {
  final String id;
  final String slot;
  final String address;
  const _StationBanner({
    required this.id,
    required this.slot,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppSizes.rLg),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSizes.rMd),
            ),
            child: const Icon(Icons.bolt_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$id${slot.isEmpty ? '' : ' — $slot'}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(address.isEmpty ? '—' : address,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text('AKTIF',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SessionInfoCard extends StatelessWidget {
  final int elapsed;
  final double cost;
  final double remaining;
  final double usedFraction;

  const _SessionInfoCard({
    required this.elapsed,
    required this.cost,
    required this.remaining,
    required this.usedFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.rLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text('Durasi',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.duration(elapsed),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Biaya',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(cost),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usedFraction,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Sisa Saldo: ${AppFormatters.currency(remaining)}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopDialog extends StatelessWidget {
  final double energy;
  final double cost;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _StopDialog({
    required this.energy,
    required this.cost,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 28, color: AppColors.warning),
                ),
                const SizedBox(height: 12),
                const Text('Hentikan Pengisian?',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Energi: ${energy.toStringAsFixed(3)} kWh · Biaya: ${AppFormatters.currency(cost)}\nSaldo akan dipotong segera.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.rLg),
                          ),
                        ),
                        child: const Text('Lanjutkan'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.rLg),
                          ),
                        ),
                        child: const Text('Ya, Hentikan',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
