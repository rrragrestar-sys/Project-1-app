import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slot_engine.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';

class Crazy777Page extends StatefulWidget {
  const Crazy777Page({super.key});

  @override
  State<Crazy777Page> createState() => _Crazy777PageState();
}

class _Crazy777PageState extends State<Crazy777Page> with TickerProviderStateMixin {
  late SlotController _mainController;
  late SlotController _specialController;

  final double _betAmount = 100.0;
  bool _isSpinning = false;
  double _lastWin = 0;
  bool _isRespin = false;

  final List<SlotSymbol> _mainSymbols = [
    const SlotSymbol(id: '777', imageUrl: '', valueMultiplier: 100, weight: 2),
    const SlotSymbol(id: '77', imageUrl: '', valueMultiplier: 50, weight: 5),
    const SlotSymbol(id: '7', imageUrl: '', valueMultiplier: 20, weight: 10),
    const SlotSymbol(id: 'BAR3', imageUrl: '', valueMultiplier: 10, weight: 15),
    const SlotSymbol(id: 'BAR2', imageUrl: '', valueMultiplier: 5, weight: 20),
    const SlotSymbol(id: 'BAR1', imageUrl: '', valueMultiplier: 2, weight: 30),
  ];

  final List<SlotSymbol> _specialSymbols = [
    const SlotSymbol(id: 'X2', imageUrl: '', valueMultiplier: 2, weight: 20),
    const SlotSymbol(id: 'X5', imageUrl: '', valueMultiplier: 5, weight: 10),
    const SlotSymbol(id: 'X10', imageUrl: '', valueMultiplier: 10, weight: 3),
    const SlotSymbol(id: 'RESPIN', imageUrl: '', valueMultiplier: 1, weight: 5),
    const SlotSymbol(id: 'NONE', imageUrl: '', valueMultiplier: 1, weight: 60),
  ];

  // Current visual grid state
  List<SlotSymbol> _mainGrid = [];
  SlotSymbol? _specialResult;
  final List<bool> _reelSpinning = [false, false, false, false];

  // Animation controller for "Big Win"
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mainController = SlotController(symbols: _mainSymbols, reelCount: 3, rowsPerReel: 1);
    _specialController = SlotController(symbols: _specialSymbols, reelCount: 1, rowsPerReel: 1);

