import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../router/route_names.dart';

class MainShell extends StatelessWidget {
  final String location;
  final Widget child;

  const MainShell({super.key, required this.location, required this.child});

  int get _currentIndex {
    if (location.startsWith('/user/home')) return 0;
    if (location.startsWith('/user/map')) return 1;
    if (location.startsWith('/user/scan')) return 2;
    if (location.startsWith('/user/history')) return 3;
    if (location.startsWith('/user/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.userDashboard);
      case 1:
        context.go(RouteNames.stationMap);
      case 2:
        context.go(RouteNames.scanStation);
      case 3:
        context.go(RouteNames.history);
      case 4:
        context.go(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      extendBody: true,
      body: child,
      bottomNavigationBar: _PillNav(
        currentIndex: _currentIndex,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _PillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PillNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomPad > 0 ? bottomPad : 16,
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavTab(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavTab(
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _ScanTab(
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavTab(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavTab(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              active: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? activeIcon : icon,
              size: 22,
              color: active
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _ScanTab({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: active ? 0.25 : 0.0),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
