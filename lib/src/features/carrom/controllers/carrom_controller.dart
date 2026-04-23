import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/carrom_models.dart';

class CarromController extends ChangeNotifier {
  late List<CarromCoin> coins;
  late Ticker _ticker;

  int currentPlayerIndex = 0;
  bool isMoving = false;
  bool isGameOver = false;
  double strikerX = 0.5;

  /// Scores: playerIndex → points
  Map<int, int> playerScores = {0: 0, 1: 0};
  final List<CarromCoin> _pocketedThisTurn = [];

  // ── Physics constants ──────────────────────────────────────────────────────
  static const double friction = 0.987;
  static const double wallBounciness = 0.72;
  static const double collisionDamping = 0.92;
  static const double pocketRadius = 0.058;
  static const double boardSize = 1.0;

  // Guard so _handleTurnEnd only fires once per shot
  bool _turnEndHandled = false;

  CarromController() {
    _initGame();
    _ticker = Ticker(_updatePhysics);
  }

  /// Standard carrom setup: 9 white + 9 black + 1 queen + 1 striker = 20 pieces.
  void _initGame() {
    coins = [];

    // ── Queen in the center ──
    coins.add(CarromCoin(
      id: 'queen',
      position: const Offset(0.5, 0.5),
      type: CarromCoinType.queen,
      radius: 0.024,
    ));

    // ── Inner ring: 6 coins alternating white/black ──
    const double innerR = 0.055;
    for (int i = 0; i < 6; i++) {
      final double angle = i * (pi / 3);
      final Offset pos = Offset(
        0.5 + innerR * cos(angle),
        0.5 + innerR * sin(angle),
      );
      coins.add(CarromCoin(
        id: i.isEven ? 'white_inner_$i' : 'black_inner_$i',
        position: pos,
        type: i.isEven ? CarromCoinType.white : CarromCoinType.black,
        radius: 0.024,
      ));
    }

    // ── Outer ring: 12 coins alternating white/black ──
    const double outerR = 0.105;
    for (int i = 0; i < 12; i++) {
      final double angle = i * (pi / 6);
      final Offset pos = Offset(
        0.5 + outerR * cos(angle),
        0.5 + outerR * sin(angle),
      );
      final bool isWhite = i.isEven;
      coins.add(CarromCoin(
        id: isWhite ? 'white_outer_$i' : 'black_outer_$i',
        position: pos,
        type: isWhite ? CarromCoinType.white : CarromCoinType.black,
        radius: 0.024,
      ));
    }

    // ── Striker ──
    coins.add(CarromCoin(
      id: 'striker',
      position: Offset(0.5, 0.82),
      type: CarromCoinType.striker,
      radius: 0.033,
    ));
  }

  CarromCoin get _striker => coins.firstWhere((c) => c.type == CarromCoinType.striker);

  // ── Public API ─────────────────────────────────────────────────────────────

  void setStrikerPosition(double x) {
    if (isMoving) return;
    strikerX = x.clamp(0.15, 0.85);
    _striker.position = Offset(strikerX, currentPlayerIndex == 0 ? 0.82 : 0.18);
    notifyListeners();
  }

  void shoot(Offset direction, double power) {
    if (isMoving || isGameOver) return;

    _striker.velocity = direction * (power * 0.14).clamp(0.002, 0.014);
    _turnEndHandled = false;
    isMoving = true;
    _ticker.start();
    notifyListeners();
  }

  // ── Physics loop ───────────────────────────────────────────────────────────

  void _updatePhysics(Duration elapsed) {
    bool anyMoving = false;

    for (var coin in coins) {
      if (coin.isPocketed) continue;
      coin.position += coin.velocity;
      coin.velocity *= friction;

      if (coin.velocity.distance < 0.0008) {
        coin.velocity = Offset.zero;
      } else {
        anyMoving = true;
      }

      _checkWallCollision(coin);
      _checkPocket(coin);
    }

    // Coin–coin collisions
    for (int i = 0; i < coins.length; i++) {
      for (int j = i + 1; j < coins.length; j++) {
        if (coins[i].isPocketed || coins[j].isPocketed) continue;
        _checkCoinCollision(coins[i], coins[j]);
      }
    }

    if (!anyMoving && !_turnEndHandled) {
      _turnEndHandled = true;
      _handleTurnEnd();
    }

    notifyListeners();
  }

