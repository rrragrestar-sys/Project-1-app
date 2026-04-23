import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/user_session.dart';
import '../../../shared/models/player.dart';
import '../models/snake_models.dart';
import '../controllers/snake_controller.dart';
import '../widgets/snake_board.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../shared/widgets/win_dialog.dart';
import '../../../core/constants.dart';

class SnakeLadderGamePage extends StatefulWidget {
  final List<Player> players;

  const SnakeLadderGamePage({super.key, required this.players});

  @override
  State<SnakeLadderGamePage> createState() => _SnakeLadderGamePageState();
}

class _SnakeLadderGamePageState extends State<SnakeLadderGamePage>
    with SingleTickerProviderStateMixin {
  late SnakeController _controller;
  late AnimationController _diceAnimController;
  late Animation<double> _diceScale;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    _diceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _diceScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _diceAnimController, curve: Curves.easeOut),
    );

    final snakePlayers = widget.players.asMap().entries.map((entry) {
      return SnakePlayer(
        id: entry.value.id,
        name: entry.value.name,
        playerIndex: entry.key,
        isBot: entry.value.isBot,
      );
    }).toList();

    _controller = SnakeController(players: snakePlayers);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _diceAnimController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.gameState == SnakeGameState.finished && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog());
    }
    if (_controller.isRolling) {
      _diceAnimController.forward().then((_) => _diceAnimController.reverse());
    }
  }

  void _showWinDialog() {
    final bool userWon = _controller.winner?.isBot == false;
    if (userWon) {
      UserSession().depositFiat(500.0);
      WinDialog.show(
        context,
        amount: 500.0,
        onConfirm: () => Navigator.pop(context),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: NeonColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_dissatisfied, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                '${_controller.winner?.name ?? "Bot"} WINS!',
                style: GoogleFonts.oswald(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ShinyButton(
                label: 'BACK TO LOBBY',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                color: NeonColors.primary,
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Column(
                  children: [
                    _buildTopHeader(),
                    _buildPlayerTurnBanner(),
                    if (_controller.lastEventMessage != null) ...[
                      const SizedBox(height: 8),
                      _buildEventMessage(),
                    ],
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 24,
                        borderColor: NeonColors.primary.withValues(alpha: 0.3),
                        blurX: 20,
                        blurY: 20,
                        child: SnakeBoard(controller: _controller),
                      ),
                    ),
                    const Spacer(),
                    _buildBottomPanel(),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'SNAKE & LADDER',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: UserSession(),
            builder: (context, _) => GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 20,
              child: Row(
                children: [
                  const Icon(Icons.wallet, color: NeonColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '₹${UserSession().fiatBalance.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildPlayerTurnBanner() {
    final player = _controller.currentPlayer;
    final color = player.playerIndex == 0 ? Colors.redAccent : Colors.blueAccent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color,
            child: Icon(
              player.isBot ? Icons.smart_toy : Icons.person,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${player.name.toUpperCase()}\'S TURN',
            style: GoogleFonts.oswald(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            '  •  Pos: ${player.position}',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMessage() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      borderRadius: 20,
      borderColor: NeonColors.primary.withValues(alpha: 0.5),
      child: Text(
        _controller.lastEventMessage!,
        style: GoogleFonts.oswald(
          color: NeonColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final bool canRoll = _controller.gameState == SnakeGameState.rolling &&
        !_controller.currentPlayer.isBot &&
        !_controller.isRolling;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ShinyButton(
              label: _controller.isRolling ? 'ROLLING...' : 'ROLL DICE 🎲',
              onPressed: canRoll ? () => _controller.rollDice() : null,
              color: canRoll ? NeonColors.primary : Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 20),
          AnimatedBuilder(
            animation: _diceScale,
            builder: (context, child) => Transform.scale(
              scale: _diceScale.value,
              child: GlassContainer(
                width: 70,
                height: 70,
                borderRadius: 15,
                borderColor: NeonColors.primary.withValues(alpha: 0.6),
                child: Center(
                  child: Text(
                    _getDiceFace(_controller.diceValue),
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDiceFace(int value) {
    const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    if (value < 1 || value > 6) return '⚀';
    return faces[value - 1];
  }
}
