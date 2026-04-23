import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium CustomPainter for the Crash game curve.
class CrashCurvePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool isCrashed;
  final Color curveColor;
  
  CrashCurvePainter({
    required this.progress,
    required this.isCrashed,
    this.curveColor = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    if (progress > 0) {
      _drawCurve(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const double spacing = 50.0;
    
    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Vertical lines (moving left to simulate forward motion)
    final double xOffset = (progress * 500) % spacing;
    for (double x = size.width - xOffset; x > 0; x -= spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawCurve(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCrashed ? Colors.white.withValues(alpha: 0.2) : curveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = curveColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          curveColor.withValues(alpha: 0.2),
          curveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    path.moveTo(0, size.height);
    fillPath.moveTo(0, size.height);

    // Drawing the exponential curve
    // y = height - (e^(x) * scaling)
    for (double i = 0; i <= progress; i += 0.01) {
      final x = i * size.width;
      // We use a power function for the visual curve to keep it within bounds
      final y = size.height - (math.pow(i, 2) * size.height * 0.8);
      
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    if (!isCrashed) {
      canvas.drawPath(path, glowPaint);
    }
    
    canvas.drawPath(fillPath..lineTo(progress * size.width, size.height)..close(), fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw the "Plane" point
    if (!isCrashed) {
      final pointPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(progress * size.width, size.height - (math.pow(progress, 2) * size.height * 0.8)), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CrashCurvePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isCrashed != isCrashed;
  }
}
