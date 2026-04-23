import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AviatorPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double multiplier;
  final bool isCrashed;
  final double gridOffset;
  final Color primaryColor;

  AviatorPainter({
    required this.progress,
    required this.multiplier,
    required this.isCrashed,
    required this.primaryColor,
    this.gridOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // 1. Draw High-Tech Grid
    final gridPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    double spacing = 40.0;
    double verticalOffset = (gridOffset * 15) % spacing;
    double horizontalOffset = (gridOffset * 30) % spacing;

    for (double x = -horizontalOffset; x < size.width; x += spacing) {
      _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = verticalOffset; y < size.height; y += spacing) {
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Flight Path
    final path = Path();
    final areaPath = Path();
    
    path.moveTo(0, size.height);
    areaPath.moveTo(0, size.height);

    // Calculate current position
    double curX = progress * size.width;
    double curY = size.height - (math.pow(progress, 1.8) * size.height * 0.85);

    for (double i = 0; i <= progress; i += 0.01) {
      double x = i * size.width;
      double y = size.height - (math.pow(i, 1.8) * size.height * 0.85);
      path.lineTo(x, y);
      areaPath.lineTo(x, y);
    }

    areaPath.lineTo(curX, size.height);
    areaPath.close();

    // Fill area under path with fiery gradient
    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        (isCrashed ? Colors.redAccent : Colors.orangeAccent).withValues(alpha: 0.5),
        Colors.transparent,
      ],
    ).createShader(rect);
    
    canvas.drawPath(areaPath, Paint()..shader = areaGradient);

    // Draw the path line with intense glow
    final lineGradient = LinearGradient(
      colors: isCrashed 
          ? [Colors.red, Colors.redAccent]
          : [Colors.yellowAccent, Colors.deepOrangeAccent],
    ).createShader(rect);

    final linePaint = Paint()
      ..shader = lineGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    
    if (!isCrashed) {
      canvas.drawPath(path, linePaint..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8));
    }
    canvas.drawPath(path, linePaint..maskFilter = null);

    // 3. Draw Fiery Particles (Speed streaks / Thrust)
    if (!isCrashed && progress > 0) {
      final random = math.Random(42);
      for (int i = 0; i < 25; i++) {
        double px = random.nextDouble() * size.width;
        double py = random.nextDouble() * size.height;
        // Particles move faster and get longer as multiplier grows
        double length = 10 + (multiplier * 8);
        
        // Only draw particles near the path and below it
        double expectedY = size.height - (math.pow(px / size.width, 1.8) * size.height * 0.85);
        if (py >= expectedY - 20) {
            final particlePaint = Paint()
                ..color = Colors.orangeAccent.withValues(alpha: 0.4)
                ..strokeWidth = 2.0;
            canvas.drawLine(
              Offset(px, py),
              Offset(px - length, py + (length * 0.3)),
              particlePaint,
            );
        }
      }
    }

    // 4. Draw the Rocket
    if (!isCrashed) {
      _drawRocket(canvas, Offset(curX, curY));
    } else {
      // Draw "FLEW AWAY" text at last position
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'FLEW AWAY!',
          style: TextStyle(
            color: Colors.redAccent, 
            fontSize: 28, 
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(curX - textPainter.width / 2, curY - 50));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const int dashWidth = 5;
    const int dashSpace = 5;
    double startX = p1.dx;
    double startY = p1.dy;
    
    // Quick calculation for dashed lines
    final distance = (p2 - p1).distance;
    final dx = (p2.dx - p1.dx) / distance;
    final dy = (p2.dy - p1.dy) / distance;
    
    double currentDistance = 0;
    while (currentDistance < distance) {
      canvas.drawLine(
        Offset(startX + dx * currentDistance, startY + dy * currentDistance),
        Offset(startX + dx * (currentDistance + dashWidth), startY + dy * (currentDistance + dashWidth)),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  void _drawRocket(Canvas canvas, Offset position) {
    // Thrust Glow
    final glowPaint = Paint()
      ..color = Colors.orangeAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(position.dx - 15, position.dy + 10), 18, glowPaint);
    
    // Core flame
    final flamePaint = Paint()
      ..color = Colors.yellowAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(position.dx - 10, position.dy + 5), 8, flamePaint);

    // Rocket Icon
    final iconData = Icons.rocket_launch;
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontFamily: iconData.fontFamily,
      fontSize: 36.0,
    ))
      ..pushStyle(ui.TextStyle(
        color: Colors.white,
        shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
      ))
      ..addText(String.fromCharCode(iconData.codePoint));
    
    final paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 40.0));
    
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(-math.pi / 8); // Slight upward tilt
    canvas.drawParagraph(paragraph, const Offset(-18, -18));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AviatorPainter oldDelegate) => true;
}
