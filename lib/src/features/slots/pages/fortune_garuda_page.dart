import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slot_engine.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../shared/widgets/glass_dialog.dart';

class FortuneGarudaPage extends StatefulWidget {
  const FortuneGarudaPage({super.key});

  @override
  State<FortuneGarudaPage> createState() => _FortuneGarudaPageState();
}

class _FortuneGarudaPageState extends State<FortuneGarudaPage> with TickerProviderStateMixin {
  late SlotController _controller;
  
  final double _betAmount = 100.0;
  bool _isSpinning = false;
  bool _isRespinning = false;
  double _currentWin = 0.0;

  final math.Random _random = math.Random();

  final List<SlotSymbol> _symbols = [
    const SlotSymbol(id: 'GARUDA', imageUrl: '', valueMultiplier: 100, weight: 5, type: SlotSymbolType.wild),
    const SlotSymbol(id: 'GOLD_ORB', imageUrl: '', valueMultiplier: 50, weight: 10),
    const SlotSymbol(id: 'FEATHER', imageUrl: '', valueMultiplier: 20, weight: 20),
    const SlotSymbol(id: 'LOTUS', imageUrl: '', valueMultiplier: 10, weight: 30),
    const SlotSymbol(id: 'ACE', imageUrl: '', valueMultiplier: 5, weight: 40),
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

  Future<void> _spin() async {
    if (_isSpinning || _isRespinning || UserSession().balance < _betAmount) return;

    setState(() {
      _isSpinning = true;
      _currentWin = 0;
      _isRespinning = false;
      _colSpinning.fillRange(0, 3, true);
      UserSession().updateBalance(UserSession().balance - _betAmount);
    });

    final result = _controller.generateResult(_betAmount);

    // Staggered stop for columns
    for (int c = 0; c < 3; c++) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _colSpinning[c] = false;
        for (int r = 0; r < 3; r++) {
          _grid[r][c] = result.grid[r][c];
        }
      });
    }

    if (result.totalWin > 0) {
      await _handleRespin(result.totalWin);
    } else {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  Future<void> _handleRespin(double initialWin) async {
    setState(() {
      _isRespinning = true;
      _currentWin = initialWin;
    });

    await Future.delayed(const Duration(seconds: 1));
    
    // 50% chance to trigger an upgrade
    if (_random.nextBool()) {
      double upgrade = _betAmount * (1 + _random.nextInt(5));
      setState(() {
        _currentWin += upgrade;
      });
      // 30% chance to keep chaining
      if (_random.nextDouble() < 0.3) {
        await _handleRespin(_currentWin);
        return;
      }
    }

    setState(() {
      UserSession().updateBalance(UserSession().balance + _currentWin);
      _isRespinning = false;
      _isSpinning = false;
    });
    
    _showWinDialog(_currentWin);
  }

  void _showWinDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        title: 'GARUDA BLESSING!',
        message: 'The Firebird awarded you a massive payout!\n\n₹${amount.toInt()}',
        buttonLabel: 'CLAIM',
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0000), // Deep crimson black
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
                  BoxShadow(color: Colors.redAccent.withValues(alpha: 0.15), blurRadius: 200, spreadRadius: 80),
                  BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.05), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildGarudaBanner(),
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
            'FORTUNE GARUDA',
            style: GoogleFonts.bungee(
              color: Colors.orangeAccent,
              fontSize: 22,
              letterSpacing: 2,
              shadows: [
                const Shadow(color: Colors.redAccent, blurRadius: 10),
                const Shadow(color: Colors.orange, blurRadius: 20),
              ],
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            borderColor: Colors.redAccent.withValues(alpha: 0.4),
            child: Text(
              '₹${UserSession().balance.toInt()}',
              style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarudaBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isRespinning ? Colors.orangeAccent : Colors.redAccent.withValues(alpha: 0.3), width: 2),
        boxShadow: _isRespinning ? [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.4), blurRadius: 20)] : [],
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: _isRespinning ? Colors.orangeAccent : Colors.white30, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isRespinning)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.5 + (_pulseController.value * 0.5),
                        child: Text('GARUDA RESPINS ACTIVE!', style: GoogleFonts.oswald(color: Colors.orangeAccent, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      );
                    },
                  )
                else
                  Text(
                    'WIN TO TRIGGER RESPINS',
                    style: GoogleFonts.oswald(color: Colors.white54, fontSize: 16, letterSpacing: 1),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Garuda upgrades wins randomly',
                  style: GoogleFonts.oswald(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
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
        color: const Color(0xFF0F0000), // Extremely dark red
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 4),
        boxShadow: [
          BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
          BoxShadow(color: Colors.orange.withValues(alpha: 0.1), blurRadius: 60, spreadRadius: 10),
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
          if (_isRespinning)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: _pulseController.value), width: 6),
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
    return Container(width: 2, color: Colors.redAccent.withValues(alpha: 0.2));
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
            Colors.redAccent.withValues(alpha: 0.3),
            Colors.orangeAccent.withValues(alpha: 0.6),
            Colors.redAccent.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    final symbol = _grid[r][c];
    final isGaruda = symbol.id == 'GARUDA';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isGaruda ? Colors.orange.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGaruda ? Colors.orangeAccent : Colors.redAccent.withValues(alpha: 0.1),
            width: isGaruda ? 2 : 1,
          ),
          boxShadow: isGaruda 
              ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10)] 
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
      case 'GARUDA':
        gradientColors = [Colors.yellowAccent, Colors.orange, Colors.red];
        fontSize = 20;
        addIcon = true;
        iconData = Icons.flight_takeoff; // Represents the mythical bird
        break;
      case 'GOLD_ORB':
        gradientColors = [Colors.yellowAccent, Colors.amber];
        fontSize = 24;
        addIcon = true;
        iconData = Icons.radio_button_checked;
        displayText = 'ORB';
        break;
      case 'FEATHER':
        gradientColors = [Colors.cyanAccent, Colors.lightBlue];
        fontSize = 20;
        break;
      case 'LOTUS':
        gradientColors = [Colors.pinkAccent, Colors.purpleAccent];
        fontSize = 22;
        break;
      case 'ACE':
        gradientColors = [Colors.white, Colors.grey];
        fontSize = 32;
        break;
      default:
        gradientColors = [Colors.white, Colors.white];
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
          Icon(iconData, color: gradientColors.first, size: 36, shadows: [Shadow(color: Colors.orange.withValues(alpha: 0.8), blurRadius: 10)]),
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
        color: const Color(0xFF0F0000),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2))),
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
              Text('TOTAL BET', style: GoogleFonts.oswald(color: Colors.redAccent, fontSize: 14, letterSpacing: 1.5)),
              Text('₹${_betAmount.toInt()}', style: GoogleFonts.bungee(color: Colors.white, fontSize: 24)),
            ],
          ),
          if (_currentWin > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('WIN', style: GoogleFonts.oswald(color: Colors.orangeAccent, fontSize: 14, letterSpacing: 1.5)),
                Text('₹${_currentWin.toInt()}', style: GoogleFonts.bungee(color: Colors.orangeAccent, fontSize: 24)),
              ],
            ),
          ShinyButton(
            label: _isRespinning ? '...' : (_isSpinning ? '...' : 'SPIN'),
            onPressed: (_isSpinning || _isRespinning) ? null : _spin,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}
