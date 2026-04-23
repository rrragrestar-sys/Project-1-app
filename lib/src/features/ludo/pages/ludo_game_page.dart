import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/user_session.dart';
import '../../../shared/models/player.dart';
import '../models/ludo_models.dart';
import '../controllers/ludo_controller.dart';
import '../widgets/ludo_board.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../shared/widgets/win_dialog.dart';
import '../../../core/constants.dart';

class LudoGamePage extends StatefulWidget {
  final List<Player> players;

  const LudoGamePage({super.key, required this.players});

  @override
  State<LudoGamePage> createState() => _LudoGamePageState();
}

class _LudoGamePageState extends State<LudoGamePage>
    with SingleTickerProviderStateMixin {
  late LudoController _controller;
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

    final ludoPlayers = widget.players.asMap().entries.map((entry) {
      final color = LudoColor.values[entry.key % 4];
      return LudoPlayer(
        id: entry.value.id,
        name: entry.value.name,
        avatarUrl: entry.value.avatarUrl,
        isBot: entry.value.isBot,
        isReady: entry.value.isReady,
        ludoColor: color,
        tokens: List.generate(4, (i) => LudoToken(id: i, color: color)),
      );
    }).toList();

    _controller = LudoController(players: ludoPlayers);
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
    if (_controller.gameState == LudoGameState.finished && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog());
    }
    // Pulse dice when rolling
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
      // Bot won — show defeat screen
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
                style: GoogleFonts.oswald(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ShinyButton(
                label: 'BACK TO LOBBY',
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close game
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
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 24,
                        borderColor: NeonColors.primary.withValues(alpha: 0.3),
                        blurX: 20,
                        blurY: 20,
                        child: LudoBoard(controller: _controller),
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
            'LUDO',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
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
    final color = _getLudoColor(player.ludoColor);
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
              color: Colors.black,
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
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    final bool canRoll = _controller.gameState == LudoGameState.rolling &&
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
          // Animated dice display
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

  Color _getLudoColor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return Colors.redAccent;
      case LudoColor.green:
        return Colors.greenAccent;
      case LudoColor.yellow:
        return Colors.yellowAccent;
      case LudoColor.blue:
        return Colors.blueAccent;
    }
  }
}
