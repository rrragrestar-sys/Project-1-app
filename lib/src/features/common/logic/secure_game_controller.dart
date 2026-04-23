import 'package:flutter/foundation.dart';
import '../../../core/user_session.dart';
import '../../../core/services/wallet_service.dart';

/// The result of a game outcome determined by the backend.
class GameOutcome {
  final bool isWin;
  final double payout;
  final dynamic state; // Custom state for specific games (e.g., slot symbols, crash multiplier)

  GameOutcome({
    required this.isWin,
    required this.payout,
    this.state,
  });
}

/// A base class for all game controllers to ensure security.
/// THE FRONTEND NEVER CALCULATES OUTCOMES.
abstract class SecureGameController extends ChangeNotifier {
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> play(double betAmount) async {
    if (_isProcessing) {
      return;
    }

    // 1. Deduct bet securely using Fiat logic
    if (!UserSession().withdrawFiat(betAmount)) {
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // 2. Request outcome from Node.js Backend
      final outcome = await requestOutcomeFromServer(betAmount);

      // 3. Animate outcome
      await animateOutcome(outcome);

      // 4. Update balance with payout if win
      if (outcome.isWin && outcome.payout > 0) {
        UserSession().depositFiat(outcome.payout);
      }

      // 5. Final balance sync from server source-of-truth
      await WalletService().syncBalance();
      
    } catch (e) {
      debugPrint("Game Error: $e");
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// MUST be implemented by specific games to call their respective backend endpoints.
  /// e.g., POST /api/v1/games/slots/play
  @protected
  Future<GameOutcome> requestOutcomeFromServer(double betAmount);

  /// MUST be implemented to trigger the Flutter animations (Reel spin, Plane crash, etc.)
  @protected
  Future<void> animateOutcome(GameOutcome outcome);
}
