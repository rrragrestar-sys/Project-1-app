import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../../common/logic/secure_game_controller.dart';

enum AviatorState { betting, waiting, flying, crashed }

class AviatorController extends SecureGameController {
  AviatorState _state = AviatorState.betting;
  double _multiplier = 1.0;
  double _elapsedSeconds = 0.0;
  double _crashPoint = 0.0;
  
  Timer? _tickTimer;
  final math.Random _random = math.Random();

  static const double _growthRate = 0.065;
  static const double _tickFrequencyMs = 50.0;

  AviatorState get state => _state;
  double get multiplier => _multiplier;
  double get progress => math.min(_elapsedSeconds / 15.0, 1.0);

  @override
  Future<GameOutcome> requestOutcomeFromServer(double betAmount) async {
    // Server returns the crash point
    await Future.delayed(const Duration(milliseconds: 500));
    double r = _random.nextDouble();
    double crashPoint = 0.99 / (1.0 - r);
    if (crashPoint < 1.0) crashPoint = 1.0;
    if (crashPoint > 1000) crashPoint = 1000.0;

    return GameOutcome(
      isWin: false, // Win is determined by cashout, not by server result alone
      payout: 0,
      state: crashPoint,
    );
  }

  @override
  Future<void> animateOutcome(GameOutcome outcome) async {
    _crashPoint = outcome.state as double;
    _state = AviatorState.flying;
    _multiplier = 1.0;
    _elapsedSeconds = 0.0;
    
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      _onTick,
    );
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_state != AviatorState.flying) {
      timer.cancel();
      return;
    }

    _elapsedSeconds += _tickFrequencyMs / 1000.0;
    _multiplier = 1.0 * math.exp(_growthRate * _elapsedSeconds);

    if (_multiplier >= _crashPoint) {
      _triggerCrash();
    } else {
      notifyListeners();
    }
  }

  void _triggerCrash() {
    _state = AviatorState.crashed;
    _tickTimer?.cancel();
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  Future<void> startBetting() async {
    _state = AviatorState.betting;
    notifyListeners();
  }

  Future<void> beginFlight() async {
    _state = AviatorState.waiting;
    notifyListeners();
    await play(0); // We call play but handle winnings via manual cashout
  }

  void cashout(double amount) {
    // In a real app, this sends a cashout request to the server
    // For now, we update local balance if flight is still active
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
