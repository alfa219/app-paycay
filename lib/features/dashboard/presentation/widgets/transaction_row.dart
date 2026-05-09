import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/transaction_model.dart';

class TransactionRow extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onTap;

  const TransactionRow({super.key, required this.tx, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCharge = tx.type == 'charging';
    final tint = isCharge ? AppColors.primary : AppColors.success;
    final icon = isCharge ? Icons.bolt_rounded : Icons.arrow_upward_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.label,
                      style: AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    tx.sub.isNotEmpty ? '${tx.date} · ${tx.sub}' : tx.date,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text(
              tx.amount < 0
                  ? AppFormatters.currency(tx.amount)
                  : '+${AppFormatters.currency(tx.amount)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tx.amount < 0 ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
