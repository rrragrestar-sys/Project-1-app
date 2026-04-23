import 'package:flutter/material.dart';
import '../controllers/carrom_controller.dart';
import '../models/carrom_models.dart';
import '../../../core/constants.dart';

class CarromBoard extends StatefulWidget {
  final CarromController controller;

  const CarromBoard({super.key, required this.controller});

  @override
  State<CarromBoard> createState() => _CarromBoardState();
}

class _CarromBoardState extends State<CarromBoard> {
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFC09C67), // Dark wood color
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.brown.shade900, width: 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double size = constraints.maxWidth;
            return GestureDetector(
              onPanStart: (details) {
                  if (widget.controller.isMoving) return;
                  // Only allow drag if starting near striker
                  final striker = widget.controller.coins.firstWhere((c) => c.type == CarromCoinType.striker);
                  final strikerPos = Offset(striker.position.dx * size, striker.position.dy * size);
                  if ((details.localPosition - strikerPos).distance < 100) {
                      _dragStart = details.localPosition;
                      _dragCurrent = details.localPosition;
                  }
              },
              onPanUpdate: (details) {
                  if (_dragStart != null) {
                      setState(() {
                        _dragCurrent = details.localPosition;
                      });
                  }
              },
              onPanEnd: (details) {
                  if (_dragStart != null && _dragCurrent != null) {
                      final delta = _dragStart! - _dragCurrent!;
                      final direction = delta / delta.distance;
                      final power = delta.distance.clamp(0.0, 200.0) / 200.0;
                      
                      widget.controller.shoot(direction, power);
                  }
                  _dragStart = null;
                  _dragCurrent = null;
                  setState(() {});
              },
              child: CustomPaint(
                size: Size(size, size),
                painter: CarromPainter(
                  controller: widget.controller,
                  dragStart: _dragStart,
                  dragCurrent: _dragCurrent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CarromPainter extends CustomPainter {
  final CarromController controller;
  final Offset? dragStart;
  final Offset? dragCurrent;

  CarromPainter({required this.controller, this.dragStart, this.dragCurrent});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoardDesign(canvas, size);
    _drawPockets(canvas, size);
    _drawCoins(canvas, size);
    _drawAimingLine(canvas, size);
  }

  void _drawBoardDesign(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Center Circle
      canvas.drawCircle(size.center(Offset.zero), size.width * 0.15, paint);
      canvas.drawCircle(size.center(Offset.zero), size.width * 0.05, paint);

      // Baseline for striker
      final baselineY = size.height * 0.8;
      canvas.drawLine(Offset(size.width * 0.2, baselineY), Offset(size.width * 0.8, baselineY), paint);
      canvas.drawLine(Offset(size.width * 0.2, baselineY + 10), Offset(size.width * 0.8, baselineY + 10), paint);
  }

  void _drawPockets(Canvas canvas, Size size) {
      final paint = Paint()..color = Colors.black;
      double r = size.width * 0.06;
      canvas.drawCircle(const Offset(0, 0), r, paint);
      canvas.drawCircle(Offset(size.width, 0), r, paint);
      canvas.drawCircle(Offset(0, size.height), r, paint);
      canvas.drawCircle(Offset(size.width, size.height), r, paint);
  }

  void _drawCoins(Canvas canvas, Size size) {
      for (var coin in controller.coins) {
          if (coin.isPocketed) continue;

          Color color;
          switch (coin.type) {
            case CarromCoinType.black: color = Colors.black87; break;
            case CarromCoinType.white: color = Colors.white; break;
            case CarromCoinType.queen: color = Colors.redAccent; break;
            case CarromCoinType.striker: color = AppColors.primary; break;
          }

          final paint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;
          
          final shadowPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

          final pos = Offset(coin.position.dx * size.width, coin.position.dy * size.height);
          final r = coin.radius * size.width;

          canvas.drawCircle(pos + const Offset(2, 2), r, shadowPaint);
          canvas.drawCircle(pos, r, paint);
          
          if (coin.type == CarromCoinType.striker) {
              canvas.drawCircle(pos, r, Paint()..color=Colors.white.withValues(alpha: 0.2)..style=PaintingStyle.stroke..strokeWidth=2);
          }
      }
  }

  void _drawAimingLine(Canvas canvas, Size size) {
      if (dragStart != null && dragCurrent != null) {
          final paint = Paint()
            ..color = AppColors.primary.withValues(alpha: 0.5)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;

          final striker = controller.coins.firstWhere((c) => c.type == CarromCoinType.striker);
          final strikerPos = Offset(striker.position.dx * size.width, striker.position.dy * size.height);
          
          final delta = dragStart! - dragCurrent!;
          final endPos = strikerPos + delta;
          
          canvas.drawLine(strikerPos, endPos, paint);
          canvas.drawCircle(strikerPos, 10, paint);
      }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
