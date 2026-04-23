import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slot_engine.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../shared/widgets/glass_dialog.dart';

class FortuneGems2Page extends StatefulWidget {
  const FortuneGems2Page({super.key});

  @override
  State<FortuneGems2Page> createState() => _FortuneGems2PageState();
}

class _FortuneGems2PageState extends State<FortuneGems2Page> {
  late SlotController _controller;
  
  final double _betAmount = 100.0;
  bool _isSpinning = false;
  double _currentWin = 0.0;
  int _extraMultiplier = 1;

  final math.Random _random = math.Random();

  final List<SlotSymbol> _symbols = [
    const SlotSymbol(id: 'RUBY', imageUrl: '', valueMultiplier: 80, weight: 8),
    const SlotSymbol(id: 'SAPPHIRE', imageUrl: '', valueMultiplier: 40, weight: 15),
    const SlotSymbol(id: 'EMERALD', imageUrl: '', valueMultiplier: 20, weight: 25),
    const SlotSymbol(id: 'GOLD_WILD', imageUrl: '', valueMultiplier: 0, weight: 10, type: SlotSymbolType.wild),
  ];

  // Visual grid state
  List<List<SlotSymbol>> _grid = [];
  final List<bool> _colSpinning = [false, false, false];
  bool _multiplierSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = SlotController(symbols: _symbols, reelCount: 3, rowsPerReel: 3);
    
    // Initialize a random starting grid
    _grid = List.generate(3, (r) => List.generate(3, (c) => _symbols[_random.nextInt(_symbols.length)]));
    
