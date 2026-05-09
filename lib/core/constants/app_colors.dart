import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand — vibrant orange
  static const Color primary = Color(0xFFFF6B2C);
  static const Color primaryDark = Color(0xFFE55100);
  static const Color primaryLight = Color(0xFFFFF0E6);

  // Black tones
  static const Color secondary = Color(0xFF0F0F0F);
  static const Color accent = Color(0xFFFFB800);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Station status
  static const Color statusAvailable = Color(0xFF22C55E);
  static const Color statusCharging = Color(0xFF3B82F6);
  static const Color statusOffline = Color(0xFF737373);
  static const Color statusMaintenance = Color(0xFFFFB800);

  // Surface
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF171717);
  static const Color border = Color(0xFFE5E5E5);
  static const Color textPrimary = Color(0xFF0F0F0F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFD4D4D4);

  static Color stationStatusColor(String status) {
    switch (status) {
      case 'available':
        return statusAvailable;
      case 'charging':
        return statusCharging;
      case 'maintenance':
        return statusMaintenance;
      default:
        return statusOffline;
    }
  }
}
