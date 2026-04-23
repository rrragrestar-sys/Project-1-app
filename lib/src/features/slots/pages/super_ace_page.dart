import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../models/slot_engine.dart';
import '../models/advanced_slot_engine.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';

class SuperAcePage extends StatefulWidget {
  const SuperAcePage({super.key});

  @override
  State<SuperAcePage> createState() => _SuperAcePageState();
}

class _SuperAcePageState extends State<SuperAcePage> with TickerProviderStateMixin {
  late AdvancedSlotController _controller;
  final double _betAmount = 100.0;
  bool _isSpinning = false;
  List<List<SlotSymbol>> _currentGrid = [];
  int _currentMultiplier = 1;
  double _totalWin = 0;
  List<Point<int>> _winningPositions = [];

  final List<SlotSymbol> _symbols = [
    const SlotSymbol(id: 'ACE', imageUrl: 'assets/ace.png', valueMultiplier: 250, weight: 5, type: SlotSymbolType.high),
    const SlotSymbol(id: 'KING', imageUrl: 'assets/king.png', valueMultiplier: 150, weight: 8, type: SlotSymbolType.high),
    const SlotSymbol(id: 'QUEEN', imageUrl: 'assets/queen.png', valueMultiplier: 100, weight: 10, type: SlotSymbolType.medium),
    const SlotSymbol(id: 'JACK', imageUrl: 'assets/jack.png', valueMultiplier: 80, weight: 12, type: SlotSymbolType.medium),
    const SlotSymbol(id: 'SPADE', imageUrl: 'assets/sa_spade.png', valueMultiplier: 50, weight: 20),
    const SlotSymbol(id: 'HEART', imageUrl: 'assets/sa_heart.png', valueMultiplier: 40, weight: 25),
    const SlotSymbol(id: 'CLUB', imageUrl: 'assets/sa_club.png', valueMultiplier: 30, weight: 30),
    const SlotSymbol(id: 'DIAMOND', imageUrl: 'assets/sa_diamond.png', valueMultiplier: 20, weight: 35),
    const SlotSymbol(id: 'WILD', imageUrl: 'assets/wild.png', valueMultiplier: 0, weight: 3, type: SlotSymbolType.wild),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AdvancedSlotController(symbols: _symbols, reelCount: 5, rowsPerReel: 4);
    _currentGrid = _controller.generateInitialGrid();
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
      _currentMultiplier = 1;
      _totalWin = 0;
      _winningPositions = [];
      UserSession().updateBalance(UserSession().balance - _betAmount);
    });

    // 1. Reel spinning animation delay
    await Future.delayed(const Duration(seconds: 2));

    List<List<SlotSymbol>> grid = _controller.generateInitialGrid();
    int currentMult = 1;
    double accumulatedWin = 0;

    // Cascade loop
    while (true) {
      final result = _controller.evaluateWins(grid, _betAmount, currentMult);
      
      setState(() {
        _currentGrid = grid;
        _currentMultiplier = currentMult;
        _winningPositions = result.winningPositions;
        _isSpinning = false; // Initial spin over, now cascading
      });

      if (result.winningPositions.isEmpty) {
        break; // No more wins
      }

      // Briefly show winning positions before cascading
      await Future.delayed(const Duration(milliseconds: 1000));
      
      accumulatedWin += result.totalWin;

      // Animate cascade
      grid = _controller.performCascade(grid, result.winningPositions);
      setState(() {
        _winningPositions = []; // Clear highlights to show dropping
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Increase multiplier for next cascade
      if (currentMult == 1) {
        currentMult = 2;
      } else if (currentMult == 2) {
        currentMult = 3;
      } else if (currentMult == 3) {
        currentMult = 5;
      }
    }

    setState(() {
      _isSpinning = false;
      _totalWin = accumulatedWin;
      if (accumulatedWin > 0) {
        UserSession().updateBalance(UserSession().balance + accumulatedWin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003011), // Luxury Casino Green Felt
      body: Stack(
        children: [
          // Background Texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/banner.png', fit: BoxFit.cover),
            ),
          ),
          // Gradient Vignette
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.transparent, Colors.black87],
                radius: 1.5,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMultiplierTrail(),
                const Spacer(),
                _buildSlotGrid(),
                const Spacer(),
                _buildControls(),
              ],
            ),
          ),
          if (_totalWin > 0 && !_isSpinning && _winningPositions.isEmpty) _buildBigWinOverlay(),
        ],
      ),
    );
  }

  Widget _buildBigWinOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _totalWin = 0; // Dismiss overlay
          });
        },
        child: Container(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SUPER WIN!',
                  style: GoogleFonts.oswald(
                    color: Colors.amber,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    shadows: [
                      const Shadow(color: Colors.orange, blurRadius: 20),
                      const Shadow(color: Colors.red, blurRadius: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '+₹${_totalWin.toInt()}',
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
            'SUPER ACE',
            style: GoogleFonts.oswald(
              color: const Color(0xFFFFD700),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              shadows: [
                const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            borderColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
            child: Text(
              '₹${UserSession().balance.toInt()}',
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierTrail() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [1, 2, 3, 5].map((m) {
          bool isActive = _currentMultiplier == m;
          bool isPassed = _currentMultiplier > m && m != 5;
          return AnimatedScale(
            scale: isActive ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              borderRadius: 12,
              backgroundGradient: LinearGradient(
                colors: isActive 
                    ? [const Color(0xFFFFD700).withValues(alpha: 0.2), const Color(0xFFFFD700).withValues(alpha: 0.1)] 
                    : [Colors.black45, Colors.black87],
              ),
              borderColor: isActive ? const Color(0xFFFFD700) : Colors.white10,
              child: Text(
                'x$m',
                style: GoogleFonts.oswald(
                  color: isActive ? const Color(0xFFFFD700) : (isPassed ? Colors.white70 : Colors.white30),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: isActive ? [const Shadow(color: Color(0xFFFFD700), blurRadius: 10)] : [],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlotGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        borderColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
        backgroundGradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.5), Colors.black.withValues(alpha: 0.7)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_controller.reelCount, (r) {
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_controller.rowsPerReel, (c) {
                  bool isWinning = _winningPositions.contains(Point(r, c));
                  return _buildSymbolCell(_currentGrid[r][c].id, isWinning, r);
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSymbolCell(String id, bool isWinning, int reelIndex) {
    // Add staggered spinning effect
    bool isReelSpinning = _isSpinning && _winningPositions.isEmpty; // Spinning, not cascading
    
    return Container(
      height: 85,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isWinning ? const Color(0xFFFFD700).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinning ? const Color(0xFFFFD700) : Colors.white10,
          width: isWinning ? 2 : 1,
        ),
        boxShadow: isWinning ? [
          BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.5), blurRadius: 10)
        ] : [],
      ),
      child: Center(
        child: isReelSpinning
            ? _buildMotionBlur()
            : _getPremiumSymbol(id),
      ),
    );
  }

  Widget _buildMotionBlur() {
    return Container(
      width: 40,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFFFFD700).withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.8),
            const Color(0xFFFFD700).withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _getPremiumSymbol(String id) {
    // Render Custom 3D Assets
    if (['SPADE', 'HEART', 'CLUB', 'DIAMOND'].contains(id)) {
      String assetName = '';
      switch (id) {
        case 'SPADE': assetName = 'assets/sa_spade.png'; break;
        case 'HEART': assetName = 'assets/sa_heart.png'; break;
        case 'CLUB': assetName = 'assets/sa_club.png'; break;
        case 'DIAMOND': assetName = 'assets/sa_diamond.png'; break;
      }
      return Image.asset(
        assetName,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) => _buildTextSymbol(id),
      );
    }
    
    // Fallback to beautiful text for Face Cards and Wild
    return _buildTextSymbol(id);
  }

  Widget _buildTextSymbol(String id) {
    String text = '';
    Color glowColor = Colors.white;
    List<Color> gradientColors = [Colors.white, Colors.grey];

    switch (id) {
      case 'ACE':
        text = 'A';
        glowColor = const Color(0xFFFFD700);
        gradientColors = [const Color(0xFFFFF8DC), const Color(0xFFDAA520)];
        break;
      case 'KING':
        text = 'K';
        glowColor = const Color(0xFFFF8C00);
        gradientColors = [const Color(0xFFFFE4B5), const Color(0xFFFF8C00)];
        break;
      case 'QUEEN':
        text = 'Q';
        glowColor = const Color(0xFFFF1493);
        gradientColors = [const Color(0xFFFFB6C1), const Color(0xFFFF1493)];
        break;
      case 'JACK':
        text = 'J';
        glowColor = const Color(0xFF00BFFF);
        gradientColors = [const Color(0xFFE0FFFF), const Color(0xFF00BFFF)];
        break;
      case 'WILD':
        text = 'JOKER';
        glowColor = Colors.purpleAccent;
        gradientColors = [Colors.pinkAccent, Colors.purple];
        break;
      // Fallbacks in case image fails
      case 'SPADE': text = '♠'; glowColor = Colors.grey; break;
      case 'HEART': text = '♥'; glowColor = Colors.redAccent; break;
      case 'CLUB': text = '♣'; glowColor = Colors.grey; break;
      case 'DIAMOND': text = '♦'; glowColor = Colors.redAccent; break;
      default: text = '?';
    }

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.rye(
          fontSize: text == 'JOKER' ? 18 : 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(color: glowColor.withValues(alpha: 0.8), blurRadius: 15, offset: const Offset(0, 0)),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      borderRadius: 32,
      borderColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
      backgroundGradient: LinearGradient(
        colors: [Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL BET', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
              Text(
                '₹${_betAmount.toInt()}', 
                style: GoogleFonts.oswald(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          ShinyButton(
            label: _isSpinning ? '...' : 'SPIN',
            onPressed: _isSpinning ? null : _spin,
            color: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }
}
