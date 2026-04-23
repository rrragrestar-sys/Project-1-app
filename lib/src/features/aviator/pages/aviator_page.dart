import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';
import '../logic/aviator_controller.dart';
import '../widgets/aviator_painter.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';

class AviatorPage extends StatefulWidget {
  const AviatorPage({super.key});

  @override
  State<AviatorPage> createState() => _AviatorPageState();
}

class _AviatorPageState extends State<AviatorPage> with TickerProviderStateMixin {
  late AviatorController _controller;
  
  // Dual Bet State
  double _bet1 = 100.0;
  bool _isBet1Placed = false;
  double? _cashout1;
  bool _autoCashout1Enabled = false;
  double _autoCashout1Val = 2.0;

  double _bet2 = 100.0;
  bool _isBet2Placed = false;
  double? _cashout2;
  bool _autoCashout2Enabled = false;
  double _autoCashout2Val = 5.0;
  
  final List<double> _history = [1.24, 5.02, 1.00, 15.42, 2.15, 1.88, 3.42];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AviatorController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.addListener(_onControllerUpdate);
    _startNewRound();
  }

  void _onControllerUpdate() {
    if (_controller.state == AviatorState.flying) {
      // Auto-cashout logic
      if (_isBet1Placed && _cashout1 == null && _autoCashout1Enabled && _controller.multiplier >= _autoCashout1Val) {
        _handleCashout(1);
      }
      if (_isBet2Placed && _cashout2 == null && _autoCashout2Enabled && _controller.multiplier >= _autoCashout2Val) {
        _handleCashout(2);
      }
    }
    if (mounted) setState(() {});
  }

  void _startNewRound() async {
    _isBet1Placed = false;
    _cashout1 = null;
    _isBet2Placed = false;
    _cashout2 = null;
    await _controller.startBetting();
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _controller.beginFlight();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleBet(int index) {
    double amt = index == 1 ? _bet1 : _bet2;
    if (_controller.state == AviatorState.betting) {
      if (UserSession().withdrawFiat(amt)) {
        setState(() {
          if (index == 1) {
            _isBet1Placed = true;
          } else {
            _isBet2Placed = true;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insufficient balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: NeonColors.primary,
          ),
        );
      }
    }
  }

  void _handleCashout(int index) {
    if (_controller.state == AviatorState.flying) {
      double amt = index == 1 ? _bet1 : _bet2;
      double? existing = index == 1 ? _cashout1 : _cashout2;
      
      if (existing == null) {
        setState(() {
          double m = _controller.multiplier;
          if (index == 1) {
            _cashout1 = m;
          } else {
            _cashout2 = m;
          }
          UserSession().depositFiat(amt * m);
        });
      }
    }
  }

  Color _getMultiplierColor() {
    double m = _controller.multiplier;
    if (_controller.state == AviatorState.crashed) return Colors.red;
    if (m < 2.0) return Colors.white;
    if (m < 10.0) return NeonColors.primary;
    return NeonColors.tertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium Maroon Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.5),
                radius: 1.5,
                colors: [
                  Color(0xFF2A0000),
                  Color(0xFF110000),
                  Colors.black,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildHistoryBar(),
                Expanded(child: _buildGameGraph()),
                _buildDualBettingPanel(),
                const SizedBox(height: 10),
              ],
            ),
          ),
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
            icon: const Icon(Icons.arrow_back_ios, color: NeonColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'AVIATOR',
            style: GoogleFonts.righteous(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 2,
              shadows: [
                Shadow(color: NeonColors.primary.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: UserSession(),
            builder: (context, _) => GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 20,
              borderColor: NeonColors.primary.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.wallet, color: NeonColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '₹${UserSession().fiatBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryBar() {
    return Container(
      height: 30,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final val = _history[index];
          final color = val < 2.0 ? Colors.grey : (val < 10.0 ? NeonColors.primary : NeonColors.tertiary);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Center(
              child: Text(
                '${val.toStringAsFixed(2)}x',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameGraph() {
    if (_controller.state == AviatorState.crashed && _cashout1 == null && _cashout2 == null) {
       Future.delayed(const Duration(seconds: 3), () {
         if (mounted && _controller.state == AviatorState.crashed) _startNewRound();
       });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        borderRadius: 24,
        borderColor: NeonColors.primary.withValues(alpha: 0.4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: AviatorPainter(
                    progress: _controller.progress,
                    multiplier: _controller.multiplier,
                    isCrashed: _controller.state == AviatorState.crashed,
                    gridOffset: _controller.progress,
                    primaryColor: NeonColors.primary,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.state == AviatorState.betting)
                      Text(
                        'WAITING FOR NEXT ROUND',
                        style: GoogleFonts.righteous(
                          color: Colors.white70,
                          fontSize: 20,
                          letterSpacing: 2,
                          shadows: [const Shadow(color: Colors.black, blurRadius: 10)],
                        ),
                      ),
                    if (_controller.state == AviatorState.flying || _controller.state == AviatorState.crashed)
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Text(
                          '${_controller.multiplier.toStringAsFixed(2)}x',
                          style: GoogleFonts.righteous(
                            color: _getMultiplierColor(),
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: _getMultiplierColor().withValues(alpha: 0.5), blurRadius: 20),
                              const Shadow(color: Colors.black, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDualBettingPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildBetCard(1)),
          const SizedBox(width: 12),
          Expanded(child: _buildBetCard(2)),
        ],
      ),
    );
  }

  Widget _buildBetCard(int index) {
    bool isPlaced = index == 1 ? _isBet1Placed : _isBet2Placed;
    double? cashout = index == 1 ? _cashout1 : _cashout2;
    double betAmt = index == 1 ? _bet1 : _bet2;
    bool autoEnabled = index == 1 ? _autoCashout1Enabled : _autoCashout2Enabled;
    double autoVal = index == 1 ? _autoCashout1Val : _autoCashout2Val;

    bool canCashout = _controller.state == AviatorState.flying && isPlaced && cashout == null;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 20,
      borderColor: NeonColors.primary.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AUTO',
                style: TextStyle(color: autoEnabled ? NeonColors.primary : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Switch(
                value: autoEnabled,
                onChanged: (v) => setState(() => index == 1 ? _autoCashout1Enabled = v : _autoCashout2Enabled = v),
                activeThumbColor: NeonColors.primary,
                activeTrackColor: NeonColors.primary.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white10,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (autoEnabled) _buildAutoInput(index, autoVal),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _amtBtn('-', () => setState(() => index == 1 ? _bet1 = math.max(10, _bet1 - 10) : _bet2 = math.max(10, _bet2 - 10))),
              Expanded(
                child: Center(
                  child: Text(
                    '₹${betAmt.toInt()}',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _amtBtn('+', () => setState(() => index == 1 ? _bet1 += 10 : _bet2 += 10)),
            ],
          ),
          const SizedBox(height: 16),
          ShinyButton(
            label: canCashout ? 'CASHOUT\n₹${(betAmt * _controller.multiplier).toInt()}' : (cashout != null ? 'WON\n₹${(betAmt * cashout).toInt()}' : (isPlaced ? 'WAITING' : 'BET')),
            color: canCashout ? NeonColors.primary : (cashout != null ? NeonColors.tertiary : (isPlaced ? Colors.grey : Colors.green)),
            onPressed: canCashout ? () => _handleCashout(index) : (isPlaced || _controller.state != AviatorState.betting ? null : () => _handleBet(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoInput(int index, double val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _amtBtn('<', () => setState(() => index == 1 ? _autoCashout1Val = math.max(1.1, _autoCashout1Val - 0.1) : _autoCashout2Val = math.max(1.1, _autoCashout2Val - 0.1))),
        Expanded(
          child: Center(
            child: Text(
              '${val.toStringAsFixed(1)}x',
              style: const TextStyle(color: NeonColors.primary, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ),
        _amtBtn('>', () => setState(() => index == 1 ? _autoCashout1Val += 0.1 : _autoCashout2Val += 0.1)),
      ],
    );
  }

  Widget _amtBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
