import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final Gradient? gradient;
  final Color? fillColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool withShadow;
  final double shadowOpacity;
  final bool showBorder;
  final double borderOpacity;

  const AppCard({
    super.key,
    required this.child,
    required this.accent,
    this.gradient,
    this.fillColor,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadius.xl,
    this.withShadow = true,
    this.shadowOpacity = 0.1,
    this.showBorder = true,
    this.borderOpacity = 0.16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: fillColor ?? (gradient == null ? palette.surfaceCard : null),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(color: accent.withValues(alpha: borderOpacity))
            : null,
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: shadowOpacity),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
