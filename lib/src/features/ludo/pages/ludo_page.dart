import 'package:flutter/material.dart';
import '../../../shared/models/player.dart';
import '../../../shared/widgets/matchmaking_overlay.dart';
import 'ludo_game_page.dart';

class LudoPage extends StatefulWidget {
  const LudoPage({super.key});

  @override
  State<LudoPage> createState() => _LudoPageState();
}

class _LudoPageState extends State<LudoPage> {
  @override
  Widget build(BuildContext context) {
    return MatchmakingOverlay(
      gameTitle: 'Ludo Pro',
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
        builder: (context) => LudoGamePage(players: players),
      ),
    );
  }
}
