import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import 'shiny_button.dart';

/// A premium Glassmorphic Dialog for high-value events like Jackpots.
class GlassDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onConfirm;
  final Widget? icon;

  const GlassDialog({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onConfirm,
    this.icon,
  });

  /// Static helper to show the dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onConfirm,
    Widget? icon,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4), // Dim background
      builder: (context) => GlassDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(height: 16),
              ],
              // Glowing Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.righteous(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.amber.withValues(alpha: 0.8),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ShinyButton(
                label: buttonLabel,
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
