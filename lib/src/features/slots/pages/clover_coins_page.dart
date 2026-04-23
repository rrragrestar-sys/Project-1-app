import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slot_engine.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../shared/widgets/glass_dialog.dart';

class CloverCoinsPage extends StatefulWidget {
  const CloverCoinsPage({super.key});

  @override
  State<CloverCoinsPage> createState() => _CloverCoinsPageState();
}

class _CloverCoinsPageState extends State<CloverCoinsPage> with TickerProviderStateMixin {
  late SlotController _controller;
  
  final double _betAmount = 100.0;
  bool _isSpinning = false;
  double _lastWin = 0;
  bool _isBonusTriggered = false;

  final math.Random _random = math.Random();

  final List<SlotSymbol> _symbols = [
    const SlotSymbol(id: 'CLOVER', imageUrl: '', valueMultiplier: 50, weight: 10),
    const SlotSymbol(id: 'COIN', imageUrl: '', valueMultiplier: 0, weight: 15, type: SlotSymbolType.bonus),
    const SlotSymbol(id: 'LEAF', imageUrl: '', valueMultiplier: 10, weight: 30),
    const SlotSymbol(id: 'CHERRY', imageUrl: '', valueMultiplier: 5, weight: 45),
  ];

  // Visual grid state
  List<List<SlotSymbol>> _grid = [];
  final List<bool> _colSpinning = [false, false, false];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = SlotController(symbols: _symbols, reelCount: 3, rowsPerReel: 3);
    
    // Initialize a random starting grid
    _grid = List.generate(3, (r) => List.generate(3, (c) => _symbols[_random.nextInt(_symbols.length)]));

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    
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

