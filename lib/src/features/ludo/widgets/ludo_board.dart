import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ludo_models.dart';
import '../controllers/ludo_controller.dart';
import '../utils/ludo_path.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LUDO BOARD — Realistic physical-board rendering
// ─────────────────────────────────────────────────────────────────────────────

class LudoBoard extends StatelessWidget {
  final LudoController controller;

  const LudoBoard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double size = constraints.maxWidth;
          final double cellSize = size / 15;
          return Stack(
            children: [
              // Drop shadow under the board
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              // Board itself
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomPaint(
                  size: Size(size, size),
                  painter: LudoBoardPainter(cellSize: cellSize),
                ),
              ),
              // Token layer on top
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildTokenLayer(cellSize),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTokenLayer(double cellSize) {
    final List<Widget> widgets = [];

    for (final player in controller.players) {
      for (final token in player.tokens) {
        final pos = _getTokenOffset(token, cellSize);
        final isMovable = controller.movableTokens.contains(token);

        widgets.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: pos.dx,
            top: pos.dy,
            child: _TokenWidget(
              key: ValueKey('${token.color.index}_${token.id}'),
              token: token,
              cellSize: cellSize,
              isMovable: isMovable,
              onTap: () => controller.moveToken(token),
            ),
          ),
        );
      }
    }

    return Stack(children: widgets);
  }

  Offset _getTokenOffset(LudoToken token, double cellSize) {
    if (token.state == TokenState.inBase) {
      final int col = token.id % 2;
      final int row = token.id ~/ 2;
      late final double bx, by;
      // Tokens sit on the 4 home circles within the 4×4 sub-grid of each quadrant
      switch (token.color) {
        case LudoColor.red:
          bx = (1.3 + col * 1.9) * cellSize;
          by = (1.3 + row * 1.9) * cellSize;
        case LudoColor.green:
          bx = (9.8 + col * 1.9) * cellSize;
          by = (1.3 + row * 1.9) * cellSize;
        case LudoColor.yellow:
          bx = (1.3 + col * 1.9) * cellSize;
          by = (9.8 + row * 1.9) * cellSize;
        case LudoColor.blue:
          bx = (9.8 + col * 1.9) * cellSize;
          by = (9.8 + row * 1.9) * cellSize;
      }
      return Offset(bx, by);
    }

    final path = LudoPath.getPath(token.color.index);
    if (token.position >= 0 && token.position < path.length) {
      final gridPos = path[token.position];
      return Offset(
        gridPos.dx * cellSize + cellSize * 0.1,
        gridPos.dy * cellSize + cellSize * 0.1,
      );
    }
    return Offset(7 * cellSize, 7 * cellSize);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Realistic 3-D Token Widget
// ─────────────────────────────────────────────────────────────────────────────

class _TokenWidget extends StatefulWidget {
  final LudoToken token;
  final double cellSize;
  final bool isMovable;
  final VoidCallback onTap;

  const _TokenWidget({
    super.key,
    required this.token,
    required this.cellSize,
    required this.isMovable,
    required this.onTap,
  });

  @override
  State<_TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<_TokenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.22)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    if (widget.isMovable) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TokenWidget old) {
    super.didUpdateWidget(old);
    if (widget.isMovable && !old.isMovable) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isMovable && old.isMovable) {
      _pulse
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.cellSize * 0.8;
    final Color base = _baseColor(widget.token.color);
    final Color light = _lightColor(widget.token.color);
    final Color dark = _darkColor(widget.token.color);

    return GestureDetector(
      onTap: widget.isMovable ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: widget.isMovable ? _scale.value : 1.0,
          child: child,
        ),
        child: SizedBox(
          width: s,
          height: s,
          child: CustomPaint(
            size: Size(s, s),
            painter: _TokenPainter(
              base: base,
              light: light,
              dark: dark,
              isMovable: widget.isMovable,
            ),
          ),
        ),
      ),
    );
  }

  Color _baseColor(LudoColor c) => switch (c) {
        LudoColor.red => const Color(0xFFD32F2F),
        LudoColor.green => const Color(0xFF388E3C),
        LudoColor.yellow => const Color(0xFFF9A825),
        LudoColor.blue => const Color(0xFF1565C0),
      };

  Color _lightColor(LudoColor c) => switch (c) {
        LudoColor.red => const Color(0xFFFF7961),
        LudoColor.green => const Color(0xFF66BB6A),
        LudoColor.yellow => const Color(0xFFFFD54F),
        LudoColor.blue => const Color(0xFF42A5F5),
      };

  Color _darkColor(LudoColor c) => switch (c) {
        LudoColor.red => const Color(0xFF8E0000),
        LudoColor.green => const Color(0xFF1B5E20),
        LudoColor.yellow => const Color(0xFFF57F17),
        LudoColor.blue => const Color(0xFF003C8F),
      };
}

