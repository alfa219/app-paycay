import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../router/route_names.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool hasErr = false;
    if (email.isEmpty) {
      setState(() => _emailError = 'Email wajib diisi.');
      hasErr = true;
    } else if (!email.contains('@')) {
      setState(() => _emailError = 'Format email tidak valid.');
      hasErr = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password wajib diisi.');
      hasErr = true;
    }
    if (hasErr) return;

    setState(() => _loading = true);
    final auth = ref.read(authServiceProvider);
    try {
      await auth.signIn(email: email, password: password);
      if (mounted) context.go(RouteNames.userDashboard);
    } catch (e) {
      if (mounted) {
        final msg = auth.mapErrorToIndonesian(e);
        setState(() {
          if (msg.toLowerCase().contains('email') &&
              !msg.toLowerCase().contains('password')) {
            _emailError = msg;
          } else {
            _passwordError = msg;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.go(RouteNames.landing),
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
              Text('Selamat Datang', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text('Masuk ke akun PAYCAY Anda',
                  style: AppTextStyles.body1
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 36),
              _Label('Email'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'nama@email.com',
                  prefixIcon:
                      const Icon(Icons.email_outlined, size: 20),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 16),
              _Label('Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _login(),
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go(RouteNames.forgotPassword),
                  child: Text('Lupa Password?',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Masuk', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun? ',
                      style: AppTextStyles.body1
                          .copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go(RouteNames.register),
                    child: Text('Daftar',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary));
  }
}
