import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_page.dart';
import '../../../shared/widgets/liquid_background.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shineAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  String _loadingText = "ROLLING DICE...";
  final List<String> _loadingSteps = [
    "SHUFFLING CARDS...",
    "CALCULATING ODDS...",
    "JACKPOT LOADING...",
    "SECURING VAULT...",
    "HOUSE IS READY...",
  ];
  int _stepIndex = 0;
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 5.0, end: 25.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Slot-machine style loading text
    _textTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted && _stepIndex < _loadingSteps.length - 1) {
        setState(() {
          _stepIndex++;
          _loadingText = _loadingSteps[_stepIndex];
        });
      }
    });

    // Navigation delay
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const LiquidBackground(),
          // Casino Velvet Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF2A0000).withValues(alpha: 0.5), // Rich Deep Maroon
                  Colors.black,
                ],
              ),
            ),
          ),
          
          // Background Sparkles (Simulated Las Vegas Lights)
          ...List.generate(15, (index) {
            final x = (index * 0.17) % 1.0;
            final y = (index * 0.23) % 1.0;
            return Positioned(
              left: MediaQuery.of(context).size.width * x,
              top: MediaQuery.of(context).size.height * y,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: (index % 3 == 0) ? (0.2 + 0.3 * _pulseAnimation.value) : 0.1,
                    child: Icon(
                      Icons.star,
                      size: (index % 4 + 1) * 4.0,
                      color: Colors.amberAccent.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            );
          }),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Golden Crown centerpiece
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amberAccent.withValues(alpha: 0.1),
                              blurRadius: _glowAnimation.value * 2,
                              spreadRadius: _glowAnimation.value / 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 100,
                          color: Colors.amberAccent,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFFD100),
                              blurRadius: _glowAnimation.value,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Gold Foil Text with Shimmer Shader
                AnimatedBuilder(
                  animation: _shineAnimation,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [
                            _shineAnimation.value - 0.2,
                            _shineAnimation.value,
                            _shineAnimation.value + 0.2,
                          ],
                          colors: [
                            const Color(0xFFB8860B), // Dark Gold
                            const Color(0xFFFFD700), // Vibrant Gold
                            const Color(0xFFB8860B), // Dark Gold
                          ],
                        ).createShader(bounds);
                      },
                      child: Column(
                        children: [
                          Text(
                            'LUCKY KING',
                            style: GoogleFonts.righteous(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                          ),
                          Text(
                            'PREMIUM CASINO',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 100),
                
                // Modern Casino Loader
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.white10,
                          color: Color(0xFFFFD700),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        child: Text(
                          _loadingText,
                          key: ValueKey(_loadingText),
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Authenticity Badge
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, color: Colors.white24, size: 14),
                const SizedBox(width: 8),
                Text(
                  'CERTIFIED SECURE FAIR PLAY',
                  style: GoogleFonts.inter(
                    color: Colors.white24,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
