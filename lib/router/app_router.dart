import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/landing_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/dashboard/presentation/pages/user_dashboard_page.dart';
import '../features/stations/presentation/pages/station_map_page.dart';
import '../features/charging/presentation/pages/scan_station_page.dart';
import '../features/charging/presentation/pages/charging_session_page.dart';
import '../features/charging/presentation/pages/session_receipt_page.dart';
import '../features/wallet/presentation/pages/wallet_page.dart';
import '../features/wallet/presentation/pages/topup_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/admin/presentation/pages/admin_page.dart';
import '../features/shell/main_shell.dart';
import 'route_names.dart';

CustomTransitionPage<T> _slideUp<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
          parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      );
    },
  );
}

CustomTransitionPage<T> _fadeOnly<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      pageBuilder: (_, __) => _fadeOnly(const SplashPage()),
    ),
    GoRoute(
      path: RouteNames.landing,
      pageBuilder: (_, __) => _fadeOnly(const LandingPage()),
    ),
    GoRoute(
      path: RouteNames.login,
      pageBuilder: (_, __) => _slideUp(const LoginPage()),
    ),
    GoRoute(
      path: RouteNames.register,
      pageBuilder: (_, __) => _slideUp(const RegisterPage()),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      pageBuilder: (_, __) => _slideUp(const ForgotPasswordPage()),
    ),

    // Main shell with bottom nav — fade between tabs
    ShellRoute(
      builder: (context, state, child) =>
          MainShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: RouteNames.userDashboard,
          pageBuilder: (_, __) => _fadeOnly(const UserDashboardPage()),
        ),
        GoRoute(
          path: RouteNames.stationMap,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _fadeOnly(
                StationMapPage(selectedStationId: extra?['selectedStation']));
          },
        ),
        GoRoute(
          path: RouteNames.scanStation,
          pageBuilder: (_, __) => _fadeOnly(const ScanStationPage()),
        ),
        GoRoute(
          path: RouteNames.history,
          pageBuilder: (_, __) => _fadeOnly(const HistoryPage()),
        ),
        GoRoute(
          path: RouteNames.profile,
          pageBuilder: (_, __) => _fadeOnly(const ProfilePage()),
        ),
      ],
    ),

    // Full-screen routes — slide up
    GoRoute(
      path: RouteNames.wallet,
      pageBuilder: (_, __) => _slideUp(const WalletPage()),
    ),
    GoRoute(
      path: RouteNames.topupRequest,
      pageBuilder: (_, __) => _slideUp(const TopupPage()),
    ),
    GoRoute(
      path: RouteNames.chargingSession,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slideUp(
            ChargingSessionPage(stationId: extra?['stationId'] ?? 'STN001'));
      },
    ),
    GoRoute(
      path: RouteNames.sessionReceipt,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slideUp(SessionReceiptPage(sessionData: extra));
      },
    ),

    // Admin
    GoRoute(
      path: RouteNames.admin,
      pageBuilder: (_, __) => _slideUp(const AdminPage()),
    ),
  ],
);
