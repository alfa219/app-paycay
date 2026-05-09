import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../core/widgets/success_check.dart';
import '../../../../data/constants/topup_methods.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/topup_providers.dart';

class TopupPage extends ConsumerStatefulWidget {
  const TopupPage({super.key});

  @override
  ConsumerState<TopupPage> createState() => _TopupPageState();
}

class _TopupPageState extends ConsumerState<TopupPage> {
  String _step = 'amount'; // amount → method → instructions → success
  int _amount = 0;
  String _methodId = 'bca';
  bool _hasProof = false;
  bool _submitting = false;
  String? _submitError;

  static const _quick = [25000, 50000, 100000, 200000, 500000];

  TopupMethod get _method =>
      kTopupMethods.firstWhere((m) => m.id == _methodId);

  int get _total => _amount + _method.fee;

  bool get _valid => _amount >= 10000;

  Future<void> _submit() async {
    if (_submitting) return;
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Anda belum login.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final topup = ref.read(topupServiceProvider);
    try {
      if (_method.isAuto) {
        await topup.submitAutoTopup(
          userId: authUser.uid,
          amount: _amount,
          method: _method,
        );
      } else {
        await topup.submitManualTopup(
          userId: authUser.uid,
          amount: _amount,
          method: _method,
        );
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = 'success';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal kirim: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _back() {
    if (_step == 'amount') {
      context.go(RouteNames.wallet);
    } else if (_step == 'method') {
      setState(() => _step = 'amount');
    } else if (_step == 'instructions') {
      setState(() => _step = 'method');
    } else {
      context.go(RouteNames.wallet);
    }
  }

  int get _stepIndex {
    switch (_step) {
      case 'amount':
        return 0;
      case 'method':
        return 1;
      case 'instructions':
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            SimpleAppBar(title: 'Top Up Saldo', onBack: _back),
            if (_step != 'success') _buildStepper(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    const labels = ['Nominal', 'Metode', 'Konfirmasi'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final lineIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: lineIdx < _stepIndex ? AppColors.primary : AppColors.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final active = idx <= _stepIndex;
          return Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                labels[idx],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 'amount':
        return _AmountStep(
          amount: _amount,
          quick: _quick,
          valid: _valid,
          onAmountChanged: (v) => setState(() => _amount = v),
          onNext: () => setState(() => _step = 'method'),
        );
      case 'method':
        return _MethodStep(
          amount: _amount,
          methodId: _methodId,
          onMethodChanged: (id) => setState(() => _methodId = id),
          onNext: () => setState(() => _step = 'instructions'),
        );
      case 'instructions':
        return _InstructionsStep(
          amount: _amount,
          method: _method,
          total: _total,
          hasProof: _hasProof,
          submitting: _submitting,
          onProofChanged: (v) => setState(() => _hasProof = v),
          onConfirm: _submit,
        );
      case 'success':
        return _SuccessStep(
          amount: _amount,
          method: _method,
          onBackToWallet: () => context.go(RouteNames.wallet),
          onViewHistory: () => context.go(RouteNames.history),
        );
      default:
        return const SizedBox();
    }
  }
}

// ─── Amount Step ─────────────────────────────────────────────────────────────

class _AmountStep extends StatefulWidget {
  final int amount;
  final List<int> quick;
  final bool valid;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onNext;

  const _AmountStep({
    required this.amount,
    required this.quick,
    required this.valid,
    required this.onAmountChanged,
    required this.onNext,
  });

  @override
  State<_AmountStep> createState() => _AmountStepState();
}

class _AmountStepState extends State<_AmountStep> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.amount == 0 ? '' : '${widget.amount}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final val = int.tryParse(digits) ?? 0;
    widget.onAmountChanged(val);
  }

  void _setQuick(int q) {
    _ctrl.text = '$q';
    _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length));
    widget.onAmountChanged(q);
  }

  @override
  Widget build(BuildContext context) {
    final belowMin = widget.amount > 0 && widget.amount < 10000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Nominal Top Up',
            style: AppTextStyles.label
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.rMd),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Rp',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onChanged,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Minimum Rp 10.000 · Maksimum Rp 5.000.000',
                style: TextStyle(
                    fontSize: 11,
                    color: belowMin ? AppColors.error : AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.quick.map((q) {
            final selected = widget.amount == q;
            return GestureDetector(
              onTap: () => _setQuick(q),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                  child: Text(AppFormatters.currency(q)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // Promo strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.rMd),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSizes.rSm),
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Promo: Top up Rp 100.000+',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Dapat cashback Rp 5.000 untuk pengguna baru',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: widget.valid ? widget.onNext : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Lanjut Pilih Metode',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Method Step ─────────────────────────────────────────────────────────────

class _MethodStep extends StatelessWidget {
  final int amount;
  final String methodId;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onNext;

  const _MethodStep({
    required this.amount,
    required this.methodId,
    required this.onMethodChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final groups = [
      _MethodGroup(kind: 'bank', label: 'Transfer Bank'),
      _MethodGroup(kind: 'ewallet', label: 'E-Wallet'),
      _MethodGroup(kind: 'rfid', label: 'Lainnya'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(AppSizes.rMd),
          ),
          child: Row(
            children: [
              Text('Top up sebesar',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85))),
              const Spacer(),
              Text(
                AppFormatters.currency(amount),
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        ...groups.map((g) {
          final methods =
              kTopupMethods.where((m) => m.kind == g.kind).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                g.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
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
                  children: List.generate(methods.length, (i) {
                    final m = methods[i];
                    return Column(
                      children: [
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 64),
                            child: Container(
                                height: 1, color: AppColors.border),
                          ),
                        _MethodRow(
                          method: m,
                          selected: methodId == m.id,
                          onSelect: () => onMethodChanged(m.id),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Lanjut',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _MethodGroup {
  final String kind;
  final String label;
  const _MethodGroup({required this.kind, required this.label});
}

class _MethodRow extends StatelessWidget {
  final TopupMethod method;
  final bool selected;
  final VoidCallback onSelect;

  const _MethodRow({
    required this.method,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(method.colorHex).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSizes.rMd),
              ),
              child: Center(
                child: method.iconData != null
                    ? Icon(method.iconData,
                        size: 20, color: Color(method.colorHex))
                    : Text(
                        method.logo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(method.colorHex),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name,
                      style: AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    method.fee > 0
                        ? '${method.sub} · Biaya admin ${AppFormatters.currency(method.fee)}'
                        : '${method.sub} · Gratis',
                    style: AppTextStyles.body2
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                          radius: 4, backgroundColor: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Instructions Step ────────────────────────────────────────────────────────

class _InstructionsStep extends StatefulWidget {
  final int amount;
  final TopupMethod method;
  final int total;
  final bool hasProof;
  final bool submitting;
  final ValueChanged<bool> onProofChanged;
  final VoidCallback onConfirm;

  const _InstructionsStep({
    required this.amount,
    required this.method,
    required this.total,
    required this.hasProof,
    required this.submitting,
    required this.onProofChanged,
    required this.onConfirm,
  });

  @override
  State<_InstructionsStep> createState() => _InstructionsStepState();
}

class _InstructionsStepState extends State<_InstructionsStep> {
  bool _copied = false;
  late int _secs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secs = 15 * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secs = (_secs - 1).clamp(0, 15 * 60));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(
        text: widget.method.account.replaceAll(' ', '')));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500),
        () => mounted ? setState(() => _copied = false) : null);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.method;
    final isRfid = m.id == 'rfid';
    final isMandiri = m.id == 'mandiri';
    final canConfirm = !isMandiri || widget.hasProof;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Method banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(m.colorHex).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.rLg),
            border: Border.all(
              color: Color(m.colorHex).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(m.colorHex),
                  borderRadius: BorderRadius.circular(AppSizes.rMd),
                ),
                child: Center(
                  child: m.iconData != null
                      ? Icon(m.iconData, size: 22, color: Colors.white)
                      : Text(
                          m.logo,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      style: AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(m.sub,
                      style: AppTextStyles.body2
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),

        if (!isRfid) ...[
          const SizedBox(height: 16),
          Text(
            m.kind == 'bank'
                ? 'Nomor Virtual Account'
                : 'Tujuan Pembayaran',
            style: AppTextStyles.label
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.rMd),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    m.account,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _copy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.rSm),
                    ),
                    child: Text(
                      _copied ? 'Tersalin' : 'Salin',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Countdown
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.rMd),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Text('Selesaikan dalam',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  AppFormatters.countdown(_secs),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // RFID instructions
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSizes.rMd),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.contactless_rounded,
                      size: 32, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 12),
                const Text('Tap Kartu di Stasiun',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text(
                  'Tempelkan RFID Anda di reader stasiun manapun, lalu masukkan nominal top up di layar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],

        // Summary
        const SizedBox(height: 20),
        Text('Ringkasan',
            style:
                AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              _SumRow(label: 'Nominal', value: AppFormatters.currency(widget.amount)),
              _SumRow(
                  label: 'Biaya admin',
                  value: widget.method.fee > 0
                      ? AppFormatters.currency(widget.method.fee)
                      : 'Gratis',
                  valueColor: widget.method.fee > 0
                      ? null
                      : AppColors.success),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(vertical: 10)),
              _SumRow(
                  label: 'Total bayar',
                  value: AppFormatters.currency(widget.total),
                  bold: true),
            ],
          ),
        ),

        // Proof upload (Mandiri only)
        if (isMandiri) ...[
          const SizedBox(height: 20),
          Text('Upload Bukti Transfer',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => widget.onProofChanged(!widget.hasProof),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: widget.hasProof
                    ? AppColors.primaryLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.rMd),
                border: Border.all(
                  color: widget.hasProof
                      ? AppColors.primary
                      : AppColors.border,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.hasProof
                        ? Icons.check_circle_rounded
                        : Icons.upload_rounded,
                    size: 20,
                    color: widget.hasProof
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.hasProof
                        ? 'bukti-transfer.jpg'
                        : 'Pilih foto bukti',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.hasProof
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (canConfirm && !widget.submitting)
                ? widget.onConfirm
                : null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.5),
            ),
            child: widget.submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    widget.method.isAuto
                        ? 'Saya Sudah Bayar'
                        : 'Kirim Request',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Success Step ─────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  final int amount;
  final TopupMethod method;
  final VoidCallback onBackToWallet;
  final VoidCallback onViewHistory;

  const _SuccessStep({
    required this.amount,
    required this.method,
    required this.onBackToWallet,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isAuto = method.isAuto;
    return Column(
      children: [
        const SizedBox(height: 40),
        const SuccessCheck(),
        const SizedBox(height: 12),
        Text(
          isAuto ? 'Top Up Berhasil!' : 'Request Terkirim!',
          style: AppTextStyles.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 280,
          child: Text(
            isAuto
                ? 'Saldo ${AppFormatters.currency(amount)} telah ditambahkan ke akun Anda.'
                : 'Admin akan memverifikasi pembayaran ${AppFormatters.currency(amount)} Anda dalam 1×24 jam.',
            style: AppTextStyles.body2
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              _SumRow(label: 'Metode', value: method.name),
              _SumRow(
                  label: 'Nominal', value: AppFormatters.currency(amount)),
              _SumRow(
                  label: 'Status',
                  value: isAuto ? 'Berhasil' : 'Menunggu Verifikasi',
                  valueColor:
                      isAuto ? AppColors.success : AppColors.warning),
              _SumRow(label: 'Waktu', value: 'Sekarang'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onBackToWallet,
            child: const Text('Kembali ke Wallet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: onViewHistory,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary),
            child: const Text('Lihat Riwayat'),
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SumRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ??
                  (bold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
