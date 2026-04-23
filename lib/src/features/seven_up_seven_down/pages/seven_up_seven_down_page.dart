import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';
import '../logic/seven_up_controller.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/shiny_button.dart';

class SevenUpSevenDownPage extends StatefulWidget {
  const SevenUpSevenDownPage({super.key});

  @override
  State<SevenUpSevenDownPage> createState() => _SevenUpSevenDownPageState();
}

class _SevenUpSevenDownPageState extends State<SevenUpSevenDownPage>
    with SingleTickerProviderStateMixin {
  final SevenUpController _controller = SevenUpController();
  double _betAmount = 100.0;
  final NumberFormat _coinFormatter = NumberFormat('#,##,###');

  // Result banner animation
  late AnimationController _resultBannerController;
  late Animation<double> _resultBannerOpacity;

  @override
  void initState() {
    super.initState();
    _resultBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultBannerOpacity = CurvedAnimation(
      parent: _resultBannerController,
      curve: Curves.easeIn,
    );
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _resultBannerController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
    if (_controller.lastResult != null && !_controller.isRolling) {
      _resultBannerController.forward(from: 0);
    }
  }

  void _handleRoll() {
    if (_controller.selectedBet == null || _controller.isRolling) return;
    // Balance check
    if (UserSession().fiatBalance < _betAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insufficient balance!'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _controller.play(_betAmount);
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
          '7 UP 7 DOWN',
          style: GoogleFonts.righteous(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [_buildBalanceDisplay()],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildStatusBanner(),
                _buildHistoryRow(),
                Expanded(child: _buildDiceStage()),
                if (_controller.lastResult != null && !_controller.isRolling)
                  _buildResultBanner(),
                _buildBettingBoard(),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

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
            border: Border.all(color: NeonColors.primary.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 14),
                const SizedBox(width: 6),
                Text(
                  _coinFormatter.format(UserSession().fiatBalance),
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

  Widget _buildStatusBanner() {
    String text = 'PLACE YOUR BET';
    Color color = Colors.white70;

    if (_controller.isRolling) {
      text = 'ROLLING...';
      color = NeonColors.primary;
    } else if (_controller.selectedBet != null && _controller.lastResult == null) {
      text = 'READY TO ROLL!';
      color = Colors.greenAccent;
    }

    return Container(
      height: 52,
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.righteous(
          color: color,
          fontSize: 22,
          letterSpacing: 2,
          shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
        ),
      ),
    );
  }

  Widget _buildHistoryRow() {
    // Show actual history from controller (newest first)
    final items = _controller.history;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: false,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final r = items[index];
          Color color;
          if (r.sum < 7) {
            color = Colors.blueAccent;
          } else if (r.sum == 7) {
            color = Colors.amber;
          } else {
            color = Colors.redAccent;
          }

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: 12,
              borderColor: r.isWin ? color : Colors.white10,
              child: Center(
                child: Text(
                  '${r.sum}',
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiceStage() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DiceWidget(value: _controller.die1, isRolling: _controller.isRolling),
          const SizedBox(width: 32),
          // Sum display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '=',
                style: GoogleFonts.righteous(
                    color: Colors.white30, fontSize: 28),
              ),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 12,
                child: Text(
                  '${_controller.die1 + _controller.die2}',
                  style: GoogleFonts.righteous(
                    color: NeonColors.primary,
                    fontSize: 32,
                    shadows: [
                      Shadow(
                          color: NeonColors.primary.withValues(alpha: 0.5),
                          blurRadius: 10)
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          _DiceWidget(value: _controller.die2, isRolling: _controller.isRolling),
        ],
      ),
    );
  }

  Widget _buildResultBanner() {
    final result = _controller.lastResult!;
    final bool isWin = result.isWin;
    final Color color = isWin ? Colors.greenAccent : Colors.redAccent;
    final String label = isWin
        ? '🎉 WIN! +₹${result.payout.toStringAsFixed(0)}'
        : '💸 LOST ₹${_betAmount.toStringAsFixed(0)}';

    return FadeTransition(
      opacity: _resultBannerOpacity,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.righteous(
            color: color,
            fontSize: 20,
            letterSpacing: 1,
            shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
          ),
        ),
      ),
    );
  }

  Widget _buildBettingBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildBetButton(BetOption.down, '7 DOWN', '2×', Colors.blueAccent),
          const SizedBox(width: 10),
          _buildBetButton(BetOption.exact, 'EXACT 7', '5×', Colors.amber),
          const SizedBox(width: 10),
          _buildBetButton(BetOption.up, '7 UP', '2×', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildBetButton(
      BetOption option, String label, String payout, Color color) {
    final bool isSelected = _controller.selectedBet == option;
    return Expanded(
      child: GestureDetector(
        onTap: _controller.isRolling ? null : () => _controller.selectBet(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 90,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.white10,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12)]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                payout,
                style: GoogleFonts.righteous(
                  color: isSelected ? color : Colors.white30,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return GlassContainer(
      borderRadius: 0,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        children: [
          _buildAmountSelector(),
          const SizedBox(height: 16),
          ShinyButton(
            label: _controller.isRolling ? 'ROLLING...' : 'ROLL DICE  🎲',
            width: double.infinity,
            onPressed: _controller.isRolling ? null : _handleRoll,
            color: _controller.selectedBet == null
                ? Colors.grey.shade700
                : NeonColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelector() {
    return Row(
      children: [
        Text(
          'BET: ',
          style: GoogleFonts.inter(
              color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        ...([50, 100, 500, 1000].map((amt) {
          final bool isSelected = _betAmount == amt.toDouble();
          return GestureDetector(
            onTap: () => setState(() => _betAmount = amt.toDouble()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? NeonColors.primary : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '₹$amt',
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        })),
      ],
    );
  }
}

// ── Dice widget ───────────────────────────────────────────────────────────────

class _DiceWidget extends StatelessWidget {
  final int value;
  final bool isRolling;

  const _DiceWidget({required this.value, required this.isRolling});

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isRolling ? 0.5 : 0,
      duration: const Duration(milliseconds: 150),
      child: GlassContainer(
        width: 90,
        height: 90,
        borderRadius: 22,
        borderColor: NeonColors.primary.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(14),
        child: CustomPaint(
          painter: _DicePainter(value),
        ),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int value;

  _DicePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double r = size.width * 0.11;
    final double p = size.width * 0.22;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset tl = Offset(p, p);
    final Offset tr = Offset(size.width - p, p);
    final Offset bl = Offset(p, size.height - p);
    final Offset br = Offset(size.width - p, size.height - p);
    final Offset ml = Offset(p, size.height / 2);
    final Offset mr = Offset(size.width - p, size.height / 2);

    void dot(Offset o) => canvas.drawCircle(o, r, paint);

    switch (value) {
      case 1:
        dot(center);
      case 2:
        dot(tl);
        dot(br);
      case 3:
        dot(tl);
        dot(center);
        dot(br);
      case 4:
        dot(tl);
        dot(tr);
        dot(bl);
        dot(br);
      case 5:
        dot(tl);
        dot(tr);
        dot(center);
        dot(bl);
        dot(br);
      case 6:
        dot(tl);
        dot(tr);
        dot(ml);
        dot(mr);
        dot(bl);
        dot(br);
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter old) => old.value != value;
}
