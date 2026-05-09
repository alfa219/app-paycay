import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Animated success checkmark with an expanding ring halo.
/// Pops in once on mount.
class SuccessCheck extends StatefulWidget {
  final double size;
  final Color color;

  const SuccessCheck({
    super.key,
    this.size = 96,
    this.color = AppColors.success,
  });

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    final ring = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    );

    return SizedBox(
      width: widget.size + 24,
      height: widget.size + 24,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding ring halo
              Opacity(
                opacity: (1 - ring.value).clamp(0.0, 1.0),
                child: Container(
                  width: widget.size + 24 * ring.value,
                  height: widget.size + 24 * ring.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Filled circle
              Transform.scale(
                scale: pop.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: widget.size * 0.58,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
