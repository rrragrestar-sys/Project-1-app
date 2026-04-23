import 'package:flutter/material.dart';

/// Provides the 58-step path for each Ludo color on a 15×15 grid.
/// Steps 0–51  → main outer track (52 squares)
/// Steps 52–56 → colored home corridor (5 squares)
/// Step 57     → home (center, counted virtually)
class LudoPath {
  static const int boardSize = 15;

  /// Returns the board coordinates for each step index (0–57) for [playerIndex].
  /// playerIndex: 0=Red(NW), 1=Green(NE), 2=Yellow(SW)→blue bottom left?, 3=Blue(SE)
  static List<Offset> getPath(int playerIndex) {
    final List<Offset> main52 = _main52();
    final int startOffset = playerIndex * 13;

    // Rotate the main track so each player starts from their own entry square
    List<Offset> playerMain = List.generate(
      52,
      (i) => main52[(startOffset + i) % 52],
    );

    // Add the 5-step home corridor + 1 virtual home (center 7,7)
    List<Offset> homeCorridor = _homeCorridor(playerIndex);
    return [...playerMain, ...homeCorridor];
  }

  /// The canonical 52-square outer track, starting from Red's entry (1,6) going clockwise.
  static List<Offset> _main52() {
    List<Offset> p = [];

    // --- Red entry segment: row 6, columns 1→5 ---
    for (int c = 1; c <= 5; c++) { p.add(Offset(c.toDouble(), 6)); }
    // --- Up column 6: rows 5→0 ---
    for (int r = 5; r >= 0; r--) { p.add(Offset(6, r.toDouble())); }
    // --- Green top: row 0, col 7 ---
    p.add(const Offset(7, 0));
    // --- Down column 8: rows 0→5 ---
    for (int r = 0; r <= 5; r++) { p.add(Offset(8, r.toDouble())); }
    // --- Green entry: row 6, cols 9→13 ---
    for (int c = 9; c <= 13; c++) { p.add(Offset(c.toDouble(), 6)); }
    // --- Right edge: col 14, row 7 ---
    p.add(const Offset(14, 7));
    // --- Blue entry: row 8, cols 13→9 ---
    for (int c = 13; c >= 9; c--) { p.add(Offset(c.toDouble(), 8)); }
    // --- Down column 8: rows 9→13 ---
    for (int r = 9; r <= 13; r++) { p.add(Offset(8, r.toDouble())); }
    // --- Bottom edge: row 14, col 7 ---
    p.add(const Offset(7, 14));
    // --- Up column 6: rows 13→9 ---
    for (int r = 13; r >= 9; r--) { p.add(Offset(6, r.toDouble())); }
    // --- Yellow entry: row 8, cols 5→1 ---
    for (int c = 5; c >= 1; c--) { p.add(Offset(c.toDouble(), 8)); }
    // --- Left edge: col 0, row 7 ---
    p.add(const Offset(0, 7));
    // Red's re-entry square: row 6, col 0 (step 51)
    p.add(const Offset(0, 6));

    assert(p.length == 52, 'Main path must be exactly 52 squares, got ${p.length}');
    return p;
  }

  /// 5-square colored home corridor + virtual home center (6 entries, indices 52–57).
  static List<Offset> _homeCorridor(int playerIndex) {
    switch (playerIndex) {
      case 0: // Red → moves right along row 7
        return [
          for (int c = 1; c <= 5; c++) Offset(c.toDouble(), 7),
          const Offset(7, 7), // virtual home
        ];
      case 1: // Green → moves down along col 7
        return [
          for (int r = 1; r <= 5; r++) Offset(7, r.toDouble()),
          const Offset(7, 7),
        ];
      case 2: // Yellow → moves left along row 7
        return [
          for (int c = 13; c >= 9; c--) Offset(c.toDouble(), 7),
          const Offset(7, 7),
        ];
      case 3: // Blue → moves up along col 7
        return [
          for (int r = 13; r >= 9; r--) Offset(7, r.toDouble()),
          const Offset(7, 7),
        ];
      default:
        return [];
    }
  }
}
