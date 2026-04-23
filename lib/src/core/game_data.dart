import 'package:flutter/material.dart';
import '../features/aviator/pages/aviator_page.dart';
import '../features/ludo/pages/ludo_page.dart';
import '../features/carrom/pages/carrom_page.dart';
import '../features/snake_ladder/pages/snake_ladder_page.dart';
import '../features/seven_up_seven_down/pages/seven_up_seven_down_page.dart';
import '../features/chicken_road/pages/chicken_road_page.dart';
import '../features/slots/pages/fortune_gems_page.dart';
import '../features/slots/pages/fortune_gems_2_page.dart';
import '../features/slots/pages/money_coming_page.dart';
import '../features/pappu/pages/pappu_game_page.dart';
import '../features/slots/pages/super_ace_page.dart';
import '../features/slots/pages/crazy_777_page.dart';
import '../features/slots/pages/clover_coins_page.dart';
import '../features/slots/pages/fortune_garuda_page.dart';
import '../features/fishing/pages/fishing_game_page.dart';
import '../features/color_prediction/pages/color_prediction_page.dart';
import '../features/slots/pages/generic_slot_page.dart';
import '../features/slots/models/slot_engine.dart';

enum GameCategory { all, slots, fishing, crash, classic }

class GameInfo {
  final String title;
  final String provider;
  final String image;
  final Widget? page;
  final bool isNew;
  final GameCategory category;

  const GameInfo({
    required this.title,
    required this.provider,
    required this.image,
    required this.category,
    this.page,
    this.isNew = false,
  });
}

