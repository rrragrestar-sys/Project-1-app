import 'package:flutter/material.dart';

enum CarromCoinType { black, white, queen, striker }

class CarromCoin {
  final String id;
  Offset position;
  Offset velocity;
  final CarromCoinType type;
  final double radius;
  bool isPocketed;

  CarromCoin({
    required this.id,
    required this.position,
    this.velocity = Offset.zero,
    required this.type,
    required this.radius,
    this.isPocketed = false,
  });

  CarromCoin copyWith({
    Offset? position,
    Offset? velocity,
    bool? isPocketed,
  }) {
    return CarromCoin(
      id: id,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      type: type,
      radius: radius,
      isPocketed: isPocketed ?? this.isPocketed,
    );
  }
}

class CarromGameState {
  final List<CarromCoin> coins;
  final int currentPlayerIndex;
  final Map<int, int> scores;
  final bool isMoving;

  CarromGameState({
    required this.coins,
    required this.currentPlayerIndex,
    required this.scores,
    this.isMoving = false,
  });
}
