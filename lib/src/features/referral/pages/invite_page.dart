import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';

class InvitePage extends StatelessWidget {
  const InvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final String shareMessage = 
        '🔥 Join me on Lucky King and win big! 🔥\n\n'
        'Use my referral code: ${session.referralCode}\n'
        'Download now and get a 100% Welcome Bonus!\n\n'
        'Check it out: https://luckyking.app/join';

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: NeonColors.background,
        elevation: 0,
        title: Text(
          'REFER & EARN',
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
            // Promotion Banner
            _buildPromoCard(),
            
            const SizedBox(height: 32),
            
            // Referral Code Card
            _buildReferralCard(context, session.referralCode),
            
            const SizedBox(height: 32),
            
            // Share Buttons
            _buildShareActions(context, shareMessage),
            
            const SizedBox(height: 40),
            
            // How it Works
            _buildHowItWorks(),
            
            const SizedBox(height: 40),
            
            // Small Disclaimer
            Text(
              'T&C Applied. Rewards are credited after friend\'s first successful deposit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: NeonColors.textSub.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [NeonColors.primary, NeonColors.primary.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: NeonColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 60, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'WIN UP TO 1000 COINS',
            textAlign: TextAlign.center,
            style: GoogleFonts.righteous(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite your friends and earn high-value rewards for every successful referral.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            'YOUR UNIQUE CODE',
            style: GoogleFonts.inter(
              color: NeonColors.textSub,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeonColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code,
                  style: GoogleFonts.righteous(
                    color: NeonColors.primary,
                    fontSize: 24,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        backgroundColor: NeonColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareActions(BuildContext context, String message) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            // ignore: deprecated_member_use
            onPressed: () => Share.share(message),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('SHARE NOW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeonColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366), // WhatsApp Green
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.wechat_sharp, color: Colors.white), // Using Generic Social Icon
            // ignore: deprecated_member_use
            onPressed: () => Share.share(message),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW IT WORKS',
          style: GoogleFonts.righteous(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 24),
        _buildStep(1, 'Invite Friends', 'Share your referral code via social media or messengers.'),
        const SizedBox(height: 16),
        _buildStep(2, 'They Register', 'Your friend signs up using your unique code.'),
        const SizedBox(height: 16),
        _buildStep(3, 'Both Earn', 'You and your friend receive bonus coins on their first deposit!'),
      ],
    );
  }

  Widget _buildStep(int number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: NeonColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: NeonColors.textSub,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
