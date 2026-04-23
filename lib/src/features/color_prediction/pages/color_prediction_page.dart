import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';
import '../controllers/color_prediction_controller.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/liquid_background.dart';

class ColorPredictionPage extends StatefulWidget {
  const ColorPredictionPage({super.key});

  @override
  State<ColorPredictionPage> createState() => _ColorPredictionPageState();
}

class _ColorPredictionPageState extends State<ColorPredictionPage>
    with SingleTickerProviderStateMixin {
  final ColorPredictionController _ctrl = ColorPredictionController();
  late AnimationController _spin;
  bool _betPlaced = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _ctrl.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.state == PredictionState.spinning) {
      _spin.forward(from: 0);
    }
    if (_ctrl.state == PredictionState.betting) {
      _betPlaced = false;
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onUpdate);
    _ctrl.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildHistoryBar(),
                const SizedBox(height: 12),
                _buildWheelSection(),
                const Spacer(),
                _buildBettingSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'COLOR PREDICTION',
            style: GoogleFonts.righteous(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: UserSession(),
            builder: (context, _) => GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              borderRadius: 20,
              child: Row(
                children: [
                  const Icon(Icons.wallet, color: NeonColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '₹${UserSession().fiatBalance.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHistoryBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _ctrl.history.length,
        itemBuilder: (context, i) {
          final color = _ctrl.history[i];
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _colorOf(color),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _colorOf(color).withValues(alpha: 0.5), blurRadius: 6)],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWheelSection() {
    return Column(
      children: [
        _buildCountdownTimer(),
        const SizedBox(height: 20),
        _buildWheel(),
        const SizedBox(height: 16),
        _buildResultLabel(),
      ],
    );
  }

  Widget _buildCountdownTimer() {
    final double progress = _ctrl.secondsLeft / ColorPredictionController.roundDurationSecs;
    final Color timerColor = _ctrl.secondsLeft <= 10 ? Colors.redAccent : NeonColors.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            color: timerColor,
            backgroundColor: Colors.white10,
          ),
        ),
        Text(
          '${_ctrl.secondsLeft}',
          style: GoogleFonts.righteous(
            color: timerColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWheel() {
    final isSpinning = _ctrl.state == PredictionState.spinning;

    return AnimatedBuilder(
      animation: _spin,
      builder: (_, child) {
        final double angle = isSpinning
            ? _spin.value * math.pi * 6 // 3 full rotations
            : 0.0;
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: CustomPaint(
        size: const Size(180, 180),
        painter: _WheelPainter(resultColor: _ctrl.lastResult?.color),
      ),
    );
  }

  Widget _buildResultLabel() {
    if (_ctrl.state == PredictionState.spinning) {
      return Text(
        'SPINNING...',
        style: GoogleFonts.righteous(color: Colors.white60, fontSize: 18, letterSpacing: 2),
      );
    }
    if (_ctrl.state == PredictionState.result && _ctrl.lastResult != null) {
      final r = _ctrl.lastResult!;
      final Color c = r.isWin ? Colors.greenAccent : Colors.redAccent;
      return Column(
        children: [
          Text(
            r.isWin ? '🎉 WIN! +₹${r.payout.toStringAsFixed(0)}' : '😢 LOST',
            style: GoogleFonts.righteous(
              color: c,
              fontSize: 22,
              shadows: [Shadow(color: c, blurRadius: 10)],
            ),
          ),
        ],
      );
    }
    return Text(
      'PLACE YOUR BET',
      style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
    );
  }

  Widget _buildBettingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildBetAmounts(),
          const SizedBox(height: 14),
          _buildColorButtons(),
        ],
      ),
    );
  }

  Widget _buildBetAmounts() {
    return Row(
      children: [
        Text('BET: ', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        const Spacer(),
        ...([50, 100, 500, 1000].map((amt) {
          final bool sel = _ctrl.betAmount == amt.toDouble();
          return GestureDetector(
            onTap: _ctrl.state == PredictionState.betting ? () => _ctrl.setBet(amt.toDouble()) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? NeonColors.primary.withValues(alpha: 0.25) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? NeonColors.primary : Colors.transparent),
              ),
              child: Text(
                '₹$amt',
                style: GoogleFonts.inter(
                  color: sel ? NeonColors.primary : Colors.white54,
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

  Widget _buildColorButtons() {
    return Row(
      children: [
        _colorBetButton(PredictionColor.red, '🔴 RED', '2×', Colors.redAccent),
        const SizedBox(width: 10),
        _colorBetButton(PredictionColor.violet, '🟣 VIOLET', '4.5×', Colors.purpleAccent),
        const SizedBox(width: 10),
        _colorBetButton(PredictionColor.green, '🟢 GREEN', '2×', Colors.greenAccent),
      ],
    );
  }

  Widget _colorBetButton(PredictionColor color, String label, String multi, Color c) {
    final bool isSelected = _ctrl.selectedColor == color;
    final bool isBetting = _ctrl.state == PredictionState.betting && !_betPlaced;

    return Expanded(
      child: GestureDetector(
        onTap: isBetting ? () {
          _ctrl.selectColor(color);
          if (_ctrl.placeBet()) {
            setState(() => _betPlaced = true);
          }
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? c.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? c : Colors.white12, width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 12)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(multi, style: GoogleFonts.righteous(color: isSelected ? c : Colors.white38, fontSize: 20)),
              Text(label.split(' ')[1], style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorOf(PredictionColor c) => switch (c) {
        PredictionColor.red => Colors.redAccent,
        PredictionColor.green => Colors.greenAccent,
        PredictionColor.violet => Colors.purpleAccent,
      };
}

// ── Color Wheel Painter ────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final PredictionColor? resultColor;

  const _WheelPainter({this.resultColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final segments = [
      (Colors.redAccent, 0.0, 90.0),       // Red: 90°
      (Colors.greenAccent, 90.0, 180.0),   // Green: 90°
      (Colors.purpleAccent, 180.0, 270.0), // Violet: 45°
      (Colors.redAccent, 270.0, 315.0),    // Red: 45°
      (Colors.greenAccent, 315.0, 360.0),  // Green: 45°
    ];

    for (final (color, start, end) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          _rad(start),
          _rad(end - start),
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    // Dividers
    for (int i = 0; i < segments.length; i++) {
      final angle = _rad(segments[i].$2);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
    }

    // Center circle
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.12,
      Paint()..color = const Color(0xFF111122),
    );

    // Pointer at top
    final pointer = Path()
      ..moveTo(cx - 8, 0)
      ..lineTo(cx + 8, 0)
      ..lineTo(cx, 22)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.white);
  }

  double _rad(double d) => d * math.pi / 180.0;

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.resultColor != resultColor;
}
