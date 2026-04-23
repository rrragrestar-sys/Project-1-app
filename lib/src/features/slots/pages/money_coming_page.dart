import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';

class MoneyComingPage extends StatefulWidget {
  const MoneyComingPage({super.key});

  @override
  State<MoneyComingPage> createState() => _MoneyComingPageState();
}

class _MoneyComingPageState extends State<MoneyComingPage> with TickerProviderStateMixin {
  final List<String> _mainReels = ['0', '0', '0'];
  String _specialAward = '-';
  bool _isSpinning = false;
  bool _showLuckyWheel = false;
  final double _betAmount = 100.0;
  double _lastWin = 0;

  // Spin animation state
  final List<bool> _reelSpinning = [false, false, false, false];

  final math.Random _random = math.Random();

  late AnimationController _wheelController;

  @override
  void initState() {
    super.initState();
    UserSession().addListener(_onSessionUpdate);
    _wheelController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    UserSession().removeListener(_onSessionUpdate);
    _wheelController.dispose();
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _spin() async {
    if (_isSpinning || UserSession().balance < _betAmount) return;

    setState(() {
      _isSpinning = true;
      _lastWin = 0;
      _reelSpinning.fillRange(0, 4, true);
      UserSession().updateBalance(UserSession().balance - _betAmount);
    });

    // Staggered stop for reels
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _reelSpinning[i] = false;
        if (i == 0) _mainReels[0] = _random.nextInt(2).toString(); // Hundreds: 0, 1
        if (i == 1) _mainReels[1] = _random.nextInt(10).toString(); // Tens: 0-9
        if (i == 2) _mainReels[2] = ['0', '00', '5'][_random.nextInt(3)]; // Ones
        if (i == 3) {
          final specialIndex = _random.nextInt(100);
          if (specialIndex < 30) {
            _specialAward = 'X2';
          } else if (specialIndex < 50) {
            _specialAward = 'X5';
          } else if (specialIndex < 60) {
            _specialAward = 'X10';
          } else if (specialIndex < 70) {
            _specialAward = 'WHEEL';
          } else {
            _specialAward = '-';
          }
        }
      });
    }

    _calculateWin();
  }

  void _calculateWin() async {
    // Treat '00' as '0' for the integer calculation, but its display value remains '00'
    int hundreds = int.parse(_mainReels[0]);
    int tens = int.parse(_mainReels[1]);
    int ones = _mainReels[2] == '00' ? 0 : int.parse(_mainReels[2]);
    
    // Value formed by concatenating digits (e.g., 1, 0, 00 => 1000)
    int baseValue = 0;
    if (_mainReels[2] == '00') {
      baseValue = int.parse('$hundreds${tens}00');
    } else {
      baseValue = int.parse('$hundreds$tens$ones');
    }

    double win = baseValue.toDouble() * (_betAmount / 10);
    
    if (_specialAward == 'X2') win *= 2;
    if (_specialAward == 'X5') win *= 5;
    if (_specialAward == 'X10') win *= 10;

    setState(() {
      _lastWin = win;
    });

    if (win > 0) {
      UserSession().updateBalance(UserSession().balance + win);
    }

    if (_specialAward == 'WHEEL') {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _showLuckyWheel = true;
      });
      _spinLuckyWheel();
    } else {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  Future<void> _spinLuckyWheel() async {
    _wheelController.reset();
    
    // Spin with a random curve to simulate friction
    await _wheelController.animateTo(1.0, curve: Curves.decelerate);
    
    // Award random bonus
    double bonus = _betAmount * [10, 20, 50, 100][_random.nextInt(4)];
    
    setState(() {
      _lastWin += bonus;
      UserSession().updateBalance(UserSession().balance + bonus);
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _showLuckyWheel = false;
      _isSpinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515), // Deep metallic charcoal
      body: Stack(
        children: [
          // Ambient Background Light
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 150, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildWinBanner(),
                const Spacer(),
                _buildMainBoard(),
                const Spacer(),
                _buildControls(),
              ],
            ),
          ),
          if (_showLuckyWheel) _buildLuckyWheelOverlay(),
        ],
      ),
    );
  }

  Widget _buildLuckyWheelOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('LUCKY WHEEL', style: GoogleFonts.oswald(color: Colors.amber, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _wheelController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _wheelController.value * 2 * math.pi * 5, // 5 full rotations
                    child: child,
                  );
                },
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 8),
                    gradient: const SweepGradient(
                      colors: [Colors.amber, Colors.orange, Colors.red, Colors.purple, Colors.blue, Colors.green, Colors.amber],
                    ),
                    boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 30)],
                  ),
                  child: const Center(
                    child: Icon(Icons.star, color: Colors.white, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_wheelController.isCompleted)
                 Text('WIN AWARDED!', style: GoogleFonts.oswald(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'MONEY COMING',
            style: GoogleFonts.russoOne(
              color: Colors.amber,
              fontSize: 28,
              letterSpacing: 2,
              shadows: [const Shadow(color: Colors.orange, blurRadius: 10)],
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            borderColor: Colors.amber.withValues(alpha: 0.5),
            child: Text(
              '₹${UserSession().balance.toInt()}',
              style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
        boxShadow: _lastWin > 0 ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 20)] : [],
      ),
      child: Column(
        children: [
          Text('WIN', style: GoogleFonts.oswald(color: Colors.white54, fontSize: 16, letterSpacing: 2)),
          Text(
            '₹${_lastWin.toInt()}', 
            style: GoogleFonts.russoOne(
              color: _lastWin > 0 ? Colors.amber : Colors.white24, 
              fontSize: 42,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildMainBoard() {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(0, 10), blurRadius: 20),
          const BoxShadow(color: Colors.amber, blurRadius: 5, spreadRadius: -2), // Inner glow
        ],
      ),
      child: Row(
        children: [
          _buildReelColumn(0, isSpecial: false),
          Container(width: 2, color: Colors.amber.withValues(alpha: 0.3)),
          _buildReelColumn(1, isSpecial: false),
          Container(width: 2, color: Colors.amber.withValues(alpha: 0.3)),
          _buildReelColumn(2, isSpecial: false),
          Container(width: 4, color: Colors.amber), // Thicker separator for special reel
          _buildReelColumn(3, isSpecial: true),
        ],
      ),
    );
  }

  Widget _buildReelColumn(int index, {required bool isSpecial}) {
    bool isSpinning = _reelSpinning[index];
    String displayValue = isSpecial ? _specialAward : _mainReels[index];

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isSpecial ? Colors.amber.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: isSpecial ? const BorderRadius.horizontal(right: Radius.circular(20)) : null,
        ),
        child: Center(
          child: isSpinning 
              ? _buildMotionBlur(isSpecial) 
              : _buildPremiumText(displayValue, isSpecial),
        ),
      ),
    );
  }

  Widget _buildMotionBlur(bool isSpecial) {
    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isSpecial ? Colors.orange.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2),
            isSpecial ? Colors.amber.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            isSpecial ? Colors.orange.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumText(String text, bool isSpecial) {
    List<Color> gradientColors = isSpecial 
        ? [Colors.orange, Colors.amber, Colors.orangeAccent]
        : [Colors.white, const Color(0xFFDDDDDD), Colors.white70];

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.russoOne(
          fontSize: isSpecial ? (text == 'WHEEL' ? 24 : 48) : 72,
          color: Colors.white,
          shadows: [
            Shadow(
              color: (isSpecial ? Colors.orange : Colors.white).withValues(alpha: 0.5),
              blurRadius: 20,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(0, -10), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL BET', style: GoogleFonts.oswald(color: Colors.white54, fontSize: 14, letterSpacing: 1.5)),
              Text('₹${_betAmount.toInt()}', style: GoogleFonts.russoOne(color: Colors.white, fontSize: 32)),
            ],
          ),
          ShinyButton(
            label: _isSpinning ? '...' : 'SPIN',
            onPressed: _isSpinning ? null : _spin,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}
