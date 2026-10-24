import 'dart:ui';

import 'package:flutter/material.dart';

/// A light frosted surface for dashboard and portfolio information panels.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = theme.colorScheme.surface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withAlpha(isDark ? 150 : 205),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 28 : 10),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
