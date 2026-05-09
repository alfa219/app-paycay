import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppSizes.rLg;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            color: AppColors.surface,
          ),
          child: child,
        ),
      ),
    );
  }
}
