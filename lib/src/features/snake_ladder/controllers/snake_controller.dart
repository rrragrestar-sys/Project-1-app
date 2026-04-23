import 'dart:math';
import '../models/snake_models.dart';
import 'package:flutter/foundation.dart';

enum SnakeGameState { rolling, moving, finished }

class SnakeController extends ChangeNotifier {
  final List<SnakePlayer> players;
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool isRolling = false;
  SnakeGameState gameState = SnakeGameState.rolling;
  String? lastEventMessage;
  SnakePlayer? winner;

  final Random _random = Random();

  SnakeController({required this.players});

  SnakePlayer get currentPlayer => players[currentPlayerIndex];

  Future<void> rollDice() async {
    if (gameState != SnakeGameState.rolling || isRolling) return;
    isRolling = true;
    notifyListeners();

    // Animate dice: rapid random values then settle
    for (int i = 0; i < 12; i++) {
      await Future.delayed(Duration(milliseconds: 40 + i * 8));
      diceValue = _random.nextInt(6) + 1;
      notifyListeners();
    }

    isRolling = false;
    gameState = SnakeGameState.moving;
    notifyListeners();

    await _movePlayer();
  }

  Future<void> _movePlayer() async {
    final int startPos = currentPlayer.position;
    final int targetPos = startPos + diceValue;

    // Cannot overshoot 100 — must land exactly
    if (targetPos > 100) {
      lastEventMessage = 'NEED EXACT ROLL TO WIN!';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 700));
      lastEventMessage = null;
      _nextTurn();
      return;
    }

    // Step-by-step token movement
    for (int i = startPos + 1; i <= targetPos; i++) {
      currentPlayer.position = i;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 120));
    }

    // Check for snakes or ladders
    await _handleJumps();

    // Check win condition
    if (currentPlayer.position == 100) {
      gameState = SnakeGameState.finished;
      winner = currentPlayer;
      notifyListeners();
      return; // Do NOT call _nextTurn
    }

    _nextTurn();
  }

  Future<void> _handleJumps() async {
    final int pos = currentPlayer.position;

    if (SnakeLadderConfig.ladders.containsKey(pos)) {
      final int endPos = SnakeLadderConfig.ladders[pos]!;
      lastEventMessage = '🪜 CLIMBED A LADDER!';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));

      // Animate ladder climb step by step
      for (int i = pos + 1; i <= endPos; i++) {
        currentPlayer.position = i;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 60));
      }
      lastEventMessage = null;
      notifyListeners();
    } else if (SnakeLadderConfig.snakes.containsKey(pos)) {
      final int endPos = SnakeLadderConfig.snakes[pos]!;
      lastEventMessage = '🐍 BIT BY A SNAKE!';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));

      // Animate snake slide step by step
      for (int i = pos - 1; i >= endPos; i--) {
        currentPlayer.position = i;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 60));
      }
      lastEventMessage = null;
      notifyListeners();
    }
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    gameState = SnakeGameState.rolling;
    notifyListeners();

    if (currentPlayer.isBot) {
      Future.delayed(const Duration(milliseconds: 800), () => rollDice());
    }
  }
}
