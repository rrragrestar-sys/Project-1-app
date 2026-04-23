import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../lobby/widgets/game_card.dart';
import '../../../core/game_data.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/liquid_background.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<GameInfo> _filteredGames = [];

  @override
  void initState() {
    super.initState();
    _filteredGames = allGames;
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredGames = allGames;
      });
    } else {
      setState(() {
        _filteredGames = allGames
            .where((game) =>
                game.title.toLowerCase().contains(query.toLowerCase()) ||
                game.provider.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const LiquidBackground(),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: GlassContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search games, providers...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filteredGames.isEmpty
                    ? _buildEmptyState()
                    : _buildResults(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSub.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No games found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term',
            style: TextStyle(
              color: AppColors.textSub,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredGames.length,
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
                  backgroundColor: AppColors.surface,
                ),
              );
            }
          },
        );
      },
    );
  }
}
