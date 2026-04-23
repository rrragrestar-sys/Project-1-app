import '../../../shared/models/player.dart';

enum LudoColor { red, green, yellow, blue }

enum TokenState { inBase, onPath, safeZone, homePath, home }

enum LudoGameState { rolling, moving, finished }

class LudoToken {
  final int id;
  final LudoColor color;
  int position; // -1 for base, 0-51 for path, 52-56 for home path, 57 for home
  TokenState state;

  LudoToken({
    required this.id,
    required this.color,
    this.position = -1,
    this.state = TokenState.inBase,
  });

  LudoToken copyWith({
    int? position,
    TokenState? state,
  }) {
    return LudoToken(
      id: id,
      color: color,
      position: position ?? this.position,
      state: state ?? this.state,
    );
  }
}

class LudoPlayer extends Player {
  final LudoColor ludoColor;
  final List<LudoToken> tokens;
  final int finishCount;

  LudoPlayer({
    required super.id,
    required super.name,
    super.avatarUrl,
    super.isBot,
    super.isReady,
    required this.ludoColor,
    required this.tokens,
    this.finishCount = 0,
  });

  LudoPlayer copyWithLudo({
    List<LudoToken>? tokens,
    int? finishCount,
  }) {
    return LudoPlayer(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      isBot: isBot,
      isReady: isReady,
      ludoColor: ludoColor,
      tokens: tokens ?? this.tokens,
      finishCount: finishCount ?? this.finishCount,
    );
  }
}