  void _handleTurnEnd() {
    _ticker.stop();
    isMoving = false;

    final CarromCoinType myType =
        currentPlayerIndex == 0 ? CarromCoinType.white : CarromCoinType.black;

    // Check if player pocketed at least one of their own coins this turn
    final bool scoredThisTurn =
        _pocketedThisTurn.any((c) => c.type == myType || c.type == CarromCoinType.queen);
    _pocketedThisTurn.clear();

    // Reset striker to the correct player's baseline
    _resetStriker();

    // ── Win condition: all 9 of your coins + queen pocketed ──
    final int whitePocketed = coins.where((c) => c.type == CarromCoinType.white && c.isPocketed).length;
    final int blackPocketed = coins.where((c) => c.type == CarromCoinType.black && c.isPocketed).length;
    final bool queenPocketed = coins.any((c) => c.type == CarromCoinType.queen && c.isPocketed);

    if ((whitePocketed >= 9 && queenPocketed) || (blackPocketed >= 9 && queenPocketed)) {
      isGameOver = true;
      notifyListeners();
      return;
    }

    // Switch turn if player didn't score
    if (!scoredThisTurn) {
      currentPlayerIndex = 1 - currentPlayerIndex;
    }

    notifyListeners();

    if (currentPlayerIndex == 1) {
      Future.delayed(const Duration(milliseconds: 900), _triggerBotTurn);
    }
  }

  void _resetStriker() {
    final double baseline = currentPlayerIndex == 0 ? 0.82 : 0.18;
    _striker.position = Offset(strikerX, baseline);
    _striker.velocity = Offset.zero;
    _striker.isPocketed = false;
  }

  void _triggerBotTurn() {
    if (isMoving || currentPlayerIndex != 1 || isGameOver) return;

    // Bot targets its own black coins only
    final targets = coins
        .where((c) => c.type == CarromCoinType.black && !c.isPocketed)
        .toList();

    // If no black coins left, target white (desperate)
    final List<CarromCoin> aimAt = targets.isNotEmpty
        ? targets
        : coins.where((c) => c.type == CarromCoinType.white && !c.isPocketed).toList();

    if (aimAt.isEmpty) return;

    final CarromCoin target = aimAt[Random().nextInt(aimAt.length)];
    // Position striker toward the target with slight randomness
    setStrikerPosition(
      target.position.dx + (Random().nextDouble() - 0.5) * 0.08,
    );

    final Offset strikerPos = _striker.position;
    final Offset dir = target.position - strikerPos;
    final Offset normalizedDir = dir / dir.distance;
    final double power = 0.45 + Random().nextDouble() * 0.35;

    shoot(normalizedDir, power);
  }

  // ── Collision helpers ──────────────────────────────────────────────────────

  void _checkWallCollision(CarromCoin coin) {
    if (coin.position.dx < coin.radius) {
      coin.position = Offset(coin.radius, coin.position.dy);
      coin.velocity = Offset(-coin.velocity.dx * wallBounciness, coin.velocity.dy);
    } else if (coin.position.dx > boardSize - coin.radius) {
      coin.position = Offset(boardSize - coin.radius, coin.position.dy);
      coin.velocity = Offset(-coin.velocity.dx * wallBounciness, coin.velocity.dy);
    }
    if (coin.position.dy < coin.radius) {
      coin.position = Offset(coin.position.dx, coin.radius);
      coin.velocity = Offset(coin.velocity.dx, -coin.velocity.dy * wallBounciness);
    } else if (coin.position.dy > boardSize - coin.radius) {
      coin.position = Offset(coin.position.dx, boardSize - coin.radius);
      coin.velocity = Offset(coin.velocity.dx, -coin.velocity.dy * wallBounciness);
    }
  }

  void _checkCoinCollision(CarromCoin a, CarromCoin b) {
    final Offset delta = a.position - b.position;
    final double distance = delta.distance;
    final double minDist = a.radius + b.radius;

    if (distance < minDist && distance > 0) {
      final double overlap = minDist - distance;
      final Offset move = delta / distance * overlap * 0.5;
      a.position += move;
      b.position -= move;

      final Offset normal = delta / distance;
      final Offset relVel = a.velocity - b.velocity;
      final double dot = relVel.dx * normal.dx + relVel.dy * normal.dy;
      if (dot > 0) return;

      final double impulse = -(1 + collisionDamping) * dot * 0.5;
      final Offset impulseVec = normal * impulse;
      a.velocity += impulseVec;
      b.velocity -= impulseVec;
    }
  }

  void _checkPocket(CarromCoin coin) {
    final List<Offset> corners = [
      Offset.zero,
      Offset(boardSize, 0),
      Offset(0, boardSize),
      Offset(boardSize, boardSize),
    ];

    for (final Offset corner in corners) {
      if ((coin.position - corner).distance < pocketRadius) {
        coin.isPocketed = true;
        coin.velocity = Offset.zero;

        if (coin.type != CarromCoinType.striker) {
          final int pts = switch (coin.type) {
            CarromCoinType.white => 20,
            CarromCoinType.black => 10,
            CarromCoinType.queen => 50,
            _ => 0,
          };
          playerScores[currentPlayerIndex] =
              (playerScores[currentPlayerIndex] ?? 0) + pts;
          _pocketedThisTurn.add(coin);
        }
        break;
      }
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
