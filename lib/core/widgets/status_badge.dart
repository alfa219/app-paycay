import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: cfg.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cfg.dot,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config(String status) {
    switch (status) {
      case 'available':
        return _BadgeConfig(
          label: 'Tersedia',
          dot: AppColors.statusAvailable,
          bg: AppColors.statusAvailable.withValues(alpha: 0.12),
        );
      case 'charging':
        return _BadgeConfig(
          label: 'Mengisi',
          dot: AppColors.statusCharging,
          bg: AppColors.statusCharging.withValues(alpha: 0.12),
        );
      case 'maintenance':
        return _BadgeConfig(
          label: 'Maintenance',
          dot: AppColors.statusMaintenance,
          bg: AppColors.statusMaintenance.withValues(alpha: 0.12),
        );
      default:
        return _BadgeConfig(
          label: 'Offline',
          dot: AppColors.statusOffline,
          bg: AppColors.statusOffline.withValues(alpha: 0.12),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color dot;
  final Color bg;
  const _BadgeConfig({required this.label, required this.dot, required this.bg});
}
