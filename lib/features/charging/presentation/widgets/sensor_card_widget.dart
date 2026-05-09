import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class SensorCardWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final SensorTone tone;

  const SensorCardWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.tone,
  });

  Color get _tint {
    switch (tone) {
      case SensorTone.warn:
        return AppColors.warning;
      case SensorTone.info:
        return AppColors.info;
      case SensorTone.primary:
        return AppColors.primary;
      case SensorTone.success:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.rLg),
        border: Border.all(color: _tint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _tint),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(unit,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _tint)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

enum SensorTone { warn, info, primary, success }
