import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/glass_container.dart';

class LiveCasinoCard extends StatelessWidget {
  final String title;
  final int tables;
  final String imageUrl;

  const LiveCasinoCard({
    super.key,
    required this.title,
    required this.tables,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeonColors.primary.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: NeonColors.primary.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -5),
        ],
        image: DecorationImage(
          image: AssetImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              NeonColors.background,
              NeonColors.background.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$tables TABLES ACTIVE',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                shadows: [const Shadow(color: Colors.black, blurRadius: 5)],
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              borderRadius: 12,
              borderColor: NeonColors.primary.withValues(alpha: 0.6),
              child: const Text(
                'JOIN TABLE',
                style: TextStyle(color: NeonColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
