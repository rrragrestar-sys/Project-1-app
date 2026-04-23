import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/slot_engine.dart';
import '../widgets/premium_slot_reel.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../core/user_session.dart';

class GenericSlotPage extends StatefulWidget {
  final String title;
  final List<SlotSymbol> symbols;
  final Color themeColor;

  const GenericSlotPage({
    super.key,
    required this.title,
    required this.symbols,
    required this.themeColor,
  });

  @override
  State<GenericSlotPage> createState() => _GenericSlotPageState();
}

class _GenericSlotPageState extends State<GenericSlotPage> {
  late SlotController _engine;
  bool _isSpinning = false;
  SlotResult? _lastResult;
  double _betAmount = 100.0;
  int _finishedReels = 0;
  final NumberFormat _coinFormatter = NumberFormat('#,##,###');

  @override
  void initState() {
    super.initState();
    _engine = SlotController(symbols: widget.symbols, reelCount: 3, rowsPerReel: 3);
  }

  void _spin() {
    if (UserSession().balance < _betAmount || _isSpinning) return;

    setState(() {
      _isSpinning = true;
      _finishedReels = 0;
      _lastResult = _engine.generateResult(_betAmount);
    });
    
    // Deduct bet
    UserSession().updateBalance(UserSession().balance - _betAmount);
  }

  void _onReelFinished() {
    _finishedReels++;
    if (_finishedReels == 3) {
      _processWin();
    }
  }

  void _processWin() {
    if (_lastResult == null) return;
    final win = _lastResult!.totalWin;

    setState(() {
      _isSpinning = false;
    });

    if (win > 0) {
      UserSession().updateBalance(UserSession().balance + win);
      _showWinDialog(win);
    }
  }

  void _showWinDialog(double win) {
    // Premium Win Notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GlassContainer(
          height: 60,
          borderRadius: 30,
          borderColor: widget.themeColor,
          child: Center(
            child: Text(
              'WIN: ${_coinFormatter.format(win)} COINS!',
              style: GoogleFonts.righteous(
                color: Colors.white,
                fontSize: 20,
                shadows: [Shadow(color: widget.themeColor, blurRadius: 10)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title.toUpperCase(),
          style: GoogleFonts.righteous(
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [_buildBalanceDisplay()],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          Column(
            children: [
              const SizedBox(height: 120),
              _buildSlotMachine(),
              const Spacer(),
              _buildControls(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 14),
                const SizedBox(width: 6),
                Text(
                  _coinFormatter.format(UserSession().balance),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotMachine() {
    return Container(
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        borderRadius: 30,
        borderColor: widget.themeColor.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: List.generate(3, (i) => PremiumSlotReel(
              symbols: widget.symbols,
              targetSymbol: _lastResult?.grid[i][0] ?? widget.symbols[0],
              isSpinning: _isSpinning,
              delay: Duration(milliseconds: i * 200),
              onFinished: _onReelFinished,
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return GlassContainer(
      borderRadius: 0,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL BET',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _betBtn('-', () => setState(() => _betAmount = (_betAmount - 100).clamp(100, 10000))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _coinFormatter.format(_betAmount),
                        style: GoogleFonts.righteous(color: Colors.white, fontSize: 24),
                      ),
                    ),
                    _betBtn('+', () => setState(() => _betAmount = (_betAmount + 100).clamp(100, 10000))),
                  ],
                ),
              ],
            ),
          ),
          ShinyButton(
            label: _isSpinning ? '...' : 'SPIN',
            width: 140,
            onPressed: _spin,
            color: widget.themeColor,
          ),
        ],
      ),
    );
  }

  Widget _betBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }
}
