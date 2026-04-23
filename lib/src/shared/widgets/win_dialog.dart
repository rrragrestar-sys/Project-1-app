import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import 'shiny_button.dart';

class WinDialog extends StatefulWidget {
  final double amount;
  final String title;
  final String subTitle;
  final VoidCallback onConfirm;

  const WinDialog({
    super.key,
    required this.amount,
    this.title = 'BIG WIN!',
    this.subTitle = 'Congratulations!',
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, {
    required double amount,
    String title = 'BIG WIN!',
    String subTitle = 'Congratulations!',
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => WinDialog(
        amount: amount,
        title: title,
        subTitle: subTitle,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<WinDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _countAnimation = Tween<double>(begin: 0, end: widget.amount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: GlassContainer(
          width: 320,
          padding: const EdgeInsets.all(32),
          borderRadius: 24,
          borderColor: Colors.amber.withValues(alpha: 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: GoogleFonts.oswald(
                  color: Colors.amber,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subTitle,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _countAnimation,
                builder: (context, child) {
                  return Text(
                    '₹${_countAnimation.value.toStringAsFixed(0)}',
                    style: GoogleFonts.dotGothic16(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 20),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ShinyButton(
                label: 'COLLECT',
                onPressed: () {
                  Navigator.pop(context);
                  widget.onConfirm();
                },
                color: Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
