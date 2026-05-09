import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/live_dot.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../charging/presentation/providers/active_session_provider.dart';
import '../../../history/presentation/providers/transaction_providers.dart';
import '../../../stations/presentation/providers/station_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/station_card.dart';
import '../widgets/transaction_row.dart';

class UserDashboardPage extends ConsumerStatefulWidget {
  const UserDashboardPage({super.key});

  @override
  ConsumerState<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends ConsumerState<UserDashboardPage> {
  bool _seeding = false;

  Future<void> _seedStations() async {
    if (_seeding) return;
    setState(() => _seeding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await ref.read(stationServiceProvider).seedSampleStations();
      messenger.showSnackBar(
        SnackBar(
          content: Text(n == 0
              ? 'Stasiun sudah ada, tidak ada yang ditambahkan.'
              : 'Berhasil menambahkan $n stasiun.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal seed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDataProvider).valueOrNull;
    final balance = user?.balance ?? 0;
    final rfid = user?.rfid.isEmpty ?? true ? '—' : user!.rfid;
    final stationsAsync = ref.watch(stationsStreamProvider);
    final txAsync = ref.watch(userTransactionsStreamProvider);
    final stations = stationsAsync.valueOrNull ?? const [];
    final transactions = txAsync.valueOrNull ?? const [];
    final isStationsLoading = stationsAsync.isLoading;
    final isTxLoading = txAsync.isLoading;
    final active = ref.watch(activeSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(user?.name ?? '', user?.firstName ?? ''),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(stationsStreamProvider);
                  ref.invalidate(userTransactionsStreamProvider);
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Balance card
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: BalanceCard(
                            balance: balance.toDouble(), rfid: rfid),
                      ),
                    ),

                    // Active session banner — auto-detected
                    if (active != null)
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: _ActiveSessionBanner(
                            stationId: active.stationId,
                            elapsed: DateTime.now()
                                .difference(active.startedAt)
                                .inSeconds,
                            energyKwh: active.accumulatedKwh,
                            onTap: () => context.go(
                                RouteNames.chargingSession,
                                extra: {'stationId': active.stationId}),
                          ),
                        ),
                      ),

                    // Nearby stations
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: SectionHeader(
                        title: 'Stasiun Terdekat',
                        action: 'Lihat Semua',
                        onAction: () => context.go(RouteNames.stationMap),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 280),
                      child: SizedBox(
                        height: 152,
                        child: isStationsLoading
                            ? ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                itemCount: 4,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, __) => const ShimmerBox(
                                  width: 160,
                                  height: 152,
                                  radius: 16,
                                ),
                              )
                            : stations.isEmpty
                                ? _StationsEmptyState(
                                    seeding: _seeding,
                                    onSeed: _seedStations,
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    itemCount: stations.length > 4
                                        ? 4
                                        : stations.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (_, i) => StationCard(
                                      station: stations[i],
                                      onTap: () => context.go(
                                          RouteNames.stationMap,
                                          extra: {
                                            'selectedStation': stations[i].id
                                          }),
                                    ),
                                  ),
                      ),
                    ),

                    // Recent activity
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 360),
                      child: SectionHeader(
                        title: 'Aktivitas Terbaru',
                        action: 'Semua',
                        onAction: () => context.go(RouteNames.history),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.rLg),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 12,
                                offset: Offset(0, 4))
                          ],
                        ),
                        child: isTxLoading
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: List.generate(3, (i) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          top: i == 0 ? 0 : 14),
                                      child: Row(
                                        children: [
                                          const ShimmerBox(
                                              width: 44,
                                              height: 44,
                                              radius: 12),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
                                                ShimmerBox(
                                                    width: 140,
                                                    height: 12,
                                                    radius: 4),
                                                SizedBox(height: 6),
                                                ShimmerBox(
                                                    width: 90,
                                                    height: 10,
                                                    radius: 4),
                                              ],
                                            ),
                                          ),
                                          const ShimmerBox(
                                              width: 70,
                                              height: 14,
                                              radius: 4),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              )
                            : transactions.isEmpty
                                ? const EmptyState(
                                    icon: Icons.receipt_long_rounded,
                                    title: 'Belum ada transaksi',
                                    subtitle:
                                        'Mulai charging atau top-up untuk\nmelihat aktivitas di sini.',
                                    padding: EdgeInsets.symmetric(
                                        vertical: 24, horizontal: 16),
                                  )
                                : Column(
                                    children: List.generate(
                                      transactions.length > 3
                                          ? 3
                                          : transactions.length,
                                      (i) => Column(
                                        children: [
                                          if (i > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 68),
                                              child: Container(
                                                  height: 1,
                                                  color: AppColors.border),
                                            ),
                                          TransactionRow(
                                              tx: transactions[i]),
                                        ],
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    ),

                    const SizedBox(height: 110),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String name, String firstName) {
    return Container(
      color: AppColors.bgLight,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          UserAvatar(name: name.isEmpty ? '?' : name, size: 36),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selamat datang', style: AppTextStyles.caption),
              Text(
                firstName.isEmpty ? 'Halo!' : 'Halo, $firstName!',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.rMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                const Center(
                    child: Icon(Icons.notifications_outlined,
                        size: 20, color: AppColors.textPrimary)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationsEmptyState extends StatelessWidget {
  final bool seeding;
  final VoidCallback onSeed;
  const _StationsEmptyState({required this.seeding, required this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSizes.rMd),
              ),
              child: const Icon(Icons.ev_station_rounded,
                  color: AppColors.primaryDark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum ada stasiun',
                      style: AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Tap untuk tambah 5 stasiun contoh.',
                      style: AppTextStyles.body2
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: seeding ? null : onSeed,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.rMd)),
              ),
              child: seeding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Seed', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  final String stationId;
  final int elapsed;
  final double energyKwh;
  final VoidCallback onTap;
  const _ActiveSessionBanner({
    required this.stationId,
    required this.elapsed,
    required this.energyKwh,
    required this.onTap,
  });

  String _formatDuration(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSizes.rMd),
              ),
              child: const Icon(Icons.bolt_rounded,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const LiveDot(color: AppColors.primary, size: 6),
                      const SizedBox(width: 6),
                      Text('Sedang Mengisi',
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$stationId · ${energyKwh.toStringAsFixed(2)} kWh · ${_formatDuration(elapsed)}',
                    style: AppTextStyles.body2
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
