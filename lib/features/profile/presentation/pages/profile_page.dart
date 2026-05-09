import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../charging/presentation/providers/charging_providers.dart';
import '../../../wallet/presentation/providers/topup_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _approving = false;

  Future<void> _approveAllPending() async {
    if (_approving) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth == null) return;
    setState(() => _approving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await ref
          .read(topupServiceProvider)
          .approveAllPending(auth.uid);
      messenger.showSnackBar(SnackBar(
        content: Text(n == 0
            ? 'Tidak ada top-up pending.'
            : 'Berhasil approve $n top-up.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Gagal approve: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDataProvider).valueOrNull;
    final name = user?.name ?? '—';
    final email = user?.email ?? '—';
    final phone = user?.phone.isEmpty ?? true ? '—' : user!.phone;
    final rfid = user?.rfid.isEmpty ?? true ? '—' : user!.rfid;
    final pendingCount =
        ref.watch(pendingTopupsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar(
              title: 'Profil Saya',
              onBack: () => context.go(RouteNames.userDashboard),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                child: Column(
                  children: [
                    // Avatar section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          UserAvatar(
                              name: name == '—' ? '?' : name, size: 88),
                          const SizedBox(height: 14),
                          Text(name, style: AppTextStyles.h2),
                          const SizedBox(height: 2),
                          Text(email,
                              style: AppTextStyles.body2
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info card
                    _Card(
                      children: [
                        _InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Nama Lengkap',
                          value: name,
                        ),
                        _Sep(),
                        _InfoRow(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: email,
                        ),
                        _Sep(),
                        _InfoRow(
                          icon: Icons.phone_rounded,
                          label: 'No. HP',
                          value: phone,
                        ),
                        _Sep(),
                        _InfoRow(
                          icon: Icons.credit_card_rounded,
                          label: 'RFID',
                          value: rfid,
                          mono: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Admin Panel button (only for admin role)
                    if (user?.role == 'admin') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(RouteNames.admin),
                          icon: const Icon(Icons.admin_panel_settings_rounded,
                              size: 18),
                          label: const Text('Admin Panel',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.rLg),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Dev Tools — approve pending top-ups
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.rLg),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.build_circle_outlined,
                                  size: 18, color: AppColors.warning),
                              const SizedBox(width: 8),
                              const Text('Dev Tools',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$pendingCount pending',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Approve semua request top-up manual yang pending. Hanya untuk testing — production butuh admin module.',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: (pendingCount == 0 || _approving)
                                  ? null
                                  : _approveAllPending,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                disabledBackgroundColor: AppColors.warning
                                    .withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.rMd)),
                              ),
                              child: _approving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      pendingCount == 0
                                          ? 'Tidak ada pending'
                                          : 'Approve $pendingCount Pending',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _showLogoutDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.rLg),
                          ),
                        ),
                        child: const Text(
                          'Keluar dari Akun',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: const Text(
          'Anda akan keluar dari sesi ini.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(chargingServiceProvider).abandonSession();
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(RouteNames.landing);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Keluar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared layout widgets ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Container(height: 1, color: AppColors.border),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.rSm),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: mono
                      ? const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)
                      : AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