    UserSession().addListener(_onSessionUpdate);
  }

  @override
  void dispose() {
    UserSession().removeListener(_onSessionUpdate);
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _spin() async {
    if (_isSpinning || UserSession().balance < _betAmount) return;

    setState(() {
      _isSpinning = true;
      _currentWin = 0;
      _extraMultiplier = 1;
      _colSpinning.fillRange(0, 3, true);
      _multiplierSpinning = true;
      UserSession().updateBalance(UserSession().balance - _betAmount);
    });

    final result = _controller.generateResult(_betAmount);

    // Multiplier logic
    final wheelOptions = [1, 2, 3, 5, 10, 20, 50];
    final weights = [40, 20, 15, 10, 8, 5, 2];
    int totalWeight = weights.reduce((a, b) => a + b);
    int randomWeight = _random.nextInt(totalWeight);
    
    int selectedMult = 1;
    int currentSum = 0;
    for (int i = 0; i < wheelOptions.length; i++) {
      currentSum += weights[i];
      if (randomWeight < currentSum) {
        selectedMult = wheelOptions[i];
        break;
      }
    }

    // Staggered stop for columns
    for (int c = 0; c < 3; c++) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _colSpinning[c] = false;
        for (int r = 0; r < 3; r++) {
          _grid[r][c] = result.grid[r][c];
        }
      });
    }

    // Finally stop the multiplier reel
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _multiplierSpinning = false;
      _extraMultiplier = selectedMult;
    });

    final finalWin = result.totalWin * _extraMultiplier;

    if (finalWin > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _currentWin = finalWin;
        UserSession().updateBalance(UserSession().balance + finalWin);
        _isSpinning = false;
      });
      if (finalWin >= _betAmount * 10) {
        _showBigWinDialog(finalWin);
      }
    } else {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  void _showBigWinDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => GlassDialog(
        title: 'TEMPLE TREASURE!',
        message: 'The ancients have blessed you with a massive payout!\n\n₹${amount.toInt()}',
        buttonLabel: 'COLLECT',
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05110A), // Deep Mayan Jungle Green
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
                  BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.15), blurRadius: 200, spreadRadius: 80),
                  BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.05), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildMultiplierReel(),
                const SizedBox(height: 16),
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
            'FORTUNE GEMS 2',
            style: GoogleFonts.bungee(
              color: Colors.amberAccent,
              fontSize: 20,
              letterSpacing: 2,
              shadows: [
                const Shadow(color: Colors.greenAccent, blurRadius: 10),
                const Shadow(color: Colors.amber, blurRadius: 20),
              ],
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            borderColor: Colors.amberAccent.withValues(alpha: 0.4),
            child: Text(
              '₹${UserSession().balance.toInt()}',
              style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierReel() {
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.amber, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
          const BoxShadow(color: Colors.black, blurRadius: 10, blurStyle: BlurStyle.inner),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(37),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_multiplierSpinning)
              _buildHorizontalMotionBlur()
            else
              Text(
                'X$_extraMultiplier',
                style: GoogleFonts.bungee(
                  color: Colors.amberAccent,
                  fontSize: 40,
                  shadows: [
                    const Shadow(color: Colors.orange, blurRadius: 10),
                    const Shadow(color: Colors.redAccent, blurRadius: 20),
                  ],
                ),
              ),
            // Glass reflection
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCabinet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF05110A), // Extremely dark green
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 4),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
          BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 60, spreadRadius: 10),
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
          if (_currentWin > 0 && !_isSpinning)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.8), width: 6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 2, color: Colors.amber.withValues(alpha: 0.2));
  }

  Widget _buildReelColumn(int colIndex) {
    bool isSpinning = _colSpinning[colIndex];

    return Expanded(
      child: isSpinning
          ? _buildVerticalMotionBlur()
          : Column(
              children: [
                _buildCell(0, colIndex),
                _buildCell(1, colIndex),
                _buildCell(2, colIndex),
              ],
            ),
    );
  }

  Widget _buildVerticalMotionBlur() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.greenAccent.withValues(alpha: 0.2),
            Colors.amberAccent.withValues(alpha: 0.4),
            Colors.greenAccent.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
  
  Widget _buildHorizontalMotionBlur() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.amberAccent.withValues(alpha: 0.4),
            Colors.orangeAccent.withValues(alpha: 0.6),
            Colors.amberAccent.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    final symbol = _grid[r][c];
    final isWild = symbol.id == 'GOLD_WILD';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isWild ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWild ? Colors.amberAccent : Colors.amber.withValues(alpha: 0.1),
            width: isWild ? 2 : 1,
          ),
          boxShadow: isWild 
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
    double fontSize = 28;
    String displayText = id;
    bool addIcon = false;
    IconData? iconData;

    switch (id) {
      case 'RUBY':
        gradientColors = [Colors.pinkAccent, Colors.red];
        fontSize = 22;
        addIcon = true;
        iconData = Icons.diamond;
        break;
      case 'SAPPHIRE':
        gradientColors = [Colors.cyanAccent, Colors.blue];
        fontSize = 20;
        addIcon = true;
        iconData = Icons.water_drop;
        break;
      case 'EMERALD':
        gradientColors = [Colors.lightGreenAccent, Colors.green];
        fontSize = 20;
        addIcon = true;
        iconData = Icons.eco;
        break;
      case 'GOLD_WILD':
        gradientColors = [Colors.yellowAccent, Colors.orange];
        fontSize = 26;
        addIcon = true;
        iconData = Icons.star;
        displayText = 'WILD';
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
          Icon(iconData, color: gradientColors.first, size: 36, shadows: [Shadow(color: gradientColors.last.withValues(alpha: 0.8), blurRadius: 10)]),
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
        color: const Color(0xFF0F1A12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: Colors.amber.withValues(alpha: 0.2))),
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
              Text('₹${_betAmount.toInt()}', style: GoogleFonts.bungee(color: Colors.white, fontSize: 24)),
            ],
          ),
          if (_currentWin > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('WIN', style: GoogleFonts.oswald(color: Colors.amberAccent, fontSize: 14, letterSpacing: 1.5)),
                Text('₹${_currentWin.toInt()}', style: GoogleFonts.bungee(color: Colors.amberAccent, fontSize: 24)),
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
