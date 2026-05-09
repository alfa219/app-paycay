import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../router/route_names.dart';
import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });

    bool err = false;
    if (name.isEmpty) {
      setState(() => _nameError = 'Nama wajib diisi.');
      err = true;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Email wajib diisi.');
      err = true;
    } else if (!email.contains('@')) {
      setState(() => _emailError = 'Format email tidak valid.');
      err = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password wajib diisi.');
      err = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password minimal 6 karakter.');
      err = true;
    }
    if (confirm != password) {
      setState(() => _confirmError = 'Konfirmasi password tidak cocok.');
      err = true;
    }
    if (err) return;

    setState(() => _loading = true);
    final auth = ref.read(authServiceProvider);
    final users = ref.read(userServiceProvider);
    try {
      final cred = await auth.signUp(email: email, password: password);
      final uid = cred.user?.uid;
      if (uid == null) throw Exception('Gagal mendapatkan UID akun.');

      await users.createUserDoc(uid: uid, name: name, email: email);

      if (mounted) context.go(RouteNames.userDashboard);
    } catch (e) {
      if (mounted) {
        final msg = auth.mapErrorToIndonesian(e);
        setState(() {
          if (msg.toLowerCase().contains('email')) {
            _emailError = msg;
          } else if (msg.toLowerCase().contains('password')) {
            _passwordError = msg;
          } else {
            _emailError = msg;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
              Text('Buat Akun Baru', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text('Daftarkan diri Anda ke PAYCAY',
                  style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              _field('Nama Lengkap', _nameCtrl,
                  hint: 'Budi Santoso',
                  icon: Icons.person_outline_rounded,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() => _nameError = null);
                    }
                  }),
              const SizedBox(height: 14),
              _field('Email', _emailCtrl,
                  hint: 'nama@email.com',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  }),
              const SizedBox(height: 14),
              _field('Password', _passCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  toggleObscure: () => setState(() => _obscure = !_obscure)),
              const SizedBox(height: 14),
              _field('Konfirmasi Password', _confirmCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  errorText: _confirmError,
                  onChanged: (_) {
                    if (_confirmError != null) {
                      setState(() => _confirmError = null);
                    }
                  }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Daftar Sekarang', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? ',
                      style: AppTextStyles.body1
                          .copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go(RouteNames.login),
                    child: Text('Masuk',
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            errorText: errorText,
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20),
                    onPressed: toggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
