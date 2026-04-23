import 'package:flutter/material.dart';
import '../../core/constants.dart';

class GenericGamePage extends StatelessWidget {
  final String title;

  const GenericGamePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeonColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: NeonColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_esports_outlined,
                size: 80,
                color: NeonColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'COMING SOON',
              style: TextStyle(
                color: NeonColors.primary.withValues(alpha: 0.8),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This game is currently being integrated.',
              style: TextStyle(color: NeonColors.textSub, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
