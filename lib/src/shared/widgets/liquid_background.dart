import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// A performant, animated 'Liquid' background widget.
/// Draws large, blurred, drifting blobs that create a dynamic mesh gradient effect.
class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Slow, organic motion
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LiquidPainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double animationValue;
  
  _LiquidPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 1. Background Base (Deep Maroon/Black)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0F0000), // Very dark maroon
    );

    // Helper to draw a drifting blob
    void drawBlob(Offset baseOffset, double radius, List<Color> colors, double offsetMultiplier) {
      // Calculate drifting position using sine/cosine for organic motion
      final double dx = math.sin(animationValue * 2 * math.pi + offsetMultiplier) * 50;
      final double dy = math.cos(animationValue * 2 * math.pi * 0.5 + offsetMultiplier) * 80;
      
      final Offset position = baseOffset + Offset(dx, dy);

      final Rect rect = Rect.fromCircle(center: position, radius: radius);
      paint.shader = RadialGradient(
        colors: colors,
      ).createShader(rect);

      canvas.drawCircle(position, radius, paint);
    }

    // Deep Red Blob
    drawBlob(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.8,
      [const Color(0xFF4A0000).withValues(alpha: 0.6), Colors.transparent],
      0.0,
    );

    // Vibrant Red/Orange Blob
    drawBlob(
      Offset(size.width * 0.8, size.height * 0.2),
      size.width * 0.7,
      [const Color(0xFF8B0000).withValues(alpha: 0.5), Colors.transparent],
      2.0,
    );

    // Casino Gold Blob
    drawBlob(
      Offset(size.width * 0.5, size.height * 0.8),
      size.width * 0.9,
      [NeonColors.primary.withValues(alpha: 0.3), Colors.transparent],
      4.0,
    );

    // Subtle Bright Gold Accent
    drawBlob(
      Offset(size.width * 0.1, size.height * 0.9),
      size.width * 0.5,
      [NeonColors.secondary.withValues(alpha: 0.2), Colors.transparent],
      1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