class _TokenPainter extends CustomPainter {
  final Color base;
  final Color light;
  final Color dark;
  final bool isMovable;

  const _TokenPainter({
    required this.base,
    required this.light,
    required this.dark,
    required this.isMovable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Outer drop shadow
    canvas.drawCircle(
      Offset(cx + 1.5, cy + 2.5),
      r * 0.92,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Base (dark bottom rim — gives 3-D depth)
    canvas.drawCircle(
      Offset(cx, cy + r * 0.08),
      r * 0.92,
      Paint()..color = dark,
    );

    // Main body gradient
    final bodyGrad = ui.Gradient.radial(
      Offset(cx - r * 0.25, cy - r * 0.25),
      r * 1.1,
      [light, base, dark],
      [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.88,
      Paint()..shader = bodyGrad,
    );

    // White outline ring
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.88,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1,
    );

    // Inner concave bowl (darker circle in centre)
    canvas.drawCircle(
      Offset(cx, cy + r * 0.04),
      r * 0.48,
      Paint()..color = dark.withValues(alpha: 0.5),
    );

    // Specular highlight (top-left sheen)
    final sheenGrad = ui.Gradient.radial(
      Offset(cx - r * 0.28, cy - r * 0.30),
      r * 0.45,
      [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.0)],
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.88,
      Paint()..shader = sheenGrad,
    );

    // Movable glow ring
    if (isMovable) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TokenPainter old) =>
      old.isMovable != isMovable;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Board Painter — looks like a real Ludo board
// ─────────────────────────────────────────────────────────────────────────────

class LudoBoardPainter extends CustomPainter {
  final double cellSize;

  const LudoBoardPainter({required this.cellSize});

  // Standard safe squares (grid col, row — 0-indexed)
  static const List<Offset> _safeSquares = [
    Offset(1, 6),  Offset(2, 8),
    Offset(6, 2),  Offset(8, 3),
    Offset(13, 6), Offset(12, 8),
    Offset(6, 13), Offset(8, 12),
  ];

  // Exact colors matching a classic physical Ludo board
  static const Color _boardCream    = Color(0xFFFAF0DC); // ivory field
  static const Color _boardLine     = Color(0xFF222222); // crisp black cell lines
  static const Color _redZone       = Color(0xFFE53935);
  static const Color _greenZone     = Color(0xFF43A047);
  static const Color _yellowZone    = Color(0xFFFDD835);
  static const Color _blueZone      = Color(0xFF1E88E5);
  static const Color _redLight      = Color(0xFFEF9A9A);
  static const Color _greenLight    = Color(0xFFA5D6A7);
  static const Color _yellowLight   = Color(0xFFFFF9C4);
  static const Color _blueLight     = Color(0xFF90CAF9);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Cream ivory background
    canvas.drawRect(Offset.zero & size, Paint()..color = _boardCream);

    // 2. Four coloured corner home zones
    _drawHomeZones(canvas, size);

    // 3. Cross-shaped playing area (cream path cells)
    // Already cream from background — just draw the correct borders

    // 4. Home corridor coloured stripes
    _drawHomeCorridors(canvas);

    // 5. Grid lines over the entire board
    _drawGridLines(canvas, size);

    // 6. Safe-square stars
    _drawSafeSquares(canvas);

    // 7. Coloured start squares (arrow squares)
    _drawStartSquares(canvas);

    // 8. Center home triangle (the 4-colour home area)
    _drawCenter(canvas, size);

    // 9. Board border
    _drawBorder(canvas, size);
  }

  // ── 1. Home Zones (the big 6×6 coloured corners) ──────────────────────────

  void _drawHomeZones(Canvas canvas, Size size) {
    const zones = <(double, double, Color, Color)>[
      (0.0, 0.0,  _redZone,    _redLight),    // NW — Red
      (9.0, 0.0,  _greenZone,  _greenLight),  // NE — Green
      (0.0, 9.0,  _yellowZone, _yellowLight), // SW — Yellow
      (9.0, 9.0,  _blueZone,   _blueLight),   // SE — Blue
    ];

    for (final (gx, gy, color, lightColor) in zones) {
      final rect = Rect.fromLTWH(gx * cellSize, gy * cellSize, 6 * cellSize, 6 * cellSize);

      // Filled background (vivid zone colour)
      canvas.drawRect(rect, Paint()..color = color);

      // Inner lighter region (the home-piece area — roughly 4×4 centred)
      final inner = Rect.fromLTWH(
        (gx + 0.8) * cellSize,
        (gy + 0.8) * cellSize,
        4.4 * cellSize,
        4.4 * cellSize,
      );
      final rrect = RRect.fromRectAndRadius(inner, Radius.circular(cellSize * 0.5));
      canvas.drawRRect(rrect, Paint()..color = lightColor);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Four home circles (one for each token slot)
      final cx = gx + 3.0;
      final cy = gy + 3.0;
      final offsets = [
        Offset((cx - 1.0) * cellSize, (cy - 1.0) * cellSize),
        Offset((cx + 1.0) * cellSize, (cy - 1.0) * cellSize),
        Offset((cx - 1.0) * cellSize, (cy + 1.0) * cellSize),
        Offset((cx + 1.0) * cellSize, (cy + 1.0) * cellSize),
      ];
      for (final o in offsets) {
        // Outer ring
        canvas.drawCircle(o, cellSize * 0.42, Paint()..color = color);
        // Inner white
        canvas.drawCircle(o, cellSize * 0.32, Paint()..color = Colors.white);
        // Shadow ring
        canvas.drawCircle(
          o,
          cellSize * 0.42,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  // ── 2. Home Corridors (coloured path into the center) ─────────────────────

  void _drawHomeCorridors(Canvas canvas) {
    // Corridor is col/row 7 (index 7), 5 cells toward center
    final corridors = <(Color, List<Offset>)>[
      // Red → row 7, cols 1–5
      (_redZone, [for (int c = 1; c <= 5; c++) Offset(c.toDouble(), 7)]),
      // Green → col 7, rows 1–5
      (_greenZone, [for (int r = 1; r <= 5; r++) Offset(7, r.toDouble())]),
      // Yellow → row 7, cols 9–13
      (_yellowZone, [for (int c = 9; c <= 13; c++) Offset(c.toDouble(), 7)]),
      // Blue → col 7, rows 9–13
      (_blueZone, [for (int r = 9; r <= 13; r++) Offset(7, r.toDouble())]),
    ];

    for (final (color, tiles) in corridors) {
      for (final t in tiles) {
        // Filled colour cell
        canvas.drawRect(
          Rect.fromLTWH(t.dx * cellSize, t.dy * cellSize, cellSize, cellSize),
          Paint()..color = color,
        );
        // Subtle white sheen
        canvas.drawRect(
          Rect.fromLTWH(t.dx * cellSize, t.dy * cellSize, cellSize, cellSize * 0.35),
          Paint()..color = Colors.white.withValues(alpha: 0.15),
        );
      }
    }
  }

  // ── 3. Grid Lines ──────────────────────────────────────────────────────────

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _boardLine.withValues(alpha: 0.55)
      ..strokeWidth = 0.9;

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), paint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), paint);
    }

    // Heavier border for the 6×6 home zones
    final thick = Paint()
      ..color = _boardLine
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (final (gx, gy) in [(0.0, 0.0), (9.0, 0.0), (0.0, 9.0), (9.0, 9.0)]) {
      canvas.drawRect(
        Rect.fromLTWH(gx * cellSize, gy * cellSize, 6 * cellSize, 6 * cellSize),
        thick,
      );
    }

    // Heavier border for the cross arms
    final crossPaint = Paint()
      ..color = _boardLine.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final rect in [
      Rect.fromLTWH(6 * cellSize, 0, 3 * cellSize, 6 * cellSize),
      Rect.fromLTWH(6 * cellSize, 9 * cellSize, 3 * cellSize, 6 * cellSize),
      Rect.fromLTWH(0, 6 * cellSize, 6 * cellSize, 3 * cellSize),
      Rect.fromLTWH(9 * cellSize, 6 * cellSize, 6 * cellSize, 3 * cellSize),
    ]) {
      canvas.drawRect(rect, crossPaint);
    }
  }

  // ── 4. Safe squares (⭐ star) ──────────────────────────────────────────────

  void _drawSafeSquares(Canvas canvas) {
    for (final sq in _safeSquares) {
      final center = Offset(sq.dx * cellSize + cellSize / 2, sq.dy * cellSize + cellSize / 2);
      // Light cream background to stand out from the cream field
      canvas.drawRect(
        Rect.fromLTWH(sq.dx * cellSize + 1, sq.dy * cellSize + 1, cellSize - 2, cellSize - 2),
        Paint()..color = const Color(0xFFFFF3E0),
      );
      _drawStar(canvas, center, cellSize * 0.34, const Color(0xFFFFB300));
    }
  }

  // ── 5. Start/Arrow squares ─────────────────────────────────────────────────

  void _drawStartSquares(Canvas canvas) {
    const starts = [
      (Offset(1, 6), _redZone),    // Red start
      (Offset(8, 1), _greenZone),  // Green start
      (Offset(13, 8), _blueZone),  // Blue start
      (Offset(6, 13), _yellowZone),// Yellow start
    ];
    for (final (pos, color) in starts) {
      final rect = Rect.fromLTWH(pos.dx * cellSize + 1, pos.dy * cellSize + 1, cellSize - 2, cellSize - 2);
      canvas.drawRect(rect, Paint()..color = color);

      // Simple arrow indicator (small triangle pointing toward center)
      final cx2 = pos.dx * cellSize + cellSize / 2;
      final cy2 = pos.dy * cellSize + cellSize / 2;
      canvas.drawCircle(Offset(cx2, cy2), cellSize * 0.28,
          Paint()..color = Colors.white.withValues(alpha: 0.65));
    }
  }

  // ── 6. Center (4-triangle home with star) ─────────────────────────────────

  void _drawCenter(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cellSize * 1.45;

    // Background for center square (cream)
    canvas.drawRect(
      Rect.fromLTWH(6 * cellSize, 6 * cellSize, 3 * cellSize, 3 * cellSize),
      Paint()..color = _boardCream,
    );

    // 4 triangles pointing to center
    // Green top, Blue right, Yellow bottom, Red left
    final triangles = [
      // Green — top (points down toward center)
      [Offset(cx, cy), Offset(cx - r, cy - r), Offset(cx + r, cy - r)],
      // Blue — right
      [Offset(cx, cy), Offset(cx + r, cy - r), Offset(cx + r, cy + r)],
      // Yellow — bottom
      [Offset(cx, cy), Offset(cx + r, cy + r), Offset(cx - r, cy + r)],
      // Red — left
      [Offset(cx, cy), Offset(cx - r, cy + r), Offset(cx - r, cy - r)],
    ];

    final triColorList = [_greenZone, _blueZone, _yellowZone, _redZone];

    for (int i = 0; i < triangles.length; i++) {
      final pts = triangles[i];
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = triColorList[i]);
    }

    // Divider lines
    canvas.drawLine(Offset(cx - r, cy - r), Offset(cx + r, cy + r),
        Paint()..color = _boardCream..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx + r, cy - r), Offset(cx - r, cy + r),
        Paint()..color = _boardCream..strokeWidth = 1.5);

    // White star at absolute center
    _drawStar(canvas, Offset(cx, cy), cellSize * 0.72, Colors.white);
    // Star outline
    _drawStarOutline(canvas, Offset(cx, cy), cellSize * 0.72, Colors.black.withValues(alpha: 0.25));
  }

  // ── 7. Board outer border ──────────────────────────────────────────────────

  void _drawBorder(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = _boardLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = _starPath(center, radius);
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawStarOutline(Canvas canvas, Offset center, double radius, Color color) {
    final path = _starPath(center, radius);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  Path _starPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = _rad(i * 36.0 - 90.0);
      final r = i.isEven ? radius : radius * 0.40;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  double _rad(double deg) => deg * math.pi / 180.0;

  @override
  bool shouldRepaint(covariant LudoBoardPainter old) => old.cellSize != cellSize;
}
