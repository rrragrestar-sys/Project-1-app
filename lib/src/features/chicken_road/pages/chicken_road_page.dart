
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

enum ChickenGameState { betting, playing, cashedOut, dead }
enum DifficultyMode { low, medium, high }

class ChickenRoadPage extends StatefulWidget {
  const ChickenRoadPage({super.key});

  @override
  State<ChickenRoadPage> createState() => _ChickenRoadPageState();
}

class _ChickenRoadPageState extends State<ChickenRoadPage>
    with TickerProviderStateMixin {
  // Game configuration
  static const int totalRows = 8;
  static const int totalCols = 5;

  ChickenGameState _gameState = ChickenGameState.betting;
  DifficultyMode _difficulty = DifficultyMode.medium;

  // Balance & Bet
  double _userBalance = 12500.50;
  double _betAmount = 100.0;

  // Game state
  int _chickenRow = -1; // current row (0 = bottom start)
  int _chickenCol = 2;  // center column
  double _currentMultiplier = 1.0;
  double _cashedOutAt = 0.0;

  // Grid: _boomGrid[row][col] = true means car is here
  List<List<bool>> _boomGrid = [];
  // Revealed cells after loss
  List<List<bool>> _revealed = [];

  // Animation controllers
  late AnimationController _chickenBounceController;
  late Animation<double> _chickenBounce;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _explosionController;



  // Multiplier tables per difficulty
  static const Map<DifficultyMode, List<double>> _multiplierTable = {
    DifficultyMode.low:    [1.12, 1.26, 1.41, 1.59, 1.78, 2.00, 2.25, 2.53],
    DifficultyMode.medium: [1.22, 1.49, 1.82, 2.22, 2.71, 3.30, 4.03, 4.92],
    DifficultyMode.high:   [1.47, 2.14, 3.14, 4.60, 6.75, 9.90, 14.5, 21.3],
  };

  static const Map<DifficultyMode, int> _carsPerRow = {
    DifficultyMode.low: 1,
    DifficultyMode.medium: 2,
    DifficultyMode.high: 3,
  };

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _chickenBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _chickenBounce = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _chickenBounceController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

  }

  @override
  void dispose() {
    _chickenBounceController.dispose();
    _glowController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  void _startGame() {
    if (_userBalance < _betAmount) return;

    // Generate boom grid
    _boomGrid = List.generate(totalRows, (_) => List.filled(totalCols, false));
    _revealed = List.generate(totalRows, (_) => List.filled(totalCols, false));

    final carsPerRow = _carsPerRow[_difficulty]!;
    for (int row = 0; row < totalRows; row++) {
      final List<int> cols = List.generate(totalCols, (i) => i)..shuffle(_random);
      for (int c = 0; c < carsPerRow; c++) {
        _boomGrid[row][cols[c]] = true;
      }
    }

    setState(() {
      _userBalance -= _betAmount;
      _chickenRow = -1;
      _chickenCol = 2;
      _currentMultiplier = 1.0;
      _cashedOutAt = 0.0;
      _gameState = ChickenGameState.playing;
    });
  }

  void _onTilePressed(int row, int col) {
    if (_gameState != ChickenGameState.playing) return;
    // Must tap the next row from chicken's current position
    if (row != _chickenRow + 1) return;

    if (_boomGrid[row][col]) {
      // Hit a car!
      setState(() {
        _chickenRow = row;
        _chickenCol = col;
        _gameState = ChickenGameState.dead;
        // Reveal all cars
        for (int r = 0; r < totalRows; r++) {
          for (int c = 0; c < totalCols; c++) {
            if (_boomGrid[r][c]) _revealed[r][c] = true;
          }
        }
      });
      _explosionController.forward(from: 0.0);
    } else {
      // Safe!
      setState(() {
        _chickenRow = row;
        _chickenCol = col;
        _currentMultiplier = _multiplierTable[_difficulty]![row];
        _revealed[row][col] = false; // not a car
      });
      _chickenBounceController.forward(from: 0.0).then((_) {
        _chickenBounceController.reverse();
      });
    }
  }

  void _cashOut() {
    if (_gameState != ChickenGameState.playing) return;
    if (_chickenRow < 0) return; // Haven't stepped anywhere yet
    setState(() {
      _cashedOutAt = _currentMultiplier;
      _userBalance += _betAmount * _currentMultiplier;
      _gameState = ChickenGameState.cashedOut;
    });
  }

  void _reset() {
    setState(() {
      _gameState = ChickenGameState.betting;
      _chickenRow = -1;
      _chickenCol = 2;
      _currentMultiplier = 1.0;
      _cashedOutAt = 0.0;
      _boomGrid = [];
      _revealed = [];
    });
  }

  Color _getDifficultyColor() {
    switch (_difficulty) {
      case DifficultyMode.low:
        return Colors.greenAccent;
      case DifficultyMode.medium:
        return Colors.orangeAccent;
      case DifficultyMode.high:
        return Colors.redAccent;
    }
  }

  String _getDifficultyLabel() {
    switch (_difficulty) {
      case DifficultyMode.low:
        return 'LOW RISK';
      case DifficultyMode.medium:
        return 'MEDIUM RISK';
      case DifficultyMode.high:
        return 'HIGH RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Multiplier display
          _buildMultiplierDisplay(),
          // Game grid
          Expanded(child: _buildGameGrid()),
          // Control panel
          _buildControlPanel(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'CHICKEN ROAD',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NeonColors.primary.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              '${_userBalance.toStringAsFixed(2)} USD',
              style: const TextStyle(
                color: NeonColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierDisplay() {
    final isPlaying = _gameState == ChickenGameState.playing;
    final isDead = _gameState == ChickenGameState.dead;
    final isCashedOut = _gameState == ChickenGameState.cashedOut;

    Color displayColor = Colors.white;
    String displayText = '1.00x';
    String? subText;

    if (isPlaying && _chickenRow >= 0) {
      displayColor = Colors.greenAccent;
      displayText = '${_currentMultiplier.toStringAsFixed(2)}x';
      subText = 'CASH OUT: \$${(_betAmount * _currentMultiplier).toStringAsFixed(2)}';
    } else if (isDead) {
      displayColor = Colors.redAccent;
      displayText = '💥 BOOM!';
      subText = 'You lost \$${_betAmount.toStringAsFixed(2)}';
    } else if (isCashedOut) {
      displayColor = Colors.greenAccent;
      displayText = '${_cashedOutAt.toStringAsFixed(2)}x';
      subText = '+\$${(_betAmount * _cashedOutAt).toStringAsFixed(2)} WON!';
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: NeonColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: displayColor.withValues(alpha: _glowAnimation.value * 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: displayColor.withValues(alpha: _glowAnimation.value * 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: TextStyle(
                      color: displayColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: displayColor.withValues(alpha: 0.6), blurRadius: 12),
                      ],
                    ),
                  ),
                  if (subText != null)
                    Text(
                      subText,
                      style: TextStyle(color: displayColor.withValues(alpha: 0.8), fontSize: 11),
                    ),
                ],
              ),
              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getDifficultyColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getDifficultyColor().withValues(alpha: 0.4)),
                ),
                child: Text(
                  _getDifficultyLabel(),
                  style: TextStyle(
                    color: _getDifficultyColor(),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameGrid() {
    final isPlaying = _gameState == ChickenGameState.playing;
    final isDead = _gameState == ChickenGameState.dead;
    final isCashedOut = _gameState == ChickenGameState.cashedOut;
    final isBetting = _gameState == ChickenGameState.betting;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Next row target row label (show at top for rows being built upwards)
          Expanded(
            child: ListView.builder(
              reverse: true, // Row 0 at bottom, row 7 at top
              itemCount: totalRows,
              itemBuilder: (context, rowIndex) {
                final multiplier = _multiplierTable[_difficulty]![rowIndex];
                final isCurrentRow = rowIndex == _chickenRow;
                final isNextRow = rowIndex == _chickenRow + 1;
                final isPastRow = rowIndex <= _chickenRow;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Row multiplier label
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${multiplier.toStringAsFixed(2)}x',
                          style: TextStyle(
                            color: isCurrentRow
                                ? Colors.greenAccent
                                : (isPastRow ? Colors.white38 : Colors.white30),
                            fontSize: 9,
                            fontWeight: isCurrentRow ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tiles
                      Expanded(
                        child: Row(
                          children: List.generate(totalCols, (colIndex) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: _buildTile(
                                  rowIndex,
                                  colIndex,
                                  isPlaying: isPlaying,
                                  isDead: isDead,
                                  isCashedOut: isCashedOut,
                                  isBetting: isBetting,
                                  isCurrentRow: isCurrentRow,
                                  isNextRow: isNextRow,
                                  isPastRow: isPastRow,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Chicken start area
          _buildChickenStart(),
        ],
      ),
    );
  }

  Widget _buildTile(
    int rowIndex,
    int colIndex, {
    required bool isPlaying,
    required bool isDead,
    required bool isCashedOut,
    required bool isBetting,
    required bool isCurrentRow,
    required bool isNextRow,
    required bool isPastRow,
  }) {
    final isChickenHere = rowIndex == _chickenRow && colIndex == _chickenCol;
    final isBoom = _revealed.isNotEmpty && _revealed[rowIndex][colIndex];
    final isExplodedTile = isDead && rowIndex == _chickenRow && colIndex == _chickenCol;

    // Decide tile appearance
    Color tileColor;
    Color borderColor;
    Widget? tileContent;
    double opacity = 1.0;

    if (isBetting) {
      tileColor = NeonColors.surface;
      borderColor = Colors.white10;
      opacity = 0.4;
    } else if (isChickenHere && isDead) {
      tileColor = Colors.red.shade900;
      borderColor = Colors.redAccent;
    } else if (isChickenHere) {
      tileColor = Colors.green.shade900;
      borderColor = Colors.greenAccent;
    } else if (isPastRow && !isCurrentRow) {
      tileColor = Colors.green.withValues(alpha: 0.08);
      borderColor = Colors.greenAccent.withValues(alpha: 0.2);
    } else if (isBoom) {
      tileColor = Colors.red.withValues(alpha: 0.2);
      borderColor = Colors.redAccent.withValues(alpha: 0.5);
    } else if (isNextRow && isPlaying) {
      tileColor = NeonColors.surface;
      borderColor = Colors.amber.withValues(alpha: 0.6);
    } else {
      tileColor = NeonColors.surface;
      borderColor = Colors.white12;
      opacity = (isPlaying && !isNextRow && !isPastRow) ? 0.5 : 1.0;
    }

    // Content
    if (isChickenHere) {
      tileContent = _buildChickenEmoji(isExplodedTile);
    } else if (isBoom) {
      tileContent = const Text('🚗', style: TextStyle(fontSize: 18));
    } else if (isNextRow && isPlaying) {
      tileContent = const Text('❓', style: TextStyle(fontSize: 16, color: Colors.white54));
    } else if (isCashedOut && isPastRow && !isChickenHere) {
      tileContent = const Icon(Icons.check, color: Colors.greenAccent, size: 14);
    }

    final canTap = isPlaying && isNextRow;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: canTap ? () => _onTilePressed(rowIndex, colIndex) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isNextRow && isPlaying
                ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 8)]
                : (isChickenHere
                    ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 12)]
                    : []),
          ),
          child: Center(child: tileContent),
        ),
      ),
    );
  }

  Widget _buildChickenEmoji(bool isDead) {
    return AnimatedBuilder(
      animation: _chickenBounce,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _chickenBounce.value),
          child: Text(
            isDead ? '💀' : '🐔',
            style: const TextStyle(fontSize: 22),
          ),
        );
      },
    );
  }

  Widget _buildChickenStart() {
    final isAtStart = _chickenRow == -1;
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(
        children: [
          const SizedBox(width: 50),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_gameState == ChickenGameState.betting)
                  const Text(
                    '🐔  Start a round to begin!',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  )
                else if (isAtStart)
                  const Text(
                    '🐔  Tap a tile above to hop!',
                    style: TextStyle(color: Colors.amber, fontSize: 12),
                  )
                else
                  const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    final isPlaying = _gameState == ChickenGameState.playing;
    final isBetting = _gameState == ChickenGameState.betting;
    final isDone = _gameState == ChickenGameState.dead || _gameState == ChickenGameState.cashedOut;
    final canCashOut = isPlaying && _chickenRow >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bet amount row
          if (isBetting) ...[
            // Difficulty picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: DifficultyMode.values.map((d) {
                final selected = _difficulty == d;
                final label = d == DifficultyMode.low ? 'LOW' : (d == DifficultyMode.medium ? 'MED' : 'HIGH');
                final color = d == DifficultyMode.low
                    ? Colors.greenAccent
                    : (d == DifficultyMode.medium ? Colors.orangeAccent : Colors.redAccent);
                return GestureDetector(
                  onTap: () => setState(() => _difficulty = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? color : Colors.white24,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? color : Colors.white54,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Bet row
            Row(
              children: [
                _buildRoundBtn('−', () {
                  if (_betAmount > 10) setState(() => _betAmount -= 10);
                }),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${_betAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const Text('BET AMOUNT', style: TextStyle(color: Colors.white38, fontSize: 9)),
                    ],
                  ),
                ),
                _buildRoundBtn('+', () => setState(() => _betAmount += 10)),
              ],
            ),
            const SizedBox(height: 6),

            // Quick bet amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [50, 100, 200, 500, 1000].map((val) => GestureDetector(
                onTap: () => setState(() => _betAmount = val.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _betAmount == val ? NeonColors.primary.withValues(alpha: 0.15) : Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _betAmount == val ? NeonColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '\$$val',
                    style: TextStyle(
                      color: _betAmount == val ? NeonColors.primary : Colors.white54,
                      fontSize: 10,
                      fontWeight: _betAmount == val ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Main action button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone
                    ? NeonColors.grey
                    : (canCashOut
                        ? Colors.greenAccent.shade700
                        : (isPlaying ? Colors.amber.shade800 : NeonColors.primary)),
                foregroundColor: isDone ? Colors.white54 : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: isDone
                  ? _reset
                  : (isBetting
                      ? (_userBalance >= _betAmount ? _startGame : null)
                      : (canCashOut ? _cashOut : null)),
              child: Text(
                isDone
                    ? 'PLAY AGAIN'
                    : (isPlaying
                        ? (canCashOut
                            ? 'CASH OUT  •  \$${(_betAmount * _currentMultiplier).toStringAsFixed(2)}'
                            : '🐔  TAP A TILE!')
                        : 'START GAME'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isPlaying && canCashOut ? 14 : 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          color: Colors.white10,
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }
}
