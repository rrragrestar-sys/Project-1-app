import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/user_session.dart';
import '../../../shared/models/player.dart';
import '../controllers/carrom_controller.dart';
import '../widgets/carrom_board.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/win_dialog.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../core/constants.dart';

class CarromGamePage extends StatefulWidget {
  final List<Player> players;

  const CarromGamePage({super.key, required this.players});

  @override
  State<CarromGamePage> createState() => _CarromGamePageState();
}

class _CarromGamePageState extends State<CarromGamePage> {
  late CarromController _controller;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = CarromController();
    _controller.addListener(_checkGameOver);
  }

  @override
  void dispose() {
    _controller.removeListener(_checkGameOver);
    super.dispose();
  }

  void _checkGameOver() {
    if (_dialogShown || !_controller.isGameOver) return;
    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Determine winner: who pocketed more of their pieces?
      final int p0Score = _controller.playerScores[0] ?? 0;
      final int p1Score = _controller.playerScores[1] ?? 0;
      final bool userWon = p0Score >= p1Score;

      if (userWon && widget.players.isNotEmpty && !widget.players[0].isBot) {
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
                const Icon(Icons.sentiment_dissatisfied,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                Text(
                  'BOT WINS!',
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Score: You $p0Score — Bot $p1Score',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
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
    });
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
                    const SizedBox(height: 8),
                    _buildScoreBoard(),
                    const SizedBox(height: 12),
                    _buildTurnIndicator(),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(4),
                        borderRadius: 16,
                        borderColor: NeonColors.primary.withValues(alpha: 0.3),
                        blurX: 20,
                        blurY: 20,
                        child: CarromBoard(controller: _controller),
                      ),
                    ),
                    const Spacer(),
                    _buildStrikerControls(),
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
            'CARROM PRO',
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
                  const SizedBox(width: 8),
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

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildPlayerScore(
            widget.players.isNotEmpty ? widget.players[0].name : 'YOU',
            _controller.playerScores[0] ?? 0,
            Colors.white,
            _controller.currentPlayerIndex == 0,
            '⚪',
          ),
          const Spacer(),
          _buildVsChip(),
          const Spacer(),
          _buildPlayerScore(
            widget.players.length > 1 ? widget.players[1].name : 'BOT',
            _controller.playerScores[1] ?? 0,
            Colors.black87,
            _controller.currentPlayerIndex == 1,
            '⚫',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(
      String name, int score, Color coinColor, bool isTurn, String emoji) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
      borderColor: isTurn ? NeonColors.primary : Colors.white10,
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(name,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Text(
            '$score',
            style: GoogleFonts.dotGothic16(
                color: NeonColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVsChip() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 20,
      child: Text(
        'VS',
        style: GoogleFonts.oswald(
            color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    final bool isUserTurn = _controller.currentPlayerIndex == 0;
    final Color color = isUserTurn ? Colors.white : Colors.grey.shade400;
    return Text(
      isUserTurn
          ? '🎯  YOUR TURN — Drag striker to aim & shoot'
          : '🤖  BOT IS THINKING...',
      style: GoogleFonts.inter(
          color: color.withValues(alpha: 0.7), fontSize: 12, letterSpacing: 0.5),
    );
  }

  Widget _buildStrikerControls() {
    final bool isUserTurn = _controller.currentPlayerIndex == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            isUserTurn ? 'POSITION STRIKER' : '',
            style: GoogleFonts.oswald(color: Colors.white60, fontSize: 14, letterSpacing: 1),
          ),
          if (isUserTurn) ...[
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 30,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: NeonColors.primary,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: NeonColors.primary,
                  overlayColor: NeonColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _controller.strikerX,
                  min: 0.15,
                  max: 0.85,
                  onChanged: !_controller.isMoving
                      ? (val) => _controller.setStrikerPosition(val)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'DRAG STRIKER ON BOARD TO SHOOT ↑',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
