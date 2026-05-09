import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../router/route_names.dart';
import '../../../stations/presentation/providers/station_providers.dart';
import '../providers/charging_providers.dart';

class SessionReceiptPage extends ConsumerWidget {
  final Map<String, dynamic>? sessionData;
  const SessionReceiptPage({super.key, this.sessionData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txId = sessionData?['transactionId'] as String?;
    final stationId = sessionData?['stationId'] as String?;
    final tariff = (sessionData?['tariff'] as int?) ?? 0;

    if (txId == null || stationId == null) {
      return _ErrorScaffold(
        message: 'Data struk tidak lengkap.',
        onBack: () => context.go(RouteNames.userDashboard),
      );
    }

    final txAsync = ref.watch(transactionByIdProvider(txId));
    final station = ref.watch(stationByIdProvider(stationId)).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar(
              title: 'Struk Pengisian',
              onBack: () => context.go(RouteNames.userDashboard),
            ),
            Expanded(
              child: txAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorBody(
                  message: 'Gagal memuat struk: $e',
                  onBack: () => context.go(RouteNames.userDashboard),
                ),
                data: (tx) {
                  if (tx == null) {
                    return _ErrorBody(
                      message: 'Transaksi tidak ditemukan.',
                      onBack: () => context.go(RouteNames.userDashboard),
                    );
                  }
                  final cost = -tx.amount;
                  final balanceBefore = tx.balanceBefore ?? 0;
                  final balanceAfter = tx.balanceAfter ?? 0;
                  final energy = tx.energyKwh ?? 0;
                  final duration = tx.durationSeconds ?? 0;
                  final slot = station?.slot ?? '';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: _SuccessBanner(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSizes.rLg),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x0F000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Icon(Icons.bolt_rounded,
                                        size: 16, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('PAYCAY',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1)),
                                  const Spacer(),
                                  Text(
                                    tx.sessionId ?? tx.id,
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: _DashedDivider(),
                              ),
                              _Row(
                                  label: 'Stasiun',
                                  value: '$stationId${slot.isEmpty ? '' : ' — $slot'}'),
                              _Row(label: 'Tanggal', value: tx.date),
                              _Row(
                                  label: 'Durasi',
                                  value:
                                      AppFormatters.durationMinutes(duration)),
                              _Row(
                                  label: 'Energi',
                                  value: '${energy.toStringAsFixed(3)} kWh'),
                              _Row(
                                  label: 'Tarif',
                                  value:
                                      '${AppFormatters.currency(tariff)} / kWh'),
                              const Divider(
                                  height: 28, color: AppColors.border),
                              Row(
                                children: [
                                  const Text('Total Biaya',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  Text(AppFormatters.currency(cost),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _Row(
                                label: 'Saldo Sebelum',
                                value: AppFormatters.currency(balanceBefore),
                                muted: true,
                              ),
                              _Row(
                                label: 'Saldo Sesudah',
                                value: AppFormatters.currency(balanceAfter),
                                muted: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () =>
                                context.go(RouteNames.userDashboard),
                            child: const Text('Kembali ke Beranda',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.rLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pengisian Berhasil',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success)),
              SizedBox(height: 2),
              Text('Saldo telah dipotong otomatis',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorBody({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: onBack,
                child: const Text('Kembali ke Beranda')),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorScaffold({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: _ErrorBody(message: message, onBack: onBack),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  const _Row({required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w500,
                  color: muted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      const dashW = 6.0;
      const gap = 4.0;
      final count = (constraints.maxWidth / (dashW + gap)).floor();
      return Row(
        children: List.generate(
          count,
          (_) => Container(
            width: dashW,
            height: 1.5,
            margin: const EdgeInsets.only(right: gap),
            color: AppColors.border,
          ),
        ),
      );
    });
  }
}
