class Player {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isBot;
  final bool isReady;

  Player({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isBot = false,
    this.isReady = false,
  });

  Player copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isBot,
    bool? isReady,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBot: isBot ?? this.isBot,
      isReady: isReady ?? this.isReady,
    );
  }
}
