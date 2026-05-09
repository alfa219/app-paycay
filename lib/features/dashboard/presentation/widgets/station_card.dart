import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/station_model.dart';

class StationCard extends StatelessWidget {
  final StationModel station;
  final VoidCallback onTap;

  const StationCard({super.key, required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(status: station.status),
            const SizedBox(height: 8),
            Text(station.id, style: AppTextStyles.h3),
            Text(station.slot,
                style: AppTextStyles.caption.copyWith(fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(station.distance,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${AppFormatters.currency(station.tariff)}/kWh',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
