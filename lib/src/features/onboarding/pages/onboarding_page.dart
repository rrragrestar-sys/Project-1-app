import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../lobby/pages/lobby_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(),
                  // Logo/Title Area
                  Column(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 80,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'LUCKY KING',
                        style: GoogleFonts.righteous(
                          color: Colors.white,
                          fontSize: 48,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        'THE VAULT OF FORTUNE',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Glass Login Card
                  GlassContainer(
                    padding: const EdgeInsets.all(30),
                    borderRadius: 32,
                    child: Column(
                      children: [
                        Text(
                          'WELCOME BACK',
                          style: GoogleFonts.righteous(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sign in to access your gold coins and premium games.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ShinyButton(
                          label: 'LOG IN WITH PHONE',
                          width: double.infinity,
                          onPressed: () => _navigateToLobby(context),
                        ),
                        const SizedBox(height: 12),
                        ShinyButton(
                          label: 'GUEST PLAY',
                          width: double.infinity,
                          color: Colors.white10,
                          onPressed: () => _navigateToLobby(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'By entering, you agree to our Terms of Service\nand confirm you are 18+ years of age.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white30,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLobby(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LobbyPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}
