import '../../../shared/models/player.dart';

class SnakePlayer extends Player {
  int position; // 0-100 (0 is starting point, 100 is win)
  final int playerIndex;

  SnakePlayer({
    required super.id,
    required super.name,
    super.avatarUrl,
    super.isBot,
    super.isReady,
    required this.playerIndex,
    this.position = 0,
  });

  SnakePlayer copyWithSnake({
    int? position,
  }) {
    return SnakePlayer(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      isBot: isBot,
      isReady: isReady,
      playerIndex: playerIndex,
      position: position ?? this.position,
    );
  }
}

class SnakeLadderConfig {
  // Map of start -> end positions
  static const Map<int, int> ladders = {
    4: 14,
    9: 31,
    20: 38,
    28: 84,
    40: 59,
    51: 67,
    63: 81,
    71: 91,
  };

  static const Map<int, int> snakes = {
    17: 7,
    54: 34,
    62: 18,
    64: 60,
    87: 24,
    93: 73,
    95: 75,
    99: 78,
  };
}
