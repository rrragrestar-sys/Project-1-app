import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium, reusable widget that implements an iOS-style 'Liquid Glass' effect.
/// Uses [BackdropFilter] and [ImageFilter.blur] to create a frosted glass look.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurX;
  final double blurY;
  final double opacity;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final List<BoxShadow>? shadows;
  final Gradient? borderGradient;
  final Gradient? backgroundGradient;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurX = 15.0,
    this.blurY = 15.0,
    this.opacity = 0.1,
    this.borderRadius = 20.0,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.shadows,
    this.borderGradient,
    this.backgroundGradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Soft drop shadow to separate the glass from the background
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              // Slight white gradient for the "Liquid Glass" shine
              gradient: backgroundGradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: opacity + 0.1),
                  Colors.white.withValues(alpha: opacity),
                ],
              ),
              // Subtle semi-transparent border to create the 'glass edge' highlight
              border: Border.all(
                width: borderWidth,
                color: borderColor ?? Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
