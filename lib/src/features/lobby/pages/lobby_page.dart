import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/game_data.dart';
import '../../../shared/widgets/neon_header.dart';
import '../../../shared/widgets/neon_bottom_nav.dart';
import '../widgets/neon_carousel.dart';
import '../widgets/game_card.dart';
import '../widgets/live_casino_card.dart';
import '../../../shared/widgets/neon_drawer.dart';
import '../../profile/pages/profile_page.dart';
import '../../wallet/pages/wallet_page.dart';
import '../../aviator/pages/aviator_page.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  int _selectedIndex = 0;
  GameCategory _selectedCategory = GameCategory.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      // Profile Navigation
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
      return;
    }

    if (index == 1) {
      // Wallet Navigation
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WalletPage()),
      );
      return;
    }

    if (index == 2) {
      // Offers placeholder
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OFFERS feature coming soon!'),
          backgroundColor: NeonColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _launchRocketGame() {
    // Navigates directly to Aviator / Crash Game as the Quick Action
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AviatorPage()),
    );
  }

  List<GameInfo> get _filteredGames {
    return allGames.where((game) {
      final matchesCategory = _selectedCategory == GameCategory.all || game.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          game.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          game.provider.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: const NeonHeader(),
      drawer: const NeonDrawer(),
      body: Stack(
        children: [
          // Premium Maroon Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.5),
                radius: 1.5,
                colors: [
                  Color(0xFF2A0000),
                  Color(0xFF110000),
                  Colors.black,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const NeonCarousel(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildCategorySelector(),
                
                // Popular Games Section
                _buildSectionHeader('POPULAR GAMES', 'VIEW ALL'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredGames.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final game = _filteredGames[index];
                      return GameCard(
                        title: game.title,
                        provider: game.provider,
                        imageUrl: game.image,
                        onTap: () {
                          if (game.page != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => game.page!),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${game.title} is coming soon!'),
                                backgroundColor: NeonColors.primary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      );
                    },
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
                const SizedBox(height: 100), // Extra space for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchRocketGame,
        backgroundColor: NeonColors.primary,
        elevation: 10,
        highlightElevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 2),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.rocket_launch, color: Colors.white, size: 28),
          ),
        ),
      ),
      bottomNavigationBar: NeonBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: NeonColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25), // Pill shaped search bar
          border: Border.all(color: NeonColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: NeonColors.primary.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'SEARCH FOR GAMES...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12, letterSpacing: 1),
            prefixIcon: const Icon(Icons.search, color: NeonColors.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: NeonColors.textSub, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: GameCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [NeonColors.primary, NeonColors.secondary])
                      : LinearGradient(colors: [NeonColors.surface, NeonColors.surface.withValues(alpha: 0.5)]),
                  borderRadius: BorderRadius.circular(30), // Premium Pill shape
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: NeonColors.primary.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  category.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: NeonColors.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: NeonColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeonColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              action,
              style: const TextStyle(
                color: NeonColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveWinnersTicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: NeonColors.surface,
        border: Border(
          top: BorderSide(color: NeonColors.primary.withValues(alpha: 0.2)),
          bottom: BorderSide(color: NeonColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.campaign, color: NeonColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'WINNERS:',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'User***42 won 1,240 Coins! • User***11 won 450 Coins! • User***88 won 90 Coins! •',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
