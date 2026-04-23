import 'package:flutter/material.dart';
import '../../../shared/models/player.dart';
import '../../../shared/widgets/matchmaking_overlay.dart';
import 'snake_ladder_game_page.dart';

class SnakeLadderPage extends StatefulWidget {
  const SnakeLadderPage({super.key});

  @override
  State<SnakeLadderPage> createState() => _SnakeLadderPageState();
}

class _SnakeLadderPageState extends State<SnakeLadderPage> {
  @override
  Widget build(BuildContext context) {
    return MatchmakingOverlay(
      gameTitle: 'Snake & Ladder',
      maxPlayers: 4,
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
        Player(id: 'bot2', name: 'Bot 2', isBot: true, isReady: true),
        Player(id: 'bot3', name: 'Bot 3', isBot: true, isReady: true),
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
        builder: (context) => SnakeLadderGamePage(players: players),
      ),
    );
  }
}
