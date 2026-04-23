import 'package:flutter/material.dart';
import '../../../shared/models/player.dart';
import '../../../shared/widgets/matchmaking_overlay.dart';
import 'carrom_game_page.dart';

class CarromPage extends StatefulWidget {
  const CarromPage({super.key});

  @override
  State<CarromPage> createState() => _CarromPageState();
}

class _CarromPageState extends State<CarromPage> {
  @override
  Widget build(BuildContext context) {
    return MatchmakingOverlay(
      gameTitle: 'Carrom Pro',
      maxPlayers: 2,
      onStartWithBots: () => _startGame(isBot: true),
      onMatchFound: (players) => _startGame(playerNames: players),
    );
  }

  void _startGame({bool isBot = false, List<String>? playerNames}) {
    List<Player> players = [];
    if (isBot) {
      players = [
        Player(id: 'user', name: 'You', isReady: true),
        Player(id: 'bot1', name: 'Bot 1', isBot: true, isReady: true),
      ];
    } else if (playerNames != null) {
      players = playerNames.asMap().entries.map((e) => Player(
        id: 'p${e.key}',
        name: e.value,
        isReady: true,
      )).toList();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CarromGamePage(players: players),
      ),
    );
  }
}
