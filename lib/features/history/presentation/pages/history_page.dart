import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../router/route_names.dart';
import '../providers/transaction_providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _filter = 'all';

  static const _filters = [
    _FilterChip(id: 'all', label: 'Semua'),
    _FilterChip(id: 'charging', label: 'Pengisian'),
    _FilterChip(id: 'topup', label: 'Top Up'),
    _FilterChip(id: 'refund', label: 'Refund'),
  ];

  List<TransactionModel> _applyFilter(List<TransactionModel> all) {
    if (_filter == 'all') return all;
    return all.where((t) => t.type == _filter).toList();
  }

  Map<String, List<TransactionModel>> _group(List<TransactionModel> txs) {
    final result = <String, List<TransactionModel>>{};
    for (final tx in txs) {
      result.putIfAbsent(tx.monthGroup, () => []).add(tx);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(userTransactionsStreamProvider);
    final all = txAsync.valueOrNull ?? const <TransactionModel>[];
    final isLoading = txAsync.isLoading;
    final groups = _group(_applyFilter(all));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar(
              title: 'Riwayat Transaksi',
              onBack: () => context.go(RouteNames.userDashboard),
            ),
            // Filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final chip = _filters[i];
                  final selected = _filter == chip.id;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = chip.id),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        child: Text(chip.label),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(userTransactionsStreamProvider);
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: isLoading
                    ? _buildLoadingShimmer()
                    : groups.isEmpty
                        ? _buildEmptyScrollable()
                        : _buildList(groups),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScrollable() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'Belum ada transaksi',
          subtitle:
              'Mulai charging atau top-up\nuntuk melihat riwayat di sini.',
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 44, height: 44, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 160, height: 12, radius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 100, height: 10, radius: 4),
                ],
              ),
            ),
            const ShimmerBox(width: 80, height: 14, radius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Map<String, List<TransactionModel>> groups) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: groups.entries.map((entry) {
        final month = entry.key;
        final items = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Text(
                month.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
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
                children: List.generate(items.length, (i) {
                  return Column(
                    children: [
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 68),
                          child:
                              Container(height: 1, color: AppColors.border),
                        ),
                      _HistoryRow(tx: items[i]),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _FilterChip {
  final String id;
  final String label;
  const _FilterChip({required this.id, required this.label});
}

class _HistoryRow extends StatelessWidget {
  final TransactionModel tx;
  const _HistoryRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCharge = tx.type == 'charging';
    final tint = isCharge ? AppColors.primary : AppColors.success;
    final bgTint = tint.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(AppSizes.rMd),
            ),
            child: Icon(
              isCharge ? Icons.bolt_rounded : Icons.arrow_upward_rounded,
              size: 20,
              color: tint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.label,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${tx.date} · ${tx.sub}',
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.amount < 0 ? '' : '+'}${AppFormatters.currency(tx.amount.abs())}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tx.amount < 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Berhasil',
                style: TextStyle(
                    fontSize: 11, color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