    _mainGrid = List.generate(3, (_) => _mainSymbols[math.Random().nextInt(_mainSymbols.length)]);
    _specialResult = _specialSymbols.last;

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);

    UserSession().addListener(_onSessionUpdate);
  }

  @override
  void dispose() {
    UserSession().removeListener(_onSessionUpdate);
    _pulseController.dispose();
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _spin({bool isBonusRespin = false}) async {
    if (_isSpinning || (!isBonusRespin && UserSession().balance < _betAmount)) return;

    setState(() {
      _isSpinning = true;
      _lastWin = 0;
      _isRespin = isBonusRespin;
      _reelSpinning.fillRange(0, 4, true);

      if (!isBonusRespin) {
        UserSession().updateBalance(UserSession().balance - _betAmount);
      }
    });

    final mainResult = _mainController.generateResult(_betAmount);
    final specialResult = _specialController.generateResult(_betAmount);

    // Staggered stop for reels
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _reelSpinning[i] = false;
        if (i < 3) {
          _mainGrid[i] = mainResult.grid[i][0];
        } else {
          _specialResult = specialResult.grid[0][0];
        }
      });
    }

    _calculateWin(mainResult.totalWin);
  }

  void _calculateWin(double baseWin) async {
    double totalWin = baseWin;

    if (totalWin > 0 && _specialResult != null && _specialResult!.id.startsWith('X')) {
      totalWin *= _specialResult!.valueMultiplier;
    }

    setState(() {
      _lastWin = totalWin;
    });

    if (totalWin > 0) {
      UserSession().updateBalance(UserSession().balance + totalWin);
    }

    if (_specialResult?.id == 'RESPIN') {
      await Future.delayed(const Duration(seconds: 1));
      _spin(isBonusRespin: true);
    } else {
      setState(() {
        _isSpinning = false;
        _isRespin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0014), // Deep Neon Night
      body: Stack(
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.15), blurRadius: 150, spreadRadius: 80),
                  BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildJackpotBanner(),
                const Spacer(),
                _buildSlotCabinet(),
                const Spacer(),
                _buildControls(),
              ],
            ),
          ),
        ],
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
            'CRAZY 777',
            style: GoogleFonts.bungee(
              color: Colors.pinkAccent,
              fontSize: 28,
              letterSpacing: 2,
              shadows: [
                const Shadow(color: Colors.purpleAccent, blurRadius: 15),
                const Shadow(color: Colors.pinkAccent, blurRadius: 30),
              ],
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            borderColor: Colors.purpleAccent.withValues(alpha: 0.4),
            child: Text(
              '₹${UserSession().balance.toInt()}',
              style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJackpotBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.2), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          if (_isRespin)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + (_pulseController.value * 0.5),
                  child: Text('FREE RESPIN ACTIVATED', style: GoogleFonts.oswald(color: Colors.greenAccent, fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.bold)),
                );
              },
            )
          else if (_lastWin > 0)
            Column(
              children: [
                Text('MEGA WIN', style: GoogleFonts.oswald(color: Colors.white54, fontSize: 16, letterSpacing: 2)),
                Text(
                  '₹${_lastWin.toInt()}',
                  style: GoogleFonts.bungee(
                    color: Colors.amber,
                    fontSize: 42,
                    shadows: [const Shadow(color: Colors.orange, blurRadius: 20)],
                  ),
                ),
              ],
            )
          else
            Text(
              'MAX WIN x3333',
              style: GoogleFonts.bungee(color: Colors.purpleAccent, fontSize: 24, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildSlotCabinet() {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF05000A), // Extremely dark purple
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purpleAccent, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: -5),
          BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.2), blurRadius: 60, spreadRadius: 10),
          const BoxShadow(color: Colors.black, blurRadius: 20, blurStyle: BlurStyle.inner), // Inner shadow
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              _buildReelColumn(0, isSpecial: false),
              _buildDivider(),
              _buildReelColumn(1, isSpecial: false),
              _buildDivider(),
              _buildReelColumn(2, isSpecial: false),
              Container(width: 4, color: Colors.pinkAccent), // Thick divider for special
              _buildReelColumn(3, isSpecial: true),
            ],
          ),
          // Winning Line Highlight
          if (_lastWin > 0)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  height: 4,
                  width: double.infinity,
                  color: Colors.amber.withValues(alpha: 0.5 + (_pulseController.value * 0.5)),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 2, color: Colors.purpleAccent.withValues(alpha: 0.3));
  }

  Widget _buildReelColumn(int index, {required bool isSpecial}) {
    bool isSpinning = _reelSpinning[index];
    SlotSymbol? symbol = isSpecial ? _specialResult : _mainGrid[index];

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isSpecial ? Colors.pinkAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: isSpecial ? const BorderRadius.horizontal(right: Radius.circular(20)) : null,
        ),
        child: Center(
          child: isSpinning
              ? _buildMotionBlur(isSpecial)
              : (symbol != null ? _buildNeonSymbol(symbol.id, isSpecial) : const SizedBox()),
        ),
      ),
    );
  }

  Widget _buildMotionBlur(bool isSpecial) {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isSpecial ? Colors.pinkAccent.withValues(alpha: 0.4) : Colors.purpleAccent.withValues(alpha: 0.3),
            isSpecial ? Colors.redAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6),
            isSpecial ? Colors.pinkAccent.withValues(alpha: 0.4) : Colors.purpleAccent.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildNeonSymbol(String id, bool isSpecial) {
    List<Color> gradientColors;
    double fontSize = 48;
    String displayText = id;

    if (isSpecial) {
      if (id.startsWith('X')) {
        gradientColors = [Colors.amber, Colors.orange, Colors.red];
      } else if (id == 'RESPIN') {
        gradientColors = [Colors.greenAccent, Colors.teal, Colors.blueAccent];
        displayText = '↻';
        fontSize = 64;
      } else {
        gradientColors = [Colors.white24, Colors.white10];
        displayText = '-';
      }
    } else {
      switch (id) {
        case '777':
          gradientColors = [Colors.cyanAccent, Colors.blue, Colors.purpleAccent];
          fontSize = 54;
          break;
        case '77':
          gradientColors = [Colors.greenAccent, Colors.teal];
          break;
        case '7':
          gradientColors = [Colors.amber, Colors.orange];
          break;
        case 'BAR3':
          gradientColors = [Colors.redAccent, Colors.deepOrange];
          fontSize = 32;
          break;
        case 'BAR2':
          gradientColors = [Colors.pinkAccent, Colors.purple];
          fontSize = 32;
          break;
        case 'BAR1':
          gradientColors = [Colors.white, Colors.grey];
          fontSize = 32;
          break;
        default:
          gradientColors = [Colors.white, Colors.white];
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ).createShader(bounds),
          child: Text(
            displayText,
            style: GoogleFonts.bungee(
              fontSize: fontSize,
              color: Colors.white,
              shadows: [
                Shadow(color: gradientColors.first.withValues(alpha: 0.6), blurRadius: 20),
                Shadow(color: gradientColors.last.withValues(alpha: 0.4), blurRadius: 40),
              ],
            ),
          ),
        ),
        if (id.startsWith('BAR'))
           Text(id.replaceAll('BAR', ' BAR '), style: GoogleFonts.oswald(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
        if (isSpecial && id == 'RESPIN')
           Text('RESPIN', style: GoogleFonts.bungee(color: Colors.greenAccent, fontSize: 12, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF150A21),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(0, -10), blurRadius: 30),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL BET', style: GoogleFonts.oswald(color: Colors.purpleAccent, fontSize: 14, letterSpacing: 1.5)),
              Text('₹${_betAmount.toInt()}', style: GoogleFonts.bungee(color: Colors.white, fontSize: 32)),
            ],
          ),
          ShinyButton(
            label: _isSpinning ? '...' : 'SPIN',
            onPressed: _isSpinning ? null : () => _spin(),
            color: Colors.pinkAccent,
          ),
        ],
      ),
    );
  }
}
