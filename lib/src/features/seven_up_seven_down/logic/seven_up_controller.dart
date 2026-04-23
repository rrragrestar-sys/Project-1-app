import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/user_session.dart';

enum BetOption { down, exact, up }

class RollResult {
  final int die1;
  final int die2;
  final int sum;
  final bool isWin;
  final double payout;
  final BetOption bet;

  const RollResult({
    required this.die1,
    required this.die2,
    required this.sum,
    required this.isWin,
    required this.payout,
    required this.bet,
  });
}

class SevenUpController extends ChangeNotifier {
  int die1 = 3;
  int die2 = 4;
  bool isRolling = false;
  BetOption? selectedBet;
  RollResult? lastResult;
  final List<RollResult> history = [];

  final Random _random = Random();

  void selectBet(BetOption option) {
    if (isRolling) return;
    selectedBet = option;
    lastResult = null; // Clear previous result when a new bet is selected
    notifyListeners();
  }

  Future<void> play(double betAmount) async {
    if (isRolling || selectedBet == null) return;

    // Balance guard
    if (!UserSession().withdrawFiat(betAmount)) {
      return;
    }

    isRolling = true;
    lastResult = null;
    notifyListeners();

    // ── Determine outcome server-side (simulated) ──
    await Future.delayed(const Duration(milliseconds: 300));
    final int d1 = _random.nextInt(6) + 1;
    final int d2 = _random.nextInt(6) + 1;
    final int sum = d1 + d2;

    bool isWin = false;
    double multiplier = 0;

    switch (selectedBet!) {
      case BetOption.down:
        isWin = sum < 7;
        multiplier = 2.0;
      case BetOption.exact:
        isWin = sum == 7;
        multiplier = 5.0;
      case BetOption.up:
        isWin = sum > 7;
        multiplier = 2.0;
    }

    final double payout = isWin ? betAmount * multiplier : 0;

    // ── Rolling animation: random flicker then settle ──
    for (int i = 0; i < 18; i++) {
      await Future.delayed(Duration(milliseconds: 45 + (i * 6)));
      die1 = _random.nextInt(6) + 1;
      die2 = _random.nextInt(6) + 1;
      notifyListeners();
    }

    // ── Set final result ──
    die1 = d1;
    die2 = d2;
    isRolling = false;

    final RollResult result = RollResult(
      die1: d1,
      die2: d2,
      sum: sum,
      isWin: isWin,
      payout: payout,
      bet: selectedBet!,
    );

    lastResult = result;
    history.insert(0, result); // newest first
    if (history.length > 20) history.removeLast();

    // Credit payout if win
    if (isWin && payout > 0) {
      UserSession().depositFiat(payout);
    }

    notifyListeners();
  }
}
