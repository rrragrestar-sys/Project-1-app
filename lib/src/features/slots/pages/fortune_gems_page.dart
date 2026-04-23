import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slot_engine.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';

class FortuneGemsPage extends StatefulWidget {
  const FortuneGemsPage({super.key});

  @override
  State<FortuneGemsPage> createState() => _FortuneGemsPageState();
}

class _FortuneGemsPageState extends State<FortuneGemsPage> with TickerProviderStateMixin {
  late SlotController _controller;
  List<List<SlotSymbol>> _grid = [];
  int _extraMultiplier = 1;
  bool _isSpinning = false;
  double _betAmount = 50.0;
  double _lastWin = 0;
  bool _showWin = false;

  List<bool> _reelSpinning = [false, false, false];
  bool _multiplierSpinning = false;

  late AnimationController _winPulseController;

  final List<SlotSymbol> _symbols = [
    const SlotSymbol(id: 'RED_GEM', imageUrl: 'assets/fg_gem_red.png', valueMultiplier: 5, weight: 10),
    const SlotSymbol(id: 'BLUE_GEM', imageUrl: 'assets/fg_gem_blue.png', valueMultiplier: 2, weight: 20),
    const SlotSymbol(id: 'GREEN_GEM', imageUrl: 'assets/fg_gem_green.png', valueMultiplier: 1, weight: 30),
    const SlotSymbol(id: 'WILD', imageUrl: 'assets/fg_wild.png', valueMultiplier: 0, weight: 5, type: SlotSymbolType.wild),
  ];

  @override
  void initState() {
    super.initState();
    _controller = SlotController(symbols: _symbols, reelCount: 3, rowsPerReel: 3);
    _grid = _controller.generateResult(_betAmount).grid;
    UserSession().addListener(_onSessionUpdate);

    _winPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    UserSession().removeListener(_onSessionUpdate);
    _winPulseController.dispose();
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _spin() async {
    if (_isSpinning || UserSession().balance < _betAmount) return;

    setState(() {
      _isSpinning = true;
      _showWin = false;
      _reelSpinning = [true, true, true];
      _multiplierSpinning = true;
      UserSession().withdrawFiat(_betAmount);
    });

    final result = _controller.generateResult(_betAmount);
    final multipliers = [1, 2, 3, 5, 10, 15];
    final newMult = multipliers[math.Random().nextInt(multipliers.length)];

    // Staggered stop
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _grid[0] = result.grid[0];
      _reelSpinning[0] = false;
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _grid[1] = result.grid[1];
      _reelSpinning[1] = false;
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _grid[2] = result.grid[2];
      _reelSpinning[2] = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _extraMultiplier = newMult;
      _multiplierSpinning = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    double totalWin = result.totalWin * _extraMultiplier;
    
    if (totalWin > 0) {
      setState(() {
        _lastWin = totalWin;
        _showWin = true;
      });
      UserSession().depositFiat(totalWin);
    }

    setState(() {
      _isSpinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0800),
      body: Stack(
        children: [
          // Background Elements
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.0,
                  colors: [
                    Color(0xFF3A1F00),
                    Color(0xFF0D0800),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: _buildMachineFrame(),
                  ),
                ),
                _buildControls(),
              ],
            ),
          ),

          if (_showWin) _buildWinOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'FORTUNE GEMS',
            style: GoogleFonts.cinzel(
              color: Colors.amber, 
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10)],
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            borderColor: Colors.amber.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  '₹${UserSession().fiatBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineFrame() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1005),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Row(
          children: [
            // 3 Main Reels
            Expanded(
              flex: 3,
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildReel(index, _grid[index], _reelSpinning[index]),
                    ),
                  );
                }),
              ),
            ),
            
            // Divider
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 4th Multiplier Reel
            Expanded(
              flex: 1,
              child: _buildMultiplierReel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReel(int reelIndex, List<SlotSymbol> symbols, bool isSpinning) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
        ),
        child: isSpinning
            ? const FastSpinningReel()
            : Column(
                children: symbols.map((symbol) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(symbol.imageUrl, fit: BoxFit.contain),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildMultiplierReel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
        ),
        child: _multiplierSpinning
            ? const FastSpinningMultiplier()
            : Column(
                children: [
                  const Expanded(child: SizedBox()), // Empty top
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        border: const Border.symmetric(horizontal: BorderSide(color: Colors.amber, width: 2)),
                      ),
                      child: Center(
                        child: Text(
                          'x$_extraMultiplier',
                          style: GoogleFonts.righteous(
                            color: Colors.amber,
                            fontSize: 32,
                            shadows: const [Shadow(color: Colors.amberAccent, blurRadius: 10)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()), // Empty bottom
                ],
              ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1005),
        border: Border(top: BorderSide(color: Colors.amber.withValues(alpha: 0.5), width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bet Amount selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL BET', style: GoogleFonts.inter(color: Colors.amber.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                    onPressed: _isSpinning ? null : () {
                      if (_betAmount > 10) setState(() => _betAmount -= 10);
                    },
                  ),
                  Text('₹${_betAmount.toInt()}', style: GoogleFonts.righteous(color: Colors.white, fontSize: 28)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
                    onPressed: _isSpinning ? null : () {
                      if (_betAmount < 1000) setState(() => _betAmount += 10);
                    },
                  ),
                ],
              ),
            ],
          ),
          
          // Spin Button
          GestureDetector(
            onTap: _spin,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isSpinning 
                    ? [Colors.grey.shade800, Colors.grey.shade900]
                    : [Colors.amber.shade300, Colors.amber.shade700],
                ),
                boxShadow: _isSpinning ? [] : [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5),
                ],
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Center(
                child: _isSpinning
                  ? const CircularProgressIndicator(color: Colors.white54)
                  : const Icon(Icons.sync, color: Colors.black, size: 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: FadeTransition(
              opacity: _winPulseController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BIG WIN!',
                    style: GoogleFonts.cinzel(
                      color: Colors.amber,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.amberAccent, blurRadius: 20)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${_lastWin.toStringAsFixed(2)}',
                    style: GoogleFonts.righteous(
                      color: Colors.white,
                      fontSize: 64,
                      shadows: const [Shadow(color: Colors.amber, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ShinyButton(
                    label: 'COLLECT',
                    onPressed: () => setState(() => _showWin = false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FastSpinningReel extends StatefulWidget {
  const FastSpinningReel({super.key});

  @override
  State<FastSpinningReel> createState() => _FastSpinningReelState();
}

class _FastSpinningReelState extends State<FastSpinningReel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _controller.value * 100 - 50),
          child: Opacity(
            opacity: 0.5,
            child: Column(
              children: [
                Expanded(child: Image.asset('assets/fg_gem_red.png')),
                Expanded(child: Image.asset('assets/fg_gem_blue.png')),
                Expanded(child: Image.asset('assets/fg_wild.png')),
                Expanded(child: Image.asset('assets/fg_gem_green.png')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FastSpinningMultiplier extends StatefulWidget {
  const FastSpinningMultiplier({super.key});

  @override
  State<FastSpinningMultiplier> createState() => _FastSpinningMultiplierState();
}

class _FastSpinningMultiplierState extends State<FastSpinningMultiplier> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<int> _mults = [1, 2, 3, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentMult = _mults[(_controller.value * _mults.length).floor() % _mults.length];
        return Center(
          child: Opacity(
            opacity: 0.5,
            child: Text(
              'x$currentMult',
              style: GoogleFonts.righteous(color: Colors.amber, fontSize: 32),
            ),
          ),
        );
      },
    );
  }
}
