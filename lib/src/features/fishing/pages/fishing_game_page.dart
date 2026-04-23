import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/fishing_controller.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';

class FishingGamePage extends StatefulWidget {
  const FishingGamePage({super.key});

  @override
  State<FishingGamePage> createState() => _FishingGamePageState();
}

class _FishingGamePageState extends State<FishingGamePage> {
  final FishingController _ctrl = FishingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap(TapDownDetails details, BoxConstraints constraints) {
    final norm = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _ctrl.tapAt(norm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Deep-sea gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF002244), Color(0xFF001133), Color(0xFF000811)],
              ),
            ),
          ),
          // Bubble animation background
          ...List.generate(8, (i) => _Bubble(index: i)),
          // Game Layer
          _ctrl.state == FishingState.betting
              ? _buildBettingScreen()
              : _ctrl.state == FishingState.finished
                  ? _buildResultScreen()
                  : _buildGameScreen(),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (d) => _onTap(d, constraints),
          child: Stack(
            children: [
              // Ocean floor
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A4A1A), Color(0xFF0D2B0D)],
                    ),
                  ),
                ),
              ),
              // Fish layer
              ..._ctrl.fish.map((fish) => _FishWidget(
                    fish: fish,
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                  )),
              // HUD
              SafeArea(child: _buildHUD()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHUD() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              // Score
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 20,
                child: Row(children: [
                  const Text('🎣 ', style: TextStyle(fontSize: 16)),
                  Text(
                    '${_ctrl.totalScore} pts',
                    style: GoogleFonts.righteous(color: Colors.amber, fontSize: 18),
                  ),
                ]),
              ),
              const Spacer(),
              // Timer
              _buildTimerRing(),
              const Spacer(),
              // Balance
              ListenableBuilder(
                listenable: UserSession(),
                builder: (context, _) => GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 20,
                  child: Text(
                    '₹${UserSession().fiatBalance.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(color: NeonColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Fish caught counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tap the fish to catch them!',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerRing() {
    final double progress = _ctrl.secondsLeft / FishingController.gameDurationSecs;
    final Color color = _ctrl.secondsLeft <= 10 ? Colors.redAccent : Colors.cyanAccent;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            color: color,
            backgroundColor: Colors.white10,
          ),
        ),
        Text(
          '${_ctrl.secondsLeft}',
          style: GoogleFonts.righteous(color: color, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildBettingScreen() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text('OCEAN FISHING',
                    style: GoogleFonts.righteous(
                        color: Colors.cyanAccent, fontSize: 22, letterSpacing: 2)),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const Spacer(),
          const Text('🐠', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 12),
          Text('Tap fish to catch them!',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 32),
          // Bet selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text('SELECT BET AMOUNT',
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [50, 100, 200, 500].map((amt) {
                    final bool sel = _ctrl.betAmount == amt.toDouble();
                    return GestureDetector(
                      onTap: () => _ctrl.setBet(amt.toDouble()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sel ? Colors.cyanAccent : Colors.white12),
                          boxShadow: sel
                              ? [const BoxShadow(color: Colors.cyanAccent, blurRadius: 10, spreadRadius: 0)]
                              : [],
                        ),
                        child: Text(
                          '₹$amt',
                          style: GoogleFonts.righteous(
                            color: sel ? Colors.cyanAccent : Colors.white54,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                // Score chart legend
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  child: Column(
                    children: [
                      Text('PAYOUT TABLE', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      _payoutRow('Score > 500', '5× bet'),
                      _payoutRow('Score > 200', '3× bet'),
                      _payoutRow('Score > 100', '2× bet'),
                      _payoutRow('Score > 50', '1.5× bet'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: () {
                if (!_ctrl.startGame()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insufficient balance'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.cyanAccent, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Center(
                  child: Text(
                    'START FISHING  🎣',
                    style: GoogleFonts.righteous(
                        color: Colors.black, fontSize: 18, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _payoutRow(String condition, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(condition, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(reward,
              style: GoogleFonts.inter(
                  color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final double multiplier = _ctrl.totalScore > 500
        ? 5.0
        : _ctrl.totalScore > 200
            ? 3.0
            : _ctrl.totalScore > 100
                ? 2.0
                : _ctrl.totalScore > 50
                    ? 1.5
                    : 0.0;
    final bool isWin = multiplier > 0;
    final double payout = isWin ? _ctrl.betAmount * multiplier : 0;

    return SafeArea(
      child: Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(32),
          borderRadius: 28,
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isWin ? '🎉' : '😢', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                isWin ? 'GREAT CATCH!' : 'BETTER LUCK\nNEXT TIME',
                style: GoogleFonts.righteous(
                  color: isWin ? Colors.cyanAccent : Colors.redAccent,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('Score: ${_ctrl.totalScore} pts',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 16)),
              Text('Fish caught: ${_ctrl.fishCaught}',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
              if (isWin) ...[
                const SizedBox(height: 8),
                Text('Payout: ₹${payout.toStringAsFixed(0)}',
                    style: GoogleFonts.righteous(
                        color: Colors.amber, fontSize: 20)),
              ],
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _ctrl.reset(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('PLAY AGAIN', style: GoogleFonts.righteous(color: Colors.black, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fish Widget ───────────────────────────────────────────────────────────────

class _FishWidget extends StatelessWidget {
  final Fish fish;
  final double maxWidth;
  final double maxHeight;

  const _FishWidget({
    required this.fish,
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double x = fish.x * maxWidth;
    final double y = fish.y * maxHeight;
    final bool caught = fish.caught;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      left: x - 24,
      top: y - 24,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: caught ? 0.0 : 1.0,
        child: Transform.flip(
          flipX: !fish.facingRight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!caught)
                Text(fish.emoji, style: const TextStyle(fontSize: 40)),
              if (caught)
                const Text('✨', style: TextStyle(fontSize: 36)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bubble Widget ─────────────────────────────────────────────────────────────

class _Bubble extends StatefulWidget {
  final int index;

  const _Bubble({required this.index});

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late double _x;
  late double _size;

  @override
  void initState() {
    super.initState();
    final rand = math.Random(widget.index * 7 + 13);
    _x = rand.nextDouble();
    _size = 4 + rand.nextDouble() * 8;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5 + rand.nextInt(8)),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final double y = 1.0 - _ctrl.value;
        return Positioned(
          left: _x * MediaQuery.of(context).size.width,
          top: y * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: (0.5 - _ctrl.value.abs() * 0.5).clamp(0, 0.35),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
