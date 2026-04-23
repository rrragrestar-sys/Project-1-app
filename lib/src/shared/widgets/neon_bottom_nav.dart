import 'package:flutter/material.dart';
import '../../core/constants.dart';

class NeonBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const NeonBottomNav({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: NeonColors.surface,
        border: Border(top: BorderSide(color: NeonColors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(Icons.home_outlined, 'LOBBY', selectedIndex == 0, 0),
          _buildItem(Icons.account_balance_wallet_outlined, 'WALLET', selectedIndex == 1, 1),
          _buildItem(Icons.card_giftcard, 'OFFERS', selectedIndex == 2, 2),
          _buildItem(Icons.person_outline, 'PROFILE', selectedIndex == 3, 3),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, bool active, int index) {
    return GestureDetector(
      onTap: () => onTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? NeonColors.primary : NeonColors.textSub, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? NeonColors.primary : NeonColors.textSub,
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
