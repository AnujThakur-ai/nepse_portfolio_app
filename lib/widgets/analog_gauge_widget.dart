import 'dart:math';

import 'package:flutter/material.dart';

class AnalogGaugeWidget extends StatelessWidget {
  final double value; // 0 to 100
  final String title;
  final String subtitle;
  final double size;

  const AnalogGaugeWidget({
    super.key,
    required this.value,
    this.title = 'NEPSE SENTIMENT GAUGE',
    this.subtitle = 'Composite Indicator Confluence',
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String rating;
    Color ratingColor;
    if (value >= 75) {
      rating = 'Extreme Greed (Strong Buy)';
      ratingColor = const Color(0xFF10B981);
    } else if (value >= 55) {
      rating = 'Bullish / Accumulate';
      ratingColor = const Color(0xFF34D399);
    } else if (value <= 25) {
      rating = 'Extreme Fear (Oversold)';
      ratingColor = const Color(0xFFEF4444);
    } else if (value <= 45) {
      rating = 'Bearish / Caution';
      ratingColor = const Color(0xFFF97316);
    } else {
      rating = 'Neutral Market Equilibrium';
      ratingColor = const Color(0xFFFBBF24);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ratingColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ratingColor.withAlpha(102)),
                  ),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: ratingColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: size * 0.65,
              width: size,
              child: CustomPaint(
                painter: _GaugePainter(
                  value: value.clamp(0.0, 100.0),
                  primaryColor: theme.colorScheme.primary,
                  isDark: isDark,
                  ratingColor: ratingColor,
                ),
              ),
            ),
            Text(
              rating,
              style: TextStyle(
                color: ratingColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(153),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final bool isDark;
  final Color ratingColor;

  _GaugePainter({
    required this.value,
    required this.primaryColor,
    required this.isDark,
    required this.ratingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = min(size.width / 2, size.height * 0.95) - 10;

    const startAngle = pi;
    const sweepAngle = pi;

    // Background Arc
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Colored Gradient Arc (Bearish Red -> Amber -> Bullish Green)
    final gradient = SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: const [
        Color(0xFFEF4444), // Fear
        Color(0xFFF97316),
        Color(0xFFFBBF24), // Neutral
        Color(0xFF10B981), // Greed
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    final progressSweep = (value / 100.0) * pi;

    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    if (progressSweep > 0.05) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );
    }

    // Tick Marks (0, 25, 50, 75, 100)
    final tickPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black26
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 10; i++) {
      final angle = pi + (i / 10.0) * pi;
      final inner = Offset(
        center.dx + (radius - 12) * cos(angle),
        center.dy + (radius - 12) * sin(angle),
      );
      final outer = Offset(
        center.dx + (radius + 2) * cos(angle),
        center.dy + (radius + 2) * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Needle
    final needleAngle = pi + (value / 100.0) * pi;
    final needleLength = radius - 15;
    final needleTarget = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = ratingColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTarget, needlePaint);

    // Center Pivot Circle
    final centerCirclePaint = Paint()..color = ratingColor;
    canvas.drawCircle(center, 7, centerCirclePaint);

    final centerInnerPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white;
    canvas.drawCircle(center, 3, centerInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.ratingColor != ratingColor;
  }
}
