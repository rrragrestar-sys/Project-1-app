import 'dart:math';
import '../models/ludo_models.dart';
import 'package:flutter/foundation.dart';

class LudoController extends ChangeNotifier {
  final List<LudoPlayer> players;
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool isRolling = false;
  LudoGameState gameState = LudoGameState.rolling;
  List<LudoToken> movableTokens = [];
  LudoPlayer? winner;

  final Random _random = Random();

  LudoController({required this.players});

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  /// Simulates a dice roll (1–6). No bet deduction for board games.
  Future<void> rollDice() async {
    if (gameState != LudoGameState.rolling || isRolling) return;
    isRolling = true;
    notifyListeners();

    // Animate: rapid random values then settle
    for (int i = 0; i < 12; i++) {
      await Future.delayed(Duration(milliseconds: 40 + i * 8));
      diceValue = _random.nextInt(6) + 1;
      notifyListeners();
    }

    isRolling = false;
    _calculateMovableTokens();

    if (movableTokens.isEmpty) {
      // No valid move: pass turn (unless rolled 6)
      await Future.delayed(const Duration(milliseconds: 600));
      _nextTurn();
    } else {
      gameState = LudoGameState.moving;
      if (currentPlayer.isBot) {
        await Future.delayed(const Duration(milliseconds: 800));
        _makeBotMove();
      }
    }
    notifyListeners();
  }

  void _calculateMovableTokens() {
    movableTokens = [];
    final player = currentPlayer;

    for (var token in player.tokens) {
      if (token.state == TokenState.inBase) {
        // Need a 6 to leave base
        if (diceValue == 6) {
          movableTokens.add(token);
        }
      } else if (token.state == TokenState.onPath || token.state == TokenState.homePath) {
        // Can move if won't overshoot home (position 57 = home)
        if (token.position + diceValue <= 57) {
          movableTokens.add(token);
        }
      }
      // TokenState.home tokens are already done — skip
    }
  }

  Future<void> moveToken(LudoToken token) async {
    if (gameState != LudoGameState.moving) return;
    if (!movableTokens.contains(token)) return;

    final steps = diceValue;

    if (token.state == TokenState.inBase) {
      // Enter the board
      token.state = TokenState.onPath;
      token.position = 0;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 150));
    } else {
      // Step-by-step movement with animation
      for (int i = 0; i < steps; i++) {
        token.position++;

        if (token.position >= 52 && token.position < 57) {
          token.state = TokenState.homePath;
        } else if (token.position == 57) {
          token.state = TokenState.home;
        }

        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 140));

        if (token.state == TokenState.home) break;
      }
    }

    // Handle collisions only on main path
    if (token.state == TokenState.onPath) {
      _checkCollisions(token);
    }

    // Check if this player has won
    if (_checkWinner()) {
      gameState = LudoGameState.finished;
      winner = currentPlayer;
      notifyListeners();
      return; // Do NOT proceed to next turn
    }

    // Rolling 6 grants a bonus turn to the same player
    gameState = LudoGameState.rolling;
    if (diceValue != 6) {
      _nextTurn();
    } else {
      // Bonus turn — if bot, auto-roll
      if (currentPlayer.isBot) {
        await Future.delayed(const Duration(milliseconds: 800));
        rollDice();
      }
    }
    notifyListeners();
  }

  /// Returns true if the current player has all 4 tokens home.
  bool _checkWinner() {
    final homeCount = currentPlayer.tokens.where((t) => t.state == TokenState.home).length;
    return homeCount == 4;
  }

  void _makeBotMove() {
    if (movableTokens.isEmpty) return;

    // Priority 1: Move a token that's already on the path (advance furthest one)
    final onPathTokens = movableTokens.where(
      (t) => t.state == TokenState.onPath || t.state == TokenState.homePath,
    ).toList();

    if (onPathTokens.isNotEmpty) {
      // Pick the one closest to home
      onPathTokens.sort((a, b) => b.position.compareTo(a.position));
      moveToken(onPathTokens.first);
      return;
    }

    // Priority 2: Enter base if rolled 6
    final baseTokens = movableTokens.where((t) => t.state == TokenState.inBase).toList();
    if (baseTokens.isNotEmpty) {
      moveToken(baseTokens.first);
      return;
    }
  }

  void _checkCollisions(LudoToken movedToken) {
    // Standard safe squares (relative positions on the main 52-step path)
    const List<int> safeSquares = [0, 8, 13, 21, 26, 34, 39, 47];
    final movedGlobal = _toGlobalPosition(movedToken.color.index, movedToken.position);
    if (safeSquares.contains(movedToken.position % 13)) return;

    for (int i = 0; i < players.length; i++) {
      if (i == currentPlayerIndex) continue;
      for (var other in players[i].tokens) {
        if (other.state != TokenState.onPath) continue;
        final otherGlobal = _toGlobalPosition(players[i].ludoColor.index, other.position);
        if (movedGlobal == otherGlobal) {
          // Send opponent token back to base
          other.state = TokenState.inBase;
          other.position = -1;
          notifyListeners();
        }
      }
    }
  }

  /// Converts a player-relative path position (0–51) to a global board square (0–51).
  int _toGlobalPosition(int colorIndex, int relPos) {
    if (relPos >= 52) return -1;
    // Each color starts 13 squares apart on the 52-square main loop
    return (colorIndex * 13 + relPos) % 52;
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    gameState = LudoGameState.rolling;
    movableTokens = [];
    notifyListeners();

    if (currentPlayer.isBot) {
      Future.delayed(const Duration(milliseconds: 800), () => rollDice());
    }
  }
}