const List<GameInfo> allGames = [
  GameInfo(
    title: 'Fortune Garuda 500',
    provider: 'JILI',
    image: 'assets/fortune_garuda_500.png',
    page: FortuneGarudaPage(),
    isNew: true,
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Fortune Gems 2',
    provider: 'JILI',
    image: 'assets/fortune_gems_2.png',
    page: FortuneGems2Page(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Money Coming',
    provider: 'JILI',
    image: 'assets/money_coming.png',
    page: MoneyComingPage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: '7UP 7DOWN',
    provider: 'DICE GAMES',
    image: 'assets/7up7down.png',
    page: SevenUpSevenDownPage(),
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'Color Prediction',
    provider: 'CLASSIC',
    image: 'assets/7up7down.png',
    page: ColorPredictionPage(),
    isNew: true,
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'Fortune Gems 3',
    provider: 'JILI',
    image: 'assets/fortune_gems_3.png',
    page: FortuneGemsPage(),
    isNew: true,
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Chicken Road 2',
    provider: 'INSTANT WIN',
    image: 'assets/chicken_road.png',
    page: ChickenRoadPage(),
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'Money Coming 2',
    provider: 'JILI',
    image: 'assets/money_coming_2.png',
    page: MoneyComingPage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Aviator',
    provider: 'SPRIBE',
    image: 'assets/aviator.png',
    page: AviatorPage(),
    category: GameCategory.crash,
  ),
  GameInfo(
    title: 'Money Coming Expanded Bets',
    provider: 'JILI',
    image: 'assets/money_coming_expanded.png',
    page: MoneyComingPage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Fortune Gems',
    provider: 'JILI',
    image: 'assets/fortune_gems.png',
    page: FortuneGemsPage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Clover Coins 3x3',
    provider: 'JILI',
    image: 'assets/clover_coins_3x3.png',
    page: CloverCoinsPage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Pappu',
    provider: 'JILI',
    image: 'assets/pappu.png',
    page: PappuGamePage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Fortune Coins',
    provider: 'JILI',
    image: 'assets/fortune_coins.png',
    page: CloverCoinsPage(),
    isNew: true,
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Jackpot Finshing',
    provider: 'JILI',
    image: 'assets/jackpot_fishing.png',
    page: FishingGamePage(),
    category: GameCategory.fishing,
  ),
  GameInfo(
    title: 'Super Ace',
    provider: 'JILI',
    image: 'assets/super_ace.png',
    page: SuperAcePage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Crazy 777',
    provider: 'JILI',
    image: 'assets/crazy_777.png',
    page: Crazy777Page(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'GoRush JILI',
    provider: 'JILI',
    image: 'assets/gorush_jili.png',
    page: AviatorPage(),
    category: GameCategory.crash,
  ),
  GameInfo(
    title: 'Crazy 777 2',
    provider: 'JILI',
    image: 'assets/crazy_777_v2.png',
    page: Crazy777Page(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Money Pot',
    provider: 'JILI',
    image: 'assets/money_pot.png',
    page: CloverCoinsPage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'Spribe Aviator',
    provider: 'SPRIBE',
    image: 'assets/aviator.png',
    page: AviatorPage(),
    category: GameCategory.crash,
  ),
  GameInfo(
    title: 'Super Ace Deluxe',
    provider: 'JILI',
    image: 'assets/super_ace_deluxe.png',
    page: SuperAcePage(),
    category: GameCategory.slots,
  ),
  GameInfo(
    title: 'LUDO',
    provider: 'CLASSIC',
    image: 'assets/ludo.png',
    page: LudoPage(),
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'CARROM',
    provider: 'CLASSIC',
    image: 'assets/carrom.png',
    page: CarromPage(),
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'SNAKE & LADDER',
    provider: 'CLASSIC',
    image: 'assets/snake_ladder.png',
    page: SnakeLadderPage(),
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'Speed Baccarat 1',
    provider: 'EVOLUTION',
    image: 'assets/baccarat.png',
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'Ultimate Blackjack',
    provider: 'EVOLUTION',
    image: 'assets/blackjack.png',
    category: GameCategory.classic,
  ),
  GameInfo(
    title: 'Cosmic Jack',
    provider: 'JILI',
    image: 'assets/cosmic_jack.png',
    category: GameCategory.slots,
    page: GenericSlotPage(
      title: 'Cosmic Jack',
      themeColor: Colors.deepPurple,
      symbols: [
        SlotSymbol(id: '7', imageUrl: 'assets/crazy_777.png', valueMultiplier: 10),
        SlotSymbol(id: 'gems', imageUrl: 'assets/fortune_gems.png', valueMultiplier: 5),
        SlotSymbol(id: 'coins', imageUrl: 'assets/clover_coins_3x3.png', valueMultiplier: 2),
      ],
    ),
  ),
  GameInfo(
    title: 'Crimson Luck',
    provider: 'JILI',
    image: 'assets/crimson_luck.png',
    category: GameCategory.slots,
    page: GenericSlotPage(
      title: 'Crimson Luck',
      themeColor: Colors.redAccent,
      symbols: [
        SlotSymbol(id: '7', imageUrl: 'assets/crazy_777.png', valueMultiplier: 10),
        SlotSymbol(id: 'gems', imageUrl: 'assets/fortune_gems.png', valueMultiplier: 5),
        SlotSymbol(id: 'coins', imageUrl: 'assets/clover_coins_3x3.png', valueMultiplier: 2),
      ],
    ),
  ),
  GameInfo(
    title: 'Golden Empire',
    provider: 'JILI',
    image: 'assets/golden_empire.png',
    category: GameCategory.slots,
    page: GenericSlotPage(
      title: 'Golden Empire',
      themeColor: Colors.amber,
      symbols: [
        SlotSymbol(id: '7', imageUrl: 'assets/crazy_777.png', valueMultiplier: 10),
        SlotSymbol(id: 'gems', imageUrl: 'assets/fortune_gems.png', valueMultiplier: 5),
        SlotSymbol(id: 'coins', imageUrl: 'assets/clover_coins_3x3.png', valueMultiplier: 2),
      ],
    ),
  ),
  GameInfo(
    title: 'Marble Wealth',
    provider: 'JILI',
    image: 'assets/marble_wealth.png',
    category: GameCategory.slots,
    page: GenericSlotPage(
      title: 'Marble Wealth',
      themeColor: Colors.teal,
      symbols: [
        SlotSymbol(id: '7', imageUrl: 'assets/crazy_777.png', valueMultiplier: 10),
        SlotSymbol(id: 'gems', imageUrl: 'assets/fortune_gems.png', valueMultiplier: 5),
        SlotSymbol(id: 'coins', imageUrl: 'assets/clover_coins_3x3.png', valueMultiplier: 2),
      ],
    ),
  ),
  GameInfo(
    title: 'Neon Sugar',
    provider: 'JILI',
    image: 'assets/neon_sugar.png',
    category: GameCategory.slots,
    page: GenericSlotPage(
      title: 'Neon Sugar',
      themeColor: Colors.pinkAccent,
      symbols: [
        SlotSymbol(id: '7', imageUrl: 'assets/crazy_777.png', valueMultiplier: 10),
        SlotSymbol(id: 'gems', imageUrl: 'assets/fortune_gems.png', valueMultiplier: 5),
        SlotSymbol(id: 'coins', imageUrl: 'assets/clover_coins_3x3.png', valueMultiplier: 2),
      ],
    ),
  ),
];
