import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/neon_header.dart';
import '../../../shared/widgets/neon_bottom_nav.dart';
import '../widgets/real_demo_toggle.dart';
import '../widgets/featured_banner.dart';
import '../widgets/game_card.dart';
import '../widgets/live_casino_card.dart';
import '../../aviator/pages/aviator_page.dart';
import '../../chicken_road/pages/chicken_road_page.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: const NeonHeader(balance: 12500.50),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const RealDemoToggle(),
            const FeaturedBanner(),
            
            // Popular Games Section
            _buildSectionHeader('POPULAR GAMES', 'VIEW ALL'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  GameCard(
                    title: 'Aviator',
                    provider: 'SPRIBE',
                    imageUrl: 'assets/aviator.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AviatorPage()),
                      );
                    },
                  ),
                  GameCard(
                    title: 'Chicken Road',
                    provider: 'INSTANT WIN',
                    imageUrl: 'assets/chicken_road.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChickenRoadPage(),
                        ),
                      );
                    },
                  ),
                  const GameCard(
                    title: '7 Up 7 Down',
                    provider: 'DICE GAMES',
                    imageUrl: 'assets/7up7down.png',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live Casino Section
            _buildSectionHeader('LIVE CASINO', 'VIEW ALL'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  LiveCasinoCard(
                    title: 'Speed Baccarat 1',
                    tables: 12,
                    imageUrl: 'assets/baccarat.png',
                  ),
                  LiveCasinoCard(
                    title: 'Ultimate Blackjack',
                    tables: 8,
                    imageUrl: 'assets/blackjack.png',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            _buildLiveWinnersTicker(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: NeonBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: NeonColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveWinnersTicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: NeonColors.surface,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.flash_on, color: NeonColors.primary, size: 16),
          const SizedBox(width: 8),
          const Text(
            'LIVE WINNERS:',
            style: TextStyle(color: NeonColors.textSub, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'User***42 won \$1,240.00 on Aviator! • User***11 won \$450.00 on Chicken Road! • User***88 won \$90.00 on 7 Up 7 Down! •',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
