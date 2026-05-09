import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AnimatedBalance extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedBalance({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: value),
      builder: (_, v, __) => Text(
        AppFormatters.currency(v),
        style: style,
      ),
    );
  }
}
