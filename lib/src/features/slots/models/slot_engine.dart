import 'dart:math' as math;
import 'package:flutter/foundation.dart';

enum SlotSymbolType { low, medium, high, wild, scatter, bonus }

class SlotSymbol {
  final String id;
  final String imageUrl;
  final double valueMultiplier;
  final SlotSymbolType type;
  final int weight;

  const SlotSymbol({
    required this.id,
    required this.imageUrl,
    required this.valueMultiplier,
    this.type = SlotSymbolType.low,
    this.weight = 10,
  });
}

class SlotResult {
  final List<List<SlotSymbol>> grid; // [reelIndex][symbolIndex]
  final double totalWin;
  final List<List<int>> winningLines; // Indices of winning symbols

  SlotResult({
    required this.grid,
    required this.totalWin,
    required this.winningLines,
  });
}

class SlotController extends ChangeNotifier {
  final List<SlotSymbol> symbols;
  final int reelCount;
  final int rowsPerReel;
  final math.Random _random = math.Random();

  SlotController({
    required this.symbols,
    this.reelCount = 3,
    this.rowsPerReel = 3,
  });

  SlotResult generateResult(double betAmount) {
    List<List<SlotSymbol>> grid = List.generate(
      reelCount,
      (_) => List.generate(rowsPerReel, (_) => _getRandomSymbol()),
    );

    // Basic Payline Logic (Example: Horizontal + Diagonal for 3x3)
    double win = 0;
    List<List<int>> wins = [];

    // Horizontal check
    for (int row = 0; row < rowsPerReel; row++) {
      if (grid[0][row].id == grid[1][row].id && grid[1][row].id == grid[2][row].id) {
        win += betAmount * grid[0][row].valueMultiplier;
        wins.add([row, row, row]);
      }
    }

    // Diagonal check (if 3x3)
    if (reelCount == 3 && rowsPerReel == 3) {
      if (grid[0][0].id == grid[1][1].id && grid[1][1].id == grid[2][2].id) {
        win += betAmount * grid[0][0].valueMultiplier;
        wins.add([0, 1, 2]);
      }
      if (grid[0][2].id == grid[1][1].id && grid[1][1].id == grid[2][0].id) {
        win += betAmount * grid[0][2].valueMultiplier;
        wins.add([2, 1, 0]);
      }
    }

    return SlotResult(grid: grid, totalWin: win, winningLines: wins);
  }

  SlotSymbol _getRandomSymbol() {
    int totalWeight = symbols.fold(0, (sum, s) => sum + s.weight);
    int r = _random.nextInt(totalWeight);
    int currentWeight = 0;
    for (var symbol in symbols) {
      currentWeight += symbol.weight;
      if (r < currentWeight) return symbol;
    }
    return symbols.first;
  }
}
