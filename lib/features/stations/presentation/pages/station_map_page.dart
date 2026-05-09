import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/station_model.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/station_providers.dart';

class StationMapPage extends ConsumerStatefulWidget {
  final String? selectedStationId;
  const StationMapPage({super.key, this.selectedStationId});

  @override
  ConsumerState<StationMapPage> createState() => _StationMapPageState();
}

class _StationMapPageState extends ConsumerState<StationMapPage> {
  String _filter = 'all';
  String _search = '';
  StationModel? _selected;
  bool _selectionInitialized = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleStart(StationModel station) {
    final user = ref.read(currentUserDataProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Anda belum login.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (user.balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saldo tidak cukup. Silakan top up dulu.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (station.status != 'available') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Stasiun tidak tersedia saat ini.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    context.go(RouteNames.chargingSession, extra: {'stationId': station.id});
  }

  List<StationModel> _applyFilters(List<StationModel> all) {
    return all.where((s) {
      if (_filter == 'available' && s.status != 'available') return false;
      if (_filter == 'charging' && s.status != 'charging') return false;
      if (_search.isNotEmpty &&
          !s.id.toLowerCase().contains(_search.toLowerCase()) &&
          !s.address.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsStreamProvider);
    final allStations = stationsAsync.valueOrNull ?? const <StationModel>[];
    final filtered = _applyFilters(allStations);

    if (!_selectionInitialized &&
        widget.selectedStationId != null &&
        allStations.isNotEmpty) {
      _selectionInitialized = true;
      _selected = allStations.firstWhere(
        (s) => s.id == widget.selectedStationId,
        orElse: () => allStations.first,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDDE5EC),
      body: Stack(
        children: [
          // Map background
          Positioned.fill(child: _MapBackground(stations: filtered, onSelect: (s) => setState(() => _selected = s))),

          // Search bar
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go(RouteNames.userDashboard),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSizes.rMd),
                            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSizes.rMd),
                            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _search = v),
                                  decoration: const InputDecoration(
                                    hintText: 'Cari stasiun...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    filled: false,
                                    hintStyle: TextStyle(fontSize: 14, color: AppColors.textDisabled),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter chips
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _Chip(label: 'Semua', active: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _Chip(label: 'Tersedia', active: _filter == 'available', onTap: () => setState(() => _filter = 'available')),
                      const SizedBox(width: 8),
                      _Chip(label: 'Sedang Mengisi', active: _filter == 'charging', onTap: () => setState(() => _filter = 'charging')),
                      const SizedBox(width: 8),
                      _Chip(label: 'Terdekat', active: _filter == 'nearby', onTap: () => setState(() => _filter = 'nearby')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // My location FAB
          if (_selected == null)
            Positioned(
              right: 16,
              bottom: 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 14, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.my_location_rounded, size: 22, color: AppColors.primary),
              ),
            ),

          // Bottom sheet
          if (_selected != null)
            _StationDetailSheet(
              station: _selected!,
              onClose: () => setState(() => _selected = null),
              onStart: () => _handleStart(_selected!),
            ),
        ],
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  final List<StationModel> stations;
  final ValueChanged<StationModel> onSelect;
  const _MapBackground({required this.stations, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid map bg
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8EEF3), Color(0xFFDDE5EC)]),
          ),
        ),
        CustomPaint(painter: _GridPainter(), size: Size.infinite),
        // Roads
        Positioned(left: 0, right: 0, top: 0, bottom: 0,
          child: Stack(children: [
            Positioned(left: 0, right: 0, top: MediaQuery.of(context).size.height * 0.40, child: Container(height: 14, color: Colors.white.withValues(alpha: 0.7))),
            Positioned(left: 0, right: 0, top: MediaQuery.of(context).size.height * 0.70, child: Container(height: 10, color: Colors.white.withValues(alpha: 0.7))),
            Positioned(top: 0, bottom: 0, left: MediaQuery.of(context).size.width * 0.40, child: Container(width: 14, color: Colors.white.withValues(alpha: 0.7))),
            Positioned(top: 0, bottom: 0, left: MediaQuery.of(context).size.width * 0.70, child: Container(width: 10, color: Colors.white.withValues(alpha: 0.7))),
          ]),
        ),
        // Station markers
        ...stations.map((s) {
          final color = AppColors.stationStatusColor(s.status);
          return Positioned(
            left: MediaQuery.of(context).size.width * s.posX / 100 - 18,
            top: MediaQuery.of(context).size.height * s.posY / 100 - 44,
            child: GestureDetector(
              onTap: () => onSelect(s),
              child: _MarkerWidget(color: color, status: s.status),
            ),
          );
        }),
        // My location dot
        Positioned(
          left: MediaQuery.of(context).size.width * 0.5 - 9,
          top: MediaQuery.of(context).size.height * 0.5 - 9,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 10, spreadRadius: 4)],
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF789CB0).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _MarkerWidget extends StatelessWidget {
  final Color color;
  final String status;
  const _MarkerWidget({required this.color, required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 44,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 12,
            child: CustomPaint(
              painter: _TrianglePainter(color: color),
              size: const Size(12, 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StationDetailSheet extends StatelessWidget {
  final StationModel station;
  final VoidCallback onClose;
  final VoidCallback onStart;
  const _StationDetailSheet({required this.station, required this.onClose, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final canStart = station.status == 'available';
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 30, offset: Offset(0, -10))],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${station.id} — ${station.slot}', style: AppTextStyles.h2),
                            const SizedBox(height: 4),
                            Text(station.address, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusBadge(status: station.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,
                    children: [
                      _InfoTile(icon: Icons.bolt_rounded, label: 'Tarif', value: '${AppFormatters.currency(station.tariff)}/kWh', tint: AppColors.primary),
                      _InfoTile(icon: Icons.power_settings_new_rounded, label: 'Daya Max', value: '${station.maxKw} kW', tint: AppColors.primary),
                      _InfoTile(icon: Icons.location_on_rounded, label: 'Jarak', value: station.distance, tint: AppColors.textPrimary),
                      _InfoTile(icon: Icons.access_time_rounded, label: 'Est. Waktu', value: '~30 mnt/kWh', tint: AppColors.textPrimary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canStart ? onStart : null,
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: const Text('Mulai Pengisian'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rLg)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  const _InfoTile({required this.icon, required this.label, required this.value, required this.tint});

  @override
  Widget build(BuildContext context) {
    final isAccented = tint == AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccented
            ? tint.withValues(alpha: 0.08)
            : AppColors.bgLight,
        borderRadius: BorderRadius.circular(AppSizes.rMd),
        border: Border.all(
            color: isAccented
                ? tint.withValues(alpha: 0.22)
                : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isAccented ? tint : AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
