import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/user_session.dart';

enum FishSize { small, medium, large, rare }

class Fish {
  final String id;
  final FishSize size;
  double x; // 0.0–1.0
  double y; // 0.0–1.0
  double speed;
  bool facingRight;
  bool caught;

  Fish({
    required this.id,
    required this.size,
    required this.x,
    required this.y,
    required this.speed,
    required this.facingRight,
    this.caught = false,
  });

  int get points => switch (size) {
        FishSize.small => 10,
        FishSize.medium => 25,
        FishSize.large => 50,
        FishSize.rare => 200,
      };

  String get emoji => switch (size) {
        FishSize.small => '🐟',
        FishSize.medium => '🐠',
        FishSize.large => '🐡',
        FishSize.rare => '🦈',
      };

  double get radius => switch (size) {
        FishSize.small => 0.05,
        FishSize.medium => 0.07,
        FishSize.large => 0.09,
        FishSize.rare => 0.12,
      };
}

enum FishingState { betting, playing, finished }

class FishingController extends ChangeNotifier {
  static const int gameDurationSecs = 60;
  static const int maxFishOnScreen = 6;

  FishingState state = FishingState.betting;
  int secondsLeft = gameDurationSecs;
  int totalScore = 0;
  int fishCaught = 0;
  double betAmount = 100.0;
  List<Fish> fish = [];
  Offset? aimPosition;

  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _moveTicker;
  final Random _random = Random();
  int _fishIdCounter = 0;

  void setBet(double amount) {
    if (state != FishingState.betting) return;
    betAmount = amount;
    notifyListeners();
  }

  bool startGame() {
    if (state != FishingState.betting) return false;
    if (!UserSession().withdrawFiat(betAmount)) return false;

    state = FishingState.playing;
    secondsLeft = gameDurationSecs;
    totalScore = 0;
    fishCaught = 0;
    fish = [];
    _spawnFish(3); // Initial fish
    notifyListeners();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsLeft--;
      notifyListeners();
      if (secondsLeft <= 0) {
        t.cancel();
        _endGame();
      }
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (fish.where((f) => !f.caught).length < maxFishOnScreen) {
        _spawnFish(1);
        notifyListeners();
      }
    });

    _moveTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _moveFish();
      notifyListeners();
    });

    return true;
  }

  bool tapAt(Offset normalizedPos) {
    if (state != FishingState.playing) return false;

    for (final f in fish) {
      if (f.caught) continue;
      final distance = (Offset(f.x, f.y) - normalizedPos).distance;
      if (distance < f.radius + 0.06) {
        f.caught = true;
        totalScore += f.points;
        fishCaught++;
        notifyListeners();
        // Remove after short delay
        Future.delayed(const Duration(milliseconds: 700), () {
          fish.remove(f);
          notifyListeners();
        });
        return true;
      }
    }
    return false;
  }

  void _spawnFish(int count) {
    for (int i = 0; i < count; i++) {
      final r = _random.nextDouble();
      FishSize size;
      if (r < 0.5) {
        size = FishSize.small;
      } else if (r < 0.78) {
        size = FishSize.medium;
      } else if (r < 0.95) {
        size = FishSize.large;
      } else {
        size = FishSize.rare;
      }

      final bool fromLeft = _random.nextBool();
      fish.add(Fish(
        id: 'fish_${_fishIdCounter++}',
        size: size,
        x: fromLeft ? 0.0 : 1.0,
        y: 0.2 + _random.nextDouble() * 0.65,
        speed: 0.003 + _random.nextDouble() * 0.006,
        facingRight: fromLeft,
      ));
    }
  }

  void _moveFish() {
    final toRemove = <Fish>[];
    for (final f in fish) {
      if (f.caught) continue;
      if (f.facingRight) {
        f.x += f.speed;
        if (f.x > 1.1) toRemove.add(f);
      } else {
        f.x -= f.speed;
        if (f.x < -0.1) toRemove.add(f);
      }
    }
    fish.removeWhere(toRemove.contains);
  }

  void _endGame() {
    _spawnTimer?.cancel();
    _moveTicker?.cancel();
    state = FishingState.finished;

    // Payout based on score
    final double multiplier = totalScore > 500
        ? 5.0
        : totalScore > 200
            ? 3.0
            : totalScore > 100
                ? 2.0
                : totalScore > 50
                    ? 1.5
                    : 0.0;

    if (multiplier > 0) {
      UserSession().depositFiat(betAmount * multiplier);
    }

    notifyListeners();
  }

  void reset() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTicker?.cancel();
    state = FishingState.betting;
    fish = [];
    totalScore = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTicker?.cancel();
    super.dispose();
  }
}
