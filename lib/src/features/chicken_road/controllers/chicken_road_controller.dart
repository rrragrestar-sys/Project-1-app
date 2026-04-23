import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/user_session.dart';

enum ChickenRoadState { idle, hopping, cashOut, crashed, won }

class ChickenRoadController extends ChangeNotifier {
  static const List<double> laneMultipliers = [
    1.2, 1.5, 2.0, 3.0, 5.0, 8.0, 12.0, 20.0, 35.0, 50.0,
  ];

  /// bombChance[lane] = probability (0–1) the tile is a bomb
  static const List<double> bombChance = [
    0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55,
  ];

  ChickenRoadState state = ChickenRoadState.idle;
  int currentLane = -1; // -1 = starting zone
  double betAmount = 100.0;
  List<bool?> laneResults = List.filled(10, null); // null=unknown, true=safe, false=bomb
  double get currentMultiplier =>
      currentLane >= 0 ? laneMultipliers[currentLane] : 1.0;
  double get potentialPayout => betAmount * currentMultiplier;

  final Random _random = Random();

  void setBet(double amount) {
    if (state != ChickenRoadState.idle) return;
    betAmount = amount;
    notifyListeners();
  }

  bool startGame() {
    if (state != ChickenRoadState.idle) return false;
    if (!UserSession().withdrawFiat(betAmount)) return false;

    // Reset lane results
    laneResults = List.filled(10, null);
    currentLane = -1;
    state = ChickenRoadState.hopping;
    notifyListeners();
    return true;
  }

  Future<void> hop() async {
    if (state != ChickenRoadState.hopping) return;
    final int nextLane = currentLane + 1;
    if (nextLane >= 10) {
      // Reached the end — auto win
      await cashOut();
      return;
    }

    state = ChickenRoadState.hopping;
    await Future.delayed(const Duration(milliseconds: 250));

    // Determine if bomb using server-simulated RNG
    final bool isBomb = _random.nextDouble() < bombChance[nextLane];
    laneResults[nextLane] = !isBomb;
    currentLane = nextLane;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    if (isBomb) {
      state = ChickenRoadState.crashed;
      notifyListeners();
      // Auto reset after delay
      await Future.delayed(const Duration(seconds: 3));
      _reset();
    } else if (nextLane == 9) {
      // Completed all lanes
      state = ChickenRoadState.won;
      UserSession().depositFiat(betAmount * laneMultipliers[9]);
      notifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      _reset();
    }
  }

  Future<void> cashOut() async {
    if (state != ChickenRoadState.hopping || currentLane < 0) return;
    state = ChickenRoadState.cashOut;
    final double payout = betAmount * laneMultipliers[currentLane];
    UserSession().depositFiat(payout);
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _reset();
  }

  void _reset() {
    currentLane = -1;
    laneResults = List.filled(10, null);
    state = ChickenRoadState.idle;
    notifyListeners();
  }
}
