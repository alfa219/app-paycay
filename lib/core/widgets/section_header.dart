import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.h3),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    action!,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
