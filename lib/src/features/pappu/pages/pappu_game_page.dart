import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/user_session.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shiny_button.dart';
import '../../../shared/widgets/win_dialog.dart';

class PappuGamePage extends StatefulWidget {
  const PappuGamePage({super.key});

  @override
  State<PappuGamePage> createState() => _PappuGamePageState();
}

class _PappuGamePageState extends State<PappuGamePage> with SingleTickerProviderStateMixin {
  double _betAmount = 100.0;
  final Map<int, double> _activeBets = {};
  bool _isSpinning = false;
  int? _winningIndex;
  
  late AnimationController _spinController;
  final List<PappuIcon> _icons = [
    PappuIcon(id: 0, name: 'Butterfly', emoji: '🦋', color: Colors.pinkAccent),
    PappuIcon(id: 1, name: 'Pigeon', emoji: '🐦', color: Colors.blueAccent),
    PappuIcon(id: 2, name: 'Sun', emoji: '☀️', color: Colors.orangeAccent),
    PappuIcon(id: 3, name: 'Lamp', emoji: '🪔', color: Colors.redAccent),
    PappuIcon(id: 4, name: 'Rose', emoji: '🌹', color: Colors.red),
    PappuIcon(id: 5, name: 'Elephant', emoji: '🐘', color: Colors.grey),
    PappuIcon(id: 6, name: 'Fish', emoji: '🐟', color: Colors.cyanAccent),
    PappuIcon(id: 7, name: 'Parrot', emoji: '🦜', color: Colors.greenAccent),
    PappuIcon(id: 8, name: 'Moon', emoji: '🌙', color: Colors.indigoAccent),
    PappuIcon(id: 9, name: 'Star', emoji: '⭐', color: Colors.amberAccent),
    PappuIcon(id: 10, name: 'Bell', emoji: '🔔', color: Colors.yellowAccent),
    PappuIcon(id: 11, name: 'Umbrella', emoji: '☂️', color: Colors.purpleAccent),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    UserSession().addListener(_onSessionUpdate);
  }

  @override
  void dispose() {
    _spinController.dispose();
    UserSession().removeListener(_onSessionUpdate);
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  void _placeBet(int index) {
    if (_isSpinning) return;
    if (UserSession().balance < _betAmount) return;

    setState(() {
      UserSession().updateBalance(UserSession().balance - _betAmount);
      _activeBets[index] = (_activeBets[index] ?? 0) + _betAmount;
    });
  }

  void _clearBets() {
    if (_isSpinning) return;
    double totalBets = _activeBets.values.fold(0, (sum, val) => sum + val);
    setState(() {
      UserSession().updateBalance(UserSession().balance + totalBets);
      _activeBets.clear();
    });
  }

  Future<void> _spin() async {
    if (_isSpinning || _activeBets.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _winningIndex = null;
    });

    _spinController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 3));
    
    final resultIndex = math.Random().nextInt(12);
    
    setState(() {
      _winningIndex = resultIndex;
      _isSpinning = false;
      
      if (_activeBets.containsKey(resultIndex)) {
        double winAmount = _activeBets[resultIndex]! * 10;
        UserSession().updateBalance(UserSession().balance + winAmount);
        _showWinDialog(winAmount);
      }
      _activeBets.clear();
    });
  }

  void _showWinDialog(double amount) {
    WinDialog.show(
      context,
      amount: amount,
      onConfirm: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildResultBanner(),
                Expanded(child: _buildGrid()),
                _buildControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text('PAPPU PRESTIGE', style: GoogleFonts.oswald(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 20,
            child: Text('₹${UserSession().balance.toInt()}', 
              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      width: double.infinity,
      height: 120,
      margin: const EdgeInsets.all(16),
      child: GlassContainer(
        borderRadius: 24,
        borderColor: Colors.amber.withValues(alpha: 0.3),
        child: Center(
          child: _isSpinning 
            ? const CircularProgressIndicator(color: Colors.amber)
            : _winningIndex == null 
              ? Text('PLACE YOUR BETS', style: GoogleFonts.oswald(color: Colors.white24, letterSpacing: 4, fontSize: 18))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_icons[_winningIndex!].emoji, style: const TextStyle(fontSize: 60)),
                    const SizedBox(width: 24),
                    Text(_icons[_winningIndex!].name.toUpperCase(), 
                      style: GoogleFonts.oswald(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final icon = _icons[index];
        final bet = _activeBets[index] ?? 0;
        final isWinner = _winningIndex == index;

        return GestureDetector(
          onTap: () => _placeBet(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isWinner ? icon.color.withValues(alpha: 0.2) : Colors.black26,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWinner ? icon.color : (bet > 0 ? Colors.amber : Colors.white10),
                width: bet > 0 ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(icon.emoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(icon.name.toUpperCase(), style: GoogleFonts.oswald(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                    ],
                  ),
                ),
                if (bet > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      borderRadius: 8,
                      borderColor: Colors.amber,
                      child: Text('₹${bet.toInt()}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return GlassContainer(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [10, 50, 100, 500, 1000].map((a) => _betChip(a.toDouble())).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _clearBets,
                  child: const Text('CLEAR ALL', style: TextStyle(color: Colors.white30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ShinyButton(
                  label: 'SPIN NOW',
                  onPressed: (_isSpinning || _activeBets.isEmpty) ? null : _spin,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _betChip(double amount) {
    final isSelected = _betAmount == amount;
    return GestureDetector(
      onTap: () => setState(() => _betAmount = amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.white : Colors.amber.withValues(alpha: 0.3), width: 2),
          boxShadow: isSelected ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 10)] : [],
        ),
        child: Center(
          child: Text(
            amount >= 1000 ? '${(amount/1000).toInt()}k' : amount.toInt().toString(),
            style: TextStyle(color: isSelected ? Colors.black : Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class PappuIcon {
  final int id;
  final String name;
  final String emoji;
  final Color color;

  PappuIcon({required this.id, required this.name, required this.emoji, required this.color});
}
