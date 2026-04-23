import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';
import '../controllers/chicken_road_controller.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../shared/widgets/win_dialog.dart';

class ChickenRoadPage extends StatefulWidget {
  const ChickenRoadPage({super.key});

  @override
  State<ChickenRoadPage> createState() => _ChickenRoadPageState();
}

class _ChickenRoadPageState extends State<ChickenRoadPage>
    with SingleTickerProviderStateMixin {
  final ChickenRoadController _ctrl = ChickenRoadController();
  late AnimationController _chickenBob;
  late Animation<double> _bob;
  bool _winDialogShown = false;

  @override
  void initState() {
    super.initState();
    _chickenBob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
    _bob = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _chickenBob, curve: Curves.easeInOut),
    );
    _ctrl.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.state == ChickenRoadState.won && !_winDialogShown) {
      _winDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WinDialog.show(
          context,
          amount: _ctrl.potentialPayout,
          onConfirm: () {},
        );
      });
    }
    if (_ctrl.state == ChickenRoadState.idle) {
      _winDialogShown = false;
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onUpdate);
    _chickenBob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Chicken Road signature green gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D2E0D), Color(0xFF050E05), Colors.black],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildMultiplierBar(),
                const SizedBox(height: 16),
                Expanded(child: _buildRoadGrid()),
                _buildBottomPanel(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'CHICKEN ROAD',
            style: GoogleFonts.righteous(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
              shadows: [const Shadow(color: Colors.greenAccent, blurRadius: 10)],
            ),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: UserSession(),
            builder: (context, _) => GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

  Widget _buildMultiplierBar() {
    final bool isActive = _ctrl.state == ChickenRoadState.hopping && _ctrl.currentLane >= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.greenAccent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Text(
            isActive ? '${_ctrl.currentMultiplier}x' : '—',
            style: GoogleFonts.righteous(
              color: Colors.greenAccent,
              fontSize: 42,
              shadows: [
                if (isActive) const Shadow(color: Colors.green, blurRadius: 20)
              ],
            ),
          ),
          if (isActive)
            Text(
              'CASHOUT: ₹${_ctrl.potentialPayout.toStringAsFixed(0)}',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildRoadGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Chicken row
          _buildChickenRow(),
          const SizedBox(height: 8),
          // Lane grid (displayed bottom to top = lane 0 at bottom)
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: 10,
              itemBuilder: (context, lane) => _buildLane(lane),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChickenRow() {
    if (_ctrl.state == ChickenRoadState.crashed) {
      return const Text('💥', style: TextStyle(fontSize: 56));
    }

    // Show chicken at its current lane or at start
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bob.value),
        child: const Text('🐔', style: TextStyle(fontSize: 52)),
      ),
    );
  }

  Widget _buildLane(int lane) {
    final bool isActive = _ctrl.currentLane == lane;
    final bool? result = _ctrl.laneResults[lane];

    final Color laneColor = result == null
        ? Colors.white.withValues(alpha: 0.04)
        : (result == true ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15));

    final Color borderColor = isActive
        ? Colors.greenAccent
        : (result == null ? Colors.white10 : (result == true ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5)));

    return GestureDetector(
      onTap: _ctrl.state == ChickenRoadState.hopping ? () => _ctrl.hop() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: laneColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        ),
        child: Row(
          children: [
            // Multiplier label
            SizedBox(
              width: 60,
              child: Text(
                '${ChickenRoadController.laneMultipliers[lane]}x',
                style: GoogleFonts.righteous(
                  color: isActive ? Colors.greenAccent : Colors.white38,
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(),
            // Tile icon
            if (result == null)
              const Icon(Icons.egg_outlined, color: Colors.white24, size: 28)
            else if (result == true)
              const Text('✅', style: TextStyle(fontSize: 24))
            else
              const Text('💣', style: TextStyle(fontSize: 24)),
            const Spacer(),
            // Bomb risk
            Text(
              '${(ChickenRoadController.bombChance[lane] * 100).toInt()}% risk',
              style: GoogleFonts.inter(
                color: Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final bool isIdle = _ctrl.state == ChickenRoadState.idle;
    final bool isHopping = _ctrl.state == ChickenRoadState.hopping;
    final bool canCashout = isHopping && _ctrl.currentLane >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (isIdle) _buildBetSelector(),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isIdle)
                Expanded(
                  child: ShinyButton(
                    label: 'START  🐔',
                    onPressed: () => _ctrl.startGame(),
                    color: Colors.greenAccent.shade700,
                  ),
                )
              else if (isHopping) ...[
                Expanded(
                  child: ShinyButton(
                    label: 'HOP →',
                    onPressed: _ctrl.currentLane < 9 ? () => _ctrl.hop() : null,
                    color: NeonColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                if (canCashout)
                  Expanded(
                    child: ShinyButton(
                      label: 'CASHOUT\n₹${_ctrl.potentialPayout.toStringAsFixed(0)}',
                      onPressed: () => _ctrl.cashOut(),
                      color: Colors.greenAccent.shade400,
                    ),
                  ),
              ] else
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    child: Center(
                      child: Text(
                        _ctrl.state == ChickenRoadState.crashed
                            ? '💥 CRASHED! Better luck next time'
                            : '🎉 YOU WON! ₹${_ctrl.potentialPayout.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: _ctrl.state == ChickenRoadState.crashed
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBetSelector() {
    return Row(
      children: [
        Text('BET: ', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        const Spacer(),
        ...([50, 100, 200, 500].map((amt) {
          final bool sel = _ctrl.betAmount == amt.toDouble();
          return GestureDetector(
            onTap: () => _ctrl.setBet(amt.toDouble()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? Colors.greenAccent : Colors.transparent),
              ),
              child: Text(
                '₹$amt',
                style: GoogleFonts.inter(
                  color: sel ? Colors.greenAccent : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        })),
      ],
    );
  }
}
