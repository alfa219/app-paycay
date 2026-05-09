import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../router/route_names.dart';

class ScanStationPage extends StatefulWidget {
  const ScanStationPage({super.key});

  @override
  State<ScanStationPage> createState() => _ScanStationPageState();
}

class _ScanStationPageState extends State<ScanStationPage> {
  final _codeCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Kode stasiun wajib diisi.');
      return;
    }
    if (!RegExp(r'^STN\d{3,}$').hasMatch(code)) {
      setState(() => _error = 'Format kode salah. Contoh: STN001');
      return;
    }
    context.go(RouteNames.stationMap, extra: {'selectedStation': code});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar(
              title: 'Cari Stasiun',
              onBack: () => context.go(RouteNames.userDashboard),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2_rounded,
                          size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Masukkan Kode Stasiun',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kode tertera di label QR pada stasiun. Format: STN diikuti 3 digit angka.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Kode Stasiun',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _codeCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9]')),
                        LengthLimitingTextInputFormatter(8),
                      ],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: STN001',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        errorText: _error,
                        hintStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          letterSpacing: 1,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text(
                          'Cari Stasiun',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.rLg),
                        border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.info),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Scan QR via kamera akan tersedia di update mendatang.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
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
}
