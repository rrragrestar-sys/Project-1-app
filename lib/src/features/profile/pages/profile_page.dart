import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<AvatarData> _avatars = [
    AvatarData(icon: Icons.face_rounded, color: Colors.blueAccent, label: 'Standard'),
    AvatarData(icon: Icons.sports_esports_rounded, color: Colors.purpleAccent, label: 'Gamer'),
    AvatarData(icon: Icons.workspace_premium_rounded, color: Colors.amberAccent, label: 'Royal'),
    AvatarData(icon: Icons.rocket_launch_rounded, color: Colors.orangeAccent, label: 'Pro'),
    AvatarData(icon: Icons.star_rounded, color: Colors.pinkAccent, label: 'Star'),
    AvatarData(icon: Icons.bolt_rounded, color: Colors.cyanAccent, label: 'Bolt'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, _) {
        final session = UserSession();
        final currentAvatar = _avatars[session.avatarIndex];

        return Scaffold(
          backgroundColor: NeonColors.background,
          appBar: AppBar(
            backgroundColor: NeonColors.background,
            elevation: 0,
            title: Text(
              'MY PROFILE',
              style: GoogleFonts.righteous(
                color: Colors.amberAccent,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: NeonColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Avatar Section
                _buildAvatarSection(currentAvatar),
                
                const SizedBox(height: 40),
                
                // Info Fields
                _buildInfoSection(session),
                
                const SizedBox(height: 32),
                
                // Terms & Conditions
                _buildTermsSection(),
                
                const SizedBox(height: 40),
                
                // Logout Button
                _buildLogoutButton(),
                
                const SizedBox(height: 20),
                Text(
                  'App Version 1.0.4 PRO',
                  style: GoogleFonts.inter(
                    color: NeonColors.textSub.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(AvatarData current) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [NeonColors.primary, current.color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: current.color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: NeonColors.background,
                child: Icon(current.icon, size: 60, color: current.color),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showAvatarPicker,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: NeonColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'LEVEL 4 VIP',
          style: GoogleFonts.outfit(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(UserSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoTile('Player Name', session.displayName, Icons.person_outline),
        const SizedBox(height: 16),
        _buildInfoTile('Player ID', session.playerId, Icons.fingerprint),
        const SizedBox(height: 16),
        _buildInfoTile('Phone Number', session.phoneNumber, Icons.phone_android_outlined),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: NeonColors.primary, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: NeonColors.textSub,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeonColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                'Terms & Conditions',
                style: GoogleFonts.outfit(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'By using Lucky King, you agree to our fair-play policy. '
            'All transactions are secured with 256-bit encryption. '
            'Players must be 18+ to participate in real-money contests. '
            'Terms are subject to periodic updates to ensure platform integrity.',
            style: GoogleFonts.inter(
              color: NeonColors.textSub,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              'View Full Document',
              style: GoogleFonts.inter(
                color: NeonColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logging out...'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Text(
              'LOGOUT ACCOUNT',
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeonColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SELECT AVATAR',
                style: GoogleFonts.righteous(
                  color: NeonColors.primary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  return GestureDetector(
                    onTap: () {
                      UserSession().updateUserInfo(avatar: index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: NeonColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: UserSession().avatarIndex == index
                              ? NeonColors.primary
                              : Colors.white12,
                          width: 2,
                        ),
                      ),
                      child: Icon(avatar.icon, color: avatar.color, size: 40),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class AvatarData {
  final IconData icon;
  final Color color;
  final String label;

  AvatarData({required this.icon, required this.color, required this.label});
}
