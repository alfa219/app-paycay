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
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/transaction_row.dart';
import '../../../history/presentation/providers/transaction_providers.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDataProvider).valueOrNull;
    final balance = (user?.balance ?? 0).toDouble();
    final rfid = user?.rfid.isEmpty ?? true ? '—' : user!.rfid;
    final txAsync = ref.watch(userTransactionsStreamProvider);
    final allTx = txAsync.valueOrNull ?? const [];
    final isTxLoading = txAsync.isLoading;
    final topups = allTx.where((t) => t.type == 'topup').toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar(
              title: 'Dompet Saya',
              onBack: () => context.go(RouteNames.userDashboard),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(userTransactionsStreamProvider);
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                  children: [
                    // Hero balance card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryDark, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(AppSizes.rLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.28),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30,
                              bottom: -30,
                              child: Icon(
                                Icons.bolt_rounded,
                                size: 180,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Saldo Aktif',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.7))),
                                const SizedBox(height: 6),
                                Text(
                                  AppFormatters.currency(balance),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _CardBtn(
                                        icon: Icons.arrow_upward_rounded,
                                        label: 'Top Up',
                                        onTap: () => context.go(RouteNames.topupRequest),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _CardBtn(
                                        icon: Icons.receipt_long_rounded,
                                        label: 'Riwayat',
                                        onTap: () => context.go(RouteNames.history),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // RFID card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.rLg),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(AppSizes.rMd),
                              ),
                              child: const Icon(Icons.credit_card_rounded,
                                  size: 22, color: AppColors.primaryDark),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kartu RFID Terdaftar',
                                      style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    rfid,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),

                    // Top-up history
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('Riwayat Top Up', style: AppTextStyles.h3),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.go(RouteNames.history),
                            child: Text('Semua',
                                style: AppTextStyles.body2.copyWith(
                                    color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.rLg),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: isTxLoading
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: List.generate(2, (i) => Padding(
                                    padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                                    child: Row(
                                      children: const [
                                        ShimmerBox(width: 44, height: 44, radius: 12),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ShimmerBox(width: 140, height: 12, radius: 4),
                                              SizedBox(height: 6),
                                              ShimmerBox(width: 90, height: 10, radius: 4),
                                            ],
                                          ),
                                        ),
                                        ShimmerBox(width: 70, height: 14, radius: 4),
                                      ],
                                    ),
                                  )),
                                ),
                              )
                            : topups.isEmpty
                                ? const EmptyState(
                                    icon: Icons.account_balance_wallet_rounded,
                                    title: 'Belum ada top-up',
                                    subtitle: 'Riwayat top-up Anda\nakan muncul di sini.',
                                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                  )
                                : Column(
                                    children: List.generate(topups.length, (i) => Column(
                                      children: [
                                        if (i > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 68),
                                            child: Container(height: 1, color: AppColors.border),
                                          ),
                                        TransactionRow(tx: topups[i]),
                                      ],
                                    )),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
}

class _CardBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CardBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppSizes.rMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
