import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';
import 'liquid_background.dart';
import 'shiny_button.dart';
import '../../core/constants.dart';

class MatchmakingOverlay extends StatefulWidget {
  final String gameTitle;
  final int maxPlayers;
  final VoidCallback onStartWithBots;
  final Function(List<String> players) onMatchFound;

  const MatchmakingOverlay({
    super.key,
    required this.gameTitle,
    this.maxPlayers = 4,
    required this.onStartWithBots,
    required this.onMatchFound,
  });

  @override
  State<MatchmakingOverlay> createState() => _MatchmakingOverlayState();
}

class _MatchmakingOverlayState extends State<MatchmakingOverlay> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<String> _players = ['You'];
  final List<String> _simNames = ['Roxie', 'Ace', 'Joker', 'King', 'Queen', 'Shadow', 'Blaze'];
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startTimer();
    _simulatePlayers();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        widget.onStartWithBots();
      }
    });
  }

  void _simulatePlayers() {
    final rand = Random();
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: rand.nextInt(4) + 2));
      if (!mounted || _players.length >= widget.maxPlayers) return false;
      
      setState(() {
        _players.add(_simNames[rand.nextInt(_simNames.length)] + rand.nextInt(99).toString());
      });

      if (_players.length == widget.maxPlayers) {
        _timer?.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) widget.onMatchFound(_players);
        });
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        'MATCHMAKING',
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  _buildPulseTimer(),
                  const SizedBox(height: 40),
                  Text(
                    widget.gameTitle.toUpperCase(),
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FINDING WORTHY OPPONENTS...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  _buildPlayersList(),
                  const Spacer(),
                  ShinyButton(
                    label: 'START WITH BOTS NOW',
                    onPressed: widget.onStartWithBots,
                    color: NeonColors.primary,
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

  Widget _buildPulseTimer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: NeonColors.primary.withValues(alpha: 0.5 * _pulseController.value),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.primary.withValues(alpha: 0.2 * _pulseController.value),
                blurRadius: 20,
                spreadRadius: 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_secondsRemaining',
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'SEC',
                style: TextStyle(color: NeonColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayersList() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxPlayers, (index) {
        bool filled = index < _players.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              GlassContainer(
                width: 60,
                height: 60,
                borderRadius: 30,
                blurX: 10,
                blurY: 10,
                opacity: 0.1,
                borderColor: filled ? NeonColors.primary : Colors.white12,
                child: Center(
                  child: filled 
                    ? const Icon(Icons.person, color: Colors.white)
                    : const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filled ? _players[index] : '...',
                style: TextStyle(
                  color: filled ? Colors.white : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
