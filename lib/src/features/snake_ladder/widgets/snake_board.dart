import 'package:flutter/material.dart';
import '../controllers/snake_controller.dart';
import '../models/snake_models.dart';
import '../../../core/constants.dart';

extension OffsetExtension on Offset {
  Offset get unit => distance == 0 ? Offset.zero : this / distance;
}

class SnakeBoard extends StatelessWidget {
  final SnakeController controller;

  const SnakeBoard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double cellSize = constraints.maxWidth / 10;
            return Stack(
              children: [
                _buildGrid(cellSize),
                _buildDecorations(cellSize), // Snakes and Ladders
                _buildTokens(cellSize),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(double cellSize) {
    List<Widget> gridItems = [];
    for (int i = 0; i < 100; i++) {
        int pos = 100 - i;
        gridItems.add(
            Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    color: pos % 2 == 0 ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                    "$pos",
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.1),
                        fontSize: 10,
                    ),
                ),
            )
        );
    }
    return GridView.count(
      crossAxisCount: 10,
      physics: const NeverScrollableScrollPhysics(),
      children: gridItems,
    );
  }

  Widget _buildDecorations(double cellSize) {
    return CustomPaint(
      size: Size.infinite,
      painter: SnakeLadderPainter(cellSize: cellSize),
    );
  }

  Widget _buildTokens(double cellSize) {
    List<Widget> tokenWidgets = [];
    for (var player in controller.players) {
      if (player.position > 0) {
        // On the board — animate position
        final Offset pos = _getPositionOffset(player.position, cellSize);
        tokenWidgets.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: pos.dx,
            top: pos.dy,
            child: _buildTokenWidget(player, cellSize),
          ),
        );
      } else {
        // At start — show in bottom-left start zone with offset per player
        tokenWidgets.add(
          Positioned(
            bottom: cellSize * 0.15,
            left: cellSize * 0.15 + player.playerIndex * cellSize * 0.8,
            child: _buildTokenWidget(player, cellSize),
          ),
        );
      }
    }
    return Stack(children: tokenWidgets);
  }

  Offset _getPositionOffset(int pos, double cellSize) {
    int y = 9 - ((pos - 1) ~/ 10);
    int rowOffset = (pos - 1) % 10;
    int x;
    if ((9 - y) % 2 == 0) {
      x = rowOffset;
    } else {
      x = 9 - rowOffset;
    }
    return Offset(x * cellSize + (cellSize * 0.1), y * cellSize + (cellSize * 0.1));
  }

  Widget _buildTokenWidget(SnakePlayer player, double cellSize) {
    Color color = player.playerIndex == 0 ? Colors.red : Colors.blue;
    return Container(
      width: cellSize * 0.8,
      height: cellSize * 0.8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
      child: Icon(player.isBot ? Icons.smart_toy : Icons.person, size: cellSize * 0.4, color: Colors.white),
    );
  }
}

class SnakeLadderPainter extends CustomPainter {
  final double cellSize;

  SnakeLadderPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    _drawLadders(canvas);
    _drawSnakes(canvas);
  }

  void _drawLadders(Canvas canvas) {
    for (var entry in SnakeLadderConfig.ladders.entries) {
      Offset startPos = _getCenterOffset(entry.key);
      Offset endPos = _getCenterOffset(entry.value);

      final railPaint = Paint()
        ..color = Colors.brown.shade400
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      // Calculate direction vector
      Offset dir = endPos - startPos;
      double len = dir.distance;
      Offset unit = dir / len;
      Offset perp = Offset(-unit.dy, unit.dx) * (cellSize * 0.2);

      // Draw side rails
      canvas.drawLine(startPos - perp, endPos - perp, railPaint);
      canvas.drawLine(startPos + perp, endPos + perp, railPaint);

      // Draw rungs
      final rungPaint = Paint()
        ..color = Colors.orange.shade200.withValues(alpha: 0.8)
        ..strokeWidth = 2;

      int rungCount = (len / (cellSize * 0.4)).floor().clamp(3, 15);
      for (int i = 0; i <= rungCount; i++) {
        double t = i / rungCount;
        Offset p = Offset.lerp(startPos, endPos, t)!;
        canvas.drawLine(p - perp, p + perp, rungPaint);
      }
    }
  }

  void _drawSnakes(Canvas canvas) {
    for (var entry in SnakeLadderConfig.snakes.entries) {
      Offset startPos = _getCenterOffset(entry.key);
      Offset endPos = _getCenterOffset(entry.value);

      final bodyPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.green.shade700, Colors.lightGreenAccent],
        ).createShader(Rect.fromPoints(startPos, endPos))
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(startPos.dx, startPos.dy);

      // Create a wavy path
      Offset mid = Offset.lerp(startPos, endPos, 0.5)!;
      Offset dir = endPos - startPos;
      Offset perp = Offset(-dir.dy, dir.dx).unit * 20;
      
      Offset control1 = Offset.lerp(startPos, mid, 0.5)! + perp;
      Offset control2 = Offset.lerp(mid, endPos, 0.5)! - perp;

      path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, endPos.dx, endPos.dy);
      canvas.drawPath(path, bodyPaint);

      // Draw a head
      final headPaint = Paint()..color = Colors.green.shade900;
      canvas.drawCircle(startPos, 6, headPaint);
      // Small dots for eyes
      final eyePaint = Paint()..color = Colors.white;
      canvas.drawCircle(startPos + const Offset(-2, -2), 1.5, eyePaint);
      canvas.drawCircle(startPos + const Offset(2, -2), 1.5, eyePaint);
    }
  }

  Offset _getCenterOffset(int pos) {
    int y = 9 - ((pos - 1) ~/ 10);
    int rowOffset = (pos - 1) % 10;
    int x;
    if ((9 - y) % 2 == 0) {
      x = rowOffset;
    } else {
      x = 9 - rowOffset;
    }
    return Offset(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
