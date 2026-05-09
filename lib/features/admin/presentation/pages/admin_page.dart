import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../stations/presentation/providers/station_providers.dart';
import '../../../wallet/presentation/providers/topup_providers.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar(
              title: 'Admin Panel',
              onBack: () => context.go(RouteNames.profile),
            ),
            Container(
              color: AppColors.bgLight,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Dashboard', icon: Icon(Icons.dashboard_rounded, size: 18)),
                  Tab(text: 'Top-up', icon: Icon(Icons.payments_rounded, size: 18)),
                  Tab(text: 'Stasiun', icon: Icon(Icons.ev_station_rounded, size: 18)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _DashboardTab(),
                  _TopupApprovalTab(),
                  _StationManagementTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsStreamProvider).valueOrNull ?? const [];
    final pendingCount =
        ref.watch(pendingTopupsCountProvider).valueOrNull ?? 0;

    final available =
        stations.where((s) => s.status == 'available').length;
    final charging = stations.where((s) => s.status == 'charging').length;
    final offline = stations.where((s) => s.status == 'offline').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                label: 'Total Stasiun',
                value: '${stations.length}',
                icon: Icons.ev_station_rounded,
                color: AppColors.primary,
              ),
              _StatCard(
                label: 'Tersedia',
                value: '$available',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
              _StatCard(
                label: 'Sedang Mengisi',
                value: '$charging',
                icon: Icons.bolt_rounded,
                color: AppColors.info,
              ),
              _StatCard(
                label: 'Offline',
                value: '$offline',
                icon: Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            label: 'Top-up Menunggu Approval',
            value: '$pendingCount',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.warning,
            wide: true,
          ),
          const SizedBox(height: 24),
          const Text('Status Stasiun',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (stations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Belum ada stasiun')),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.rLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: List.generate(stations.length, (i) {
                  final s = stations[i];
                  return Column(
                    children: [
                      if (i > 0)
                        Container(
                            height: 1,
                            color: AppColors.border,
                            margin: const EdgeInsets.only(left: 16)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.stationStatusColor(s.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('${s.id} — ${s.slot}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Text(s.address,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Text(s.status,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors
                                        .stationStatusColor(s.status))),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.rLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.rMd),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top-up Approval Tab ──────────────────────────────────────────────────────

class _TopupApprovalTab extends ConsumerWidget {
  const _TopupApprovalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingTopupsStreamProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 56, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('Tidak ada top-up pending',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _PendingTopupCard(data: list[i]),
        );
      },
    );
  }
}

class _PendingTopupCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const _PendingTopupCard({required this.data});

  @override
  ConsumerState<_PendingTopupCard> createState() =>
      _PendingTopupCardState();
}

class _PendingTopupCardState extends ConsumerState<_PendingTopupCard> {
  bool _busy = false;

  Future<void> _approve() async {
    if (_busy) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(topupServiceProvider).approveOne(
            requestId: widget.data['id'] as String,
            adminUserId: auth.uid,
          );
      messenger.showSnackBar(const SnackBar(
        content: Text('Top-up disetujui'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Gagal: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    if (_busy) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(topupServiceProvider).rejectOne(
            requestId: widget.data['id'] as String,
            adminUserId: auth.uid,
            reason: 'Rejected by admin',
          );
      messenger.showSnackBar(const SnackBar(
        content: Text('Top-up ditolak'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Gagal: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final amount = (d['amount'] as num?)?.toInt() ?? 0;
    final methodName = d['methodName'] as String? ?? '—';
    final userId = d['userId'] as String? ?? '';
    final ts = d['requestedAt'];
    final requested = ts is Timestamp
        ? AppFormatters.relativeTime(ts.toDate())
        : 'baru saja';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.rLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.rMd),
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppFormatters.currency(amount),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('$methodName · $requested',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(AppSizes.rSm),
            ),
            child: Text('User: $userId',
                style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _reject,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.rMd)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _approve,
                  icon: _busy
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.rMd)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Station Management Tab ───────────────────────────────────────────────────

class _StationManagementTab extends ConsumerWidget {
  const _StationManagementTab();

  static const _statuses = ['available', 'charging', 'offline', 'maintenance'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsStreamProvider).valueOrNull ?? const [];

    if (stations.isEmpty) {
      return const Center(child: Text('Belum ada stasiun'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = stations[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.rLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.stationStatusColor(s.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${s.id} — ${s.slot}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(AppFormatters.currency(s.tariff),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Text(s.address,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _statuses.map((status) {
                  final selected = s.status == status;
                  return GestureDetector(
                    onTap: selected
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(stationServiceProvider)
                                  .updateStatus(s.id, status);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Gagal: $e'),
                                        backgroundColor: AppColors.error,
                                        behavior:
                                            SnackBarBehavior.floating));
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.stationStatusColor(status)
                                .withValues(alpha: 0.15)
                            : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: selected
                                ? AppColors.stationStatusColor(status)
                                : AppColors.border),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.stationStatusColor(status)
                                : AppColors.textSecondary),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
