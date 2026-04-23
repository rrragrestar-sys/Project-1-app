import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/user_session.dart';

enum PredictionColor { red, green, violet }

enum PredictionState { betting, spinning, result }

class ColorResult {
  final PredictionColor color;
  final bool isWin;
  final double payout;

  const ColorResult({required this.color, required this.isWin, required this.payout});
}

class ColorPredictionController extends ChangeNotifier {
  static const int roundDurationSecs = 60;
  static const Map<PredictionColor, double> multipliers = {
    PredictionColor.red: 2.0,
    PredictionColor.green: 2.0,
    PredictionColor.violet: 4.5,
  };

  PredictionState state = PredictionState.betting;
  int secondsLeft = roundDurationSecs;
  PredictionColor? selectedColor;
  double betAmount = 100.0;
  ColorResult? lastResult;
  final List<PredictionColor> history = [];

  Timer? _countdownTimer;
  final Random _random = Random();

  ColorPredictionController() {
    _startRound();
  }

  void _startRound() {
    state = PredictionState.betting;
    secondsLeft = roundDurationSecs;
    selectedColor = null;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsLeft--;
      notifyListeners();
      if (secondsLeft <= 0) {
        t.cancel();
        _spin();
      }
    });
  }

  void selectColor(PredictionColor color) {
    if (state != PredictionState.betting) return;
    selectedColor = color;
    notifyListeners();
  }

  void setBet(double amount) {
    if (state != PredictionState.betting) return;
    betAmount = amount;
    notifyListeners();
  }

  bool placeBet() {
    if (state != PredictionState.betting || selectedColor == null) return false;
    if (!UserSession().withdrawFiat(betAmount)) return false;
    return true;
  }

  Future<void> _spin() async {
    state = PredictionState.spinning;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 2500));

    // Determine outcome
    final PredictionColor outcome = _roll();
    final bool isWin = selectedColor == outcome;
    final double payout = isWin ? betAmount * (multipliers[selectedColor!] ?? 2.0) : 0;

    if (selectedColor != null) {
      if (isWin && payout > 0) {
        UserSession().depositFiat(payout);
      }
    }

    lastResult = ColorResult(color: outcome, isWin: isWin, payout: payout);
    history.insert(0, outcome);
    if (history.length > 15) history.removeLast();

    state = PredictionState.result;
    notifyListeners();

    // Start next round after 4 seconds
    await Future.delayed(const Duration(seconds: 4));
    _startRound();
  }

  PredictionColor _roll() {
    // Red: 40%, Green: 40%, Violet: 20%
    final r = _random.nextDouble();
    if (r < 0.40) return PredictionColor.red;
    if (r < 0.80) return PredictionColor.green;
    return PredictionColor.violet;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
