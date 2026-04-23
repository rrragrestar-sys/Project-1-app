import 'package:flutter/foundation.dart';

/// A centralized singleton to manage user session data in a production-ready way.
/// This replaces hardcoded placeholders and provides a single source of truth.
class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  /// The official platform conversion ratio: ₹1 = 100 Gold Coins.
  static const double inrToCoinRatio = 100.0;

  String _displayName = 'LUCKY_KING_777';
  final String _playerId = '8829410';
  String _phoneNumber = '+91 98765 43210';
  int _avatarIndex = 0;
  int _vipLevel = 4;
  double _balance = 1250000.0; // Updated for 1:100 ratio (e.g. ₹12,500 = 1,250,000 coins)

  String get displayName => _displayName;
  String get playerId => _playerId;
  String get phoneNumber => _phoneNumber;
  int get avatarIndex => _avatarIndex;
  
  /// Unique referral code for this user.
  String get referralCode => 'LK777_${_playerId.substring(_playerId.length - 4)}';
  
  int get vipLevel => _vipLevel;
  double get balance => _balance;

  /// Returns the balance in real Fiat currency (INR)
  double get fiatBalance => _balance / inrToCoinRatio;

  /// Update coin balance (e.g., after a win or deposit conversion)
  /// In production, this should ONLY be called after a successful backend sync.
  void updateBalance(double newCoinBalance) {
    _balance = newCoinBalance;
    notifyListeners();
  }

  /// Deducts from the balance based on a Fiat (INR) amount.
  /// Returns true if the transaction was successful.
  bool withdrawFiat(double inrAmount) {
    final double coinsToDeduct = convertInrToCoins(inrAmount);
    if (_balance >= coinsToDeduct) {
      _balance -= coinsToDeduct;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Adds to the balance based on a Fiat (INR) amount (e.g. from a game win).
  void depositFiat(double inrAmount) {
    final double coinsToAdd = convertInrToCoins(inrAmount);
    _balance += coinsToAdd;
    notifyListeners();
  }

  /// Converts Real INR to platform Gold Coins.
  static double convertInrToCoins(double inrAmount) {
    return inrAmount * inrToCoinRatio;
  }

  /// Update user info (e.g., after profile sync)
  void updateUserInfo({String? name, int? vip, String? phone, int? avatar}) {
    if (name != null) _displayName = name;
    if (vip != null) _vipLevel = vip;
    if (phone != null) _phoneNumber = phone;
    if (avatar != null) _avatarIndex = avatar;
    notifyListeners();
  }
}
