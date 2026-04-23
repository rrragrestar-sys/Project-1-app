import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CrashState { betting, flying, crashed }

/// The business logic for the Crash (Aviator) game.
/// Strictly decoupled from UI concerns.
class CrashEngine extends ChangeNotifier {
  CrashState _state = CrashState.betting;
  double _multiplier = 1.0;
  double _elapsedSeconds = 0.0;
  double _crashPoint = 0.0;
  
  Timer? _tickTimer;
  final math.Random _random = math.Random();

  // Constants for growth formula: multiplier = start * e^(rate * time)
  static const double _growthRate = 0.065;
  static const double _tickFrequencyMs = 50.0;

  CrashState get state => _state;
  double get multiplier => _multiplier;
  double get progress => math.min(_elapsedSeconds / 15.0, 1.0); // Normalized for painting

  /// Starts the flight simulation.
  void startFlight() {
    _state = CrashState.flying;
    _multiplier = 1.0;
    _elapsedSeconds = 0.0;
    
    // Provably fair-ish crash point calculation
    // Lower chance of high multipliers, high chance of early crash
    double r = _random.nextDouble();
    _crashPoint = 0.99 / (1.0 - r);
    if (_crashPoint < 1.0) _crashPoint = 1.0;

    _tickTimer = Timer.periodic(
      Duration(milliseconds: _tickFrequencyMs.toInt()),
      _onTick,
    );
    
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_state != CrashState.flying) {
      timer.cancel();
      return;
    }

    _elapsedSeconds += _tickFrequencyMs / 1000.0;
    
    // Exponential Growth Formula
    _multiplier = 1.0 * math.exp(_growthRate * _elapsedSeconds);

    if (_multiplier >= _crashPoint) {
      _triggerCrash();
    } else {
      notifyListeners();
    }
  }

  void _triggerCrash() {
    _state = CrashState.crashed;
    _tickTimer?.cancel();
    
    // STUB: Trigger heavy vibration on crash
    HapticFeedback.heavyImpact();
    
    notifyListeners();
  }

  void reset() {
    _state = CrashState.betting;
    _multiplier = 1.0;
    _elapsedSeconds = 0.0;
    _tickTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
