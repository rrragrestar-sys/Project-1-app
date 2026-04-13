import 'dart:math' as math;
import 'package:flutter/material.dart';

class AviatorPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (relative to current visible window)
  final double multiplier;
  final bool isCrashed;
  final double gridOffset;

  AviatorPainter({
    required this.progress,
    required this.multiplier,
    required this.isCrashed,
    this.gridOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Grid (Moving)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    double spacing = 40.0;
    double verticalOffset = (gridOffset * 10) % spacing;
    double horizontalOffset = (gridOffset * 20) % spacing;

    for (double x = -horizontalOffset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = verticalOffset; y < size.height + verticalOffset; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Main Path Paint (with glow)
    final paint = Paint()
      ..color = isCrashed ? Colors.red.withValues(alpha: 0.5) : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0); // Subtle glow

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (isCrashed ? Colors.red : Colors.red).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final areaPath = Path();

    // The parabolic curve: y = x^2 (normalized)
    // We draw from x=0 to x=progress
    path.moveTo(0, size.height);
    areaPath.moveTo(0, size.height);

    for (double i = 0; i <= progress; i += 0.01) {
      // Quadratic curve for a natural flight feel
      double x = i * size.width;
      double y = size.height - (math.pow(i, 2) * size.height * 0.8);
      path.lineTo(x, y);
      areaPath.lineTo(x, y);
    }

    areaPath.lineTo(progress * size.width, size.height);
    areaPath.close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, paint);

    // Draw indicators/grid lines
    // (Using original gridPaint or shared paint)
    final indicatorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 5; i++) {
      double y = size.height - (i * size.height / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), indicatorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AviatorPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isCrashed != isCrashed;
  }
}
