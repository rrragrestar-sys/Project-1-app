import 'dart:math';
import 'slot_engine.dart';
import '../../common/logic/secure_game_controller.dart';

class AdvancedSlotResult {
  final List<List<SlotSymbol>> grid;
  final double totalWin;
  final List<Point<int>> winningPositions;
  final bool hasCascades;
  final int multiplier;

  AdvancedSlotResult({
    required this.grid,
    required this.totalWin,
    required this.winningPositions,
    this.hasCascades = false,
    this.multiplier = 1,
  });
}

class AdvancedSlotController extends SecureGameController {
  final List<SlotSymbol> symbols;
  final int reelCount;
  final int rowsPerReel;
  final Random _random = Random();

  List<List<SlotSymbol>> grid = [];
  bool isSpinning = false;
  int currentMultiplier = 1;
  List<Point<int>> winningPositions = [];

  AdvancedSlotController({
    required this.symbols,
    this.reelCount = 5,
    this.rowsPerReel = 4,
  }) {
    grid = generateInitialGrid();
  }

  @override
  Future<GameOutcome> requestOutcomeFromServer(double betAmount) async {
    // In production, the server returns the entire grid sequence (initial + cascades)
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate server response
    final initialGrid = generateInitialGrid();
    final result = evaluateWins(initialGrid, betAmount, 1);
    
    return GameOutcome(
      isWin: result.totalWin > 0,
      payout: result.totalWin,
      state: {
        'initialGrid': initialGrid,
        'win': result.totalWin,
        'winningPositions': result.winningPositions,
      },
    );
  }

  @override
  Future<void> animateOutcome(GameOutcome outcome) async {
    isSpinning = true;
    notifyListeners();

    // 1. Initial Spin stop
    grid = outcome.state['initialGrid'] as List<List<SlotSymbol>>;
    winningPositions = outcome.state['winningPositions'] as List<Point<int>>;
    notifyListeners();

    // 2. If win, handle cascades (simplified for now)
    if (outcome.isWin) {
      await Future.delayed(const Duration(milliseconds: 1000));
      // Perform one cascade for visual effect
      grid = performCascade(grid, winningPositions);
      winningPositions = [];
      currentMultiplier = 2;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    isSpinning = false;
    currentMultiplier = 1;
    notifyListeners();
  }

  Future<void> spin(double betAmount) async {
    if (isSpinning) return;
    await play(betAmount);
  }

  List<List<SlotSymbol>> generateInitialGrid() {
    return List.generate(
      reelCount,
      (r) => List.generate(rowsPerReel, (c) => _getRandomSymbol(r)),
    );
  }

  AdvancedSlotResult evaluateWins(List<List<SlotSymbol>> grid, double betAmount, int multiplier) {
    List<Point<int>> winningPos = [];
    double totalWin = 0;
    Set<String> possibleWinningSymbols = grid[0].map((s) => s.id).toSet();
    
    for (String symbolId in possibleWinningSymbols) {
      if (symbolId == 'WILD') continue;
      int consecutiveReels = 0;
      List<int> counts = [];
      List<List<int>> symbolRowsPerReel = [];

      for (int r = 0; r < reelCount; r++) {
        var rows = <int>[];
        for (int c = 0; c < rowsPerReel; c++) {
          if (grid[r][c].id == symbolId || grid[r][c].id == 'WILD') {
            rows.add(c);
          }
        }
        if (rows.isEmpty) break;
        consecutiveReels++;
        counts.add(rows.length);
        symbolRowsPerReel.add(rows);
      }

      if (consecutiveReels >= 3) {
        int ways = counts.reduce((a, b) => a * b);
        var symbol = symbols.firstWhere((s) => s.id == symbolId);
        double basePayout = symbol.valueMultiplier;
        if (consecutiveReels == 4) basePayout *= 2;
        if (consecutiveReels == 5) basePayout *= 5;
        totalWin += (betAmount * (basePayout / 100)) * ways * multiplier;
        for (int r = 0; r < consecutiveReels; r++) {
          for (int c in symbolRowsPerReel[r]) {
            winningPos.add(Point(r, c));
          }
        }
      }
    }

    return AdvancedSlotResult(
      grid: grid,
      totalWin: totalWin,
      winningPositions: winningPos,
      multiplier: multiplier,
    );
  }

  List<List<SlotSymbol>> performCascade(List<List<SlotSymbol>> grid, List<Point<int>> winningPositions) {
    List<List<SlotSymbol?>> mutableGrid = grid.map((reel) => List<SlotSymbol?>.from(reel)).toList();
    for (var pos in winningPositions) {
      mutableGrid[pos.x][pos.y] = null;
    }
    for (int r = 0; r < reelCount; r++) {
      List<SlotSymbol> remaining = mutableGrid[r].whereType<SlotSymbol>().toList();
      int gaps = rowsPerReel - remaining.length;
      List<SlotSymbol> newSymbols = List.generate(gaps, (_) => _getRandomSymbol(r));
      grid[r] = [...newSymbols, ...remaining];
    }
    return grid;
  }

  SlotSymbol _getRandomSymbol(int reelIndex) {
    int totalWeight = symbols.fold(0, (sum, s) => sum + s.weight);
    int r = _random.nextInt(totalWeight);
    int currentWeight = 0;
    for (var symbol in symbols) {
      currentWeight += symbol.weight;
      if (r < currentWeight) return symbol;
    }
    return symbols.first;
  }

  AdvancedSlotResult generateResult(double betAmount) {
    final initialGrid = generateInitialGrid();
    return evaluateWins(initialGrid, betAmount, currentMultiplier);
  }
}
