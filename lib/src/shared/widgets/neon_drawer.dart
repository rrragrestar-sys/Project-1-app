import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/user_session.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/wallet/pages/wallet_page.dart';
import '../../features/referral/pages/invite_page.dart';

class NeonDrawer extends StatelessWidget {
  const NeonDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: NeonColors.background,
      child: Column(
        children: [
          // Drawer Header with User Profile
          _buildHeader(),
          
          const SizedBox(height: 10),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(Icons.person_outline, 'My Profile', () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                }),
                _buildNavItem(Icons.account_balance_wallet_outlined, 'Deposit', () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(builder: (context) => const WalletPage()),
                  );
                }),
                _buildNavItem(Icons.history, 'Transaction History', () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(builder: (context) => const WalletPage()),
                  );
                }),
                _buildNavItem(Icons.group_add_outlined, 'Refer & Earn', () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(builder: (context) => const InvitePage()),
                  );
                }, isHighlighted: true),
                
                const Divider(color: Colors.white12, height: 32),
                
                _buildNavItem(
                  Icons.headset_mic_outlined, 
                  'Support', 
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connecting to Support Chat...'),
                        backgroundColor: NeonColors.primary,
                      ),
                    );
                  },
                  isHighlighted: true,
                ),
              ],
            ),
          ),
          
          // Logout Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        border: Border(
          bottom: BorderSide(color: NeonColors.primary.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: ListenableBuilder(
        listenable: UserSession(),
        builder: (context, _) {
          final session = UserSession();
          // Map index to icon/color (matching ProfilePage)
          final List<Map<String, dynamic>> avatarOptions = [
            {'icon': Icons.face_rounded, 'color': Colors.blueAccent},
            {'icon': Icons.sports_esports_rounded, 'color': Colors.purpleAccent},
            {'icon': Icons.workspace_premium_rounded, 'color': Colors.amberAccent},
            {'icon': Icons.rocket_launch_rounded, 'color': Colors.orangeAccent},
            {'icon': Icons.star_rounded, 'color': Colors.pinkAccent},
            {'icon': Icons.bolt_rounded, 'color': Colors.cyanAccent},
          ];
          final currentAvatar = avatarOptions[session.avatarIndex];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: currentAvatar['color'] as Color, width: 2),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: NeonColors.background,
                  child: Icon(
                    currentAvatar['icon'] as IconData, 
                    size: 40, 
                    color: currentAvatar['color'] as Color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                session.displayName,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: NeonColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'VIP LEVEL ${session.vipLevel}',
                      style: GoogleFonts.inter(
                        color: NeonColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${session.playerId}',
                    style: GoogleFonts.inter(
                      color: NeonColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, VoidCallback onTap, {bool isHighlighted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? NeonColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isHighlighted ? NeonColors.primary : NeonColors.textSub,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isHighlighted ? NeonColors.primary : Colors.white70,
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logging out safely...'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            const SizedBox(width: 12),
            Text(
              'LOGOUT',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