  Future<void> _spin() async {
    if (_isSpinning || UserSession().balance < _betAmount) return;

    setState(() {
      _isSpinning = true;
      _lastWin = 0;
      _isBonusTriggered = false;
      _colSpinning.fillRange(0, 3, true);
      UserSession().updateBalance(UserSession().balance - _betAmount);
    });

    final result = _controller.generateResult(_betAmount);

    // Staggered stop for columns
    for (int c = 0; c < 3; c++) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _colSpinning[c] = false;
        // Update the visual grid column by column
        for (int r = 0; r < 3; r++) {
          _grid[r][c] = result.grid[r][c];
        }
      });
    }

    _calculateWin(result.totalWin, result.grid);
  }

  void _calculateWin(double baseWin, List<List<SlotSymbol>> finalGrid) async {
    int coinCount = 0;
    for (var reel in finalGrid) {
      for (var s in reel) {
        if (s.id == 'COIN') coinCount++;
      }
    }

    setState(() {
      _lastWin = baseWin;
    });

    if (baseWin > 0) {
      UserSession().updateBalance(UserSession().balance + baseWin);
    }

    if (coinCount >= 3) {
      setState(() {
        _isBonusTriggered = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      _startBonus();
    } else {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  void _startBonus() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlassDialog(
        title: 'CLOVER BONUS!',
        message: 'You hit the jackpot sequence!\nCollecting prizes...',
        buttonLabel: 'COLLECT',
        onConfirm: () {
          Navigator.pop(context);
          _processBonusWin();
        },
      ),
    );
  }

  void _processBonusWin() async {
    // Generate a random large multiplier for the bonus
    double bonusWin = _betAmount * (10 + _random.nextInt(40));
    
    setState(() {
      _lastWin += bonusWin;
      UserSession().updateBalance(UserSession().balance + bonusWin);
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSpinning = false;
      _isBonusTriggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A0A), // Very dark emerald
      body: Stack(
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 200, spreadRadius: 80),
                  BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.05), blurRadius: 100, spreadRadius: 50),
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
            'CLOVER COINS',
            style: GoogleFonts.bungee(
              color: Colors.greenAccent,
              fontSize: 26,
              letterSpacing: 2,
              shadows: [
                const Shadow(color: Colors.teal, blurRadius: 10),
                const Shadow(color: Colors.green, blurRadius: 20),
              ],
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            borderColor: Colors.amber.withValues(alpha: 0.4),
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
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          if (_isBonusTriggered)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + (_pulseController.value * 0.5),
                  child: Text('CLOVER BONUS!', style: GoogleFonts.oswald(color: Colors.amber, fontSize: 24, letterSpacing: 3, fontWeight: FontWeight.bold)),
                );
              },
            )
          else if (_lastWin > 0)
            Column(
              children: [
                Text('WIN', style: GoogleFonts.oswald(color: Colors.white54, fontSize: 16, letterSpacing: 2)),
                Text(
                  '₹${_lastWin.toInt()}',
                  style: GoogleFonts.bungee(
                    color: Colors.greenAccent,
                    fontSize: 38,
                    shadows: [const Shadow(color: Colors.green, blurRadius: 15)],
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  'COLLECT 3 COINS',
                  style: GoogleFonts.bungee(color: Colors.amber, fontSize: 18, letterSpacing: 1),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.stars, color: Colors.amber, size: 28),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSlotCabinet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF030D05), // Extremely dark green
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 4),
        boxShadow: [
          BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
          BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 60, spreadRadius: 10),
          const BoxShadow(color: Colors.black, blurRadius: 20, blurStyle: BlurStyle.inner),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _buildReelColumn(0),
              _buildDivider(),
              _buildReelColumn(1),
              _buildDivider(),
              _buildReelColumn(2),
            ],
          ),
          if (_isBonusTriggered)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.withValues(alpha: _pulseController.value), width: 6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 2, color: Colors.greenAccent.withValues(alpha: 0.2));
  }

  Widget _buildReelColumn(int colIndex) {
    bool isSpinning = _colSpinning[colIndex];

    return Expanded(
      child: isSpinning
          ? _buildMotionBlur()
          : Column(
              children: [
                _buildCell(0, colIndex),
                _buildCell(1, colIndex),
                _buildCell(2, colIndex),
              ],
            ),
    );
  }

  Widget _buildMotionBlur() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.greenAccent.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.6),
            Colors.greenAccent.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    final symbol = _grid[r][c];
    final isCoin = symbol.id == 'COIN';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isCoin ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCoin ? Colors.amber : Colors.greenAccent.withValues(alpha: 0.1),
            width: isCoin ? 2 : 1,
          ),
          boxShadow: isCoin 
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10)] 
              : null,
        ),
        child: Center(
          child: _buildPremiumSymbol(symbol.id),
        ),
      ),
    );
  }

  Widget _buildPremiumSymbol(String id) {
    List<Color> gradientColors;
    double fontSize = 32;
    String displayText = id;
    bool addIcon = false;
    IconData? iconData;

    switch (id) {
      case 'CLOVER':
        gradientColors = [Colors.greenAccent, Colors.teal];
        fontSize = 24;
        break;
      case 'COIN':
        gradientColors = [Colors.yellowAccent, Colors.amber, Colors.orange];
        fontSize = 28;
        addIcon = true;
        iconData = Icons.monetization_on;
        break;
      case 'LEAF':
        gradientColors = [Colors.lightGreen, Colors.green];
        fontSize = 24;
        break;
      case 'CHERRY':
        gradientColors = [Colors.redAccent, Colors.pink];
        fontSize = 22;
        break;
      default:
        gradientColors = [Colors.white, Colors.grey];
    }

    Widget textWidget = ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(bounds),
      child: Text(
        displayText,
        style: GoogleFonts.bungee(
          fontSize: fontSize,
          color: Colors.white,
          shadows: [
            Shadow(color: gradientColors.last.withValues(alpha: 0.5), blurRadius: 10),
          ],
        ),
      ),
    );

    if (addIcon) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: Colors.amber, size: 48, shadows: [Shadow(color: Colors.orange.withValues(alpha: 0.8), blurRadius: 15)]),
          const SizedBox(height: 4),
          textWidget,
        ],
      );
    }

    return textWidget;
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF09140B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.2))),
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
              Text('TOTAL BET', style: GoogleFonts.oswald(color: Colors.greenAccent, fontSize: 14, letterSpacing: 1.5)),
              Text('₹${_betAmount.toInt()}', style: GoogleFonts.bungee(color: Colors.white, fontSize: 32)),
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
