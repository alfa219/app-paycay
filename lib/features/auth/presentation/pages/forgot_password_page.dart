import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../router/route_names.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _emailError;

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    setState(() => _emailError = null);

    if (email.isEmpty) {
      setState(() => _emailError = 'Email wajib diisi.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _emailError = 'Format email tidak valid.');
      return;
    }

    setState(() => _loading = true);
    final auth = ref.read(authServiceProvider);
    try {
      await auth.sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = auth.mapErrorToIndonesian(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? _SuccessView(onBack: () => context.go(RouteNames.login))
              : _FormView(
                  emailCtrl: _emailCtrl,
                  loading: _loading,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                  onBack: () => context.go(RouteNames.login),
                  onSend: _send,
                ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback onBack;
  final VoidCallback onSend;

  const _FormView({
    required this.emailCtrl,
    required this.loading,
    this.errorText,
    this.onChanged,
    required this.onBack,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.rMd),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              size: 32, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('Lupa Password?', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text(
          'Masukkan email Anda dan kami akan kirimkan link reset password.',
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        const Text('Email',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'nama@email.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            errorText: errorText,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : onSend,
            child: loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text('Kirim Link Reset', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onBack;
  const _SuccessView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 56, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text('Email Terkirim!', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Cek inbox email Anda untuk\nlink reset password.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onBack,
              child: Text('Kembali ke Login', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}
