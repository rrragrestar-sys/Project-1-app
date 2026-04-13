import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../widgets/aviator_painter.dart';

enum GameState { betting, waiting, flying, crashed }

class AviatorPage extends StatefulWidget {
  const AviatorPage({super.key});

  @override
  State<AviatorPage> createState() => _AviatorPageState();
}

class _AviatorPageState extends State<AviatorPage> with TickerProviderStateMixin {
  GameState _gameState = GameState.betting;
  double _multiplier = 1.0;
  double _timeInFlight = 0.0;
  double _crashPoint = 2.5;
  int _bettingCountdown = 10;
  
  // Balance state
  double _userBalance = 12500.50;
  
  // Betting state
  double _betAmount = 100.0;
  bool _isBetPlaced = false;
  bool _autoBet1 = false;
  double? _cashoutMultiplier;
  
  Timer? _gameTimer;
  late AnimationController _planeController;
  
  // Simulation data
  final List<double> _history = [1.24, 5.02, 1.00, 15.42, 2.15, 1.88, 3.42];
  final List<Map<String, dynamic>> _liveBets = [];
  final math.Random _random = math.Random();
  double _gridOffset = 0.0;
  
  // Betting panel 2
  double _betAmount2 = 100.0;
  bool _isBetPlaced2 = false;
  bool _autoBet2 = false;
  double? _cashoutMultiplier2;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Auto-cashout
  bool _autoCashout1 = false;
  double _autoCashoutThreshold1 = 2.0;
  bool _autoCashout2 = false;
  double _autoCashoutThreshold2 = 5.0;
  
  late AnimationController _exitController;
  late Animation<Offset> _exitAnimation;

  @override
  void initState() {
    super.initState();
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(5.0, -5.0)).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _generateMockLiveBets();
    _startBettingCycle();
  }

  void _generateMockLiveBets() {
    final names = ['Alpha', 'Beta', 'GamerX', 'Lucky7', 'WinMax', 'NeonFly', 'Ace'];
    for (var name in names) {
      _liveBets.add({
        'name': '$name***${_random.nextInt(99)}',
        'bet': (50 + _random.nextInt(200)).toDouble(),
        'cashout': null,
      });
    }
  }

  void _startBettingCycle() {
    setState(() {
      _gameState = GameState.betting;
      _bettingCountdown = 5; 
      _multiplier = 1.0;
      _timeInFlight = 0.0;
      _gridOffset = 0.0;
      _isBetPlaced = _autoBet1 && _userBalance >= _betAmount;
      _isBetPlaced2 = _autoBet2 && _userBalance >= _betAmount2;
      
      if (_isBetPlaced) _userBalance -= _betAmount;
      if (_isBetPlaced2) _userBalance -= _betAmount2;

      _cashoutMultiplier = null;
      _cashoutMultiplier2 = null;
      
      // Reset live bets
      for (var bet in _liveBets) {
        bet['cashout'] = null;
      }
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_bettingCountdown > 0) {
        setState(() => _bettingCountdown--);
      } else {
        timer.cancel();
        _prepareFlight();
      }
    });
  }

  void _prepareFlight() {
    setState(() => _gameState = GameState.waiting);
    // Provably Fair Style Logic
    // crashPoint = 0.99 * 100 / (100 - r) where r is [0, 99]
    double r = _random.nextDouble() * 100;
    _crashPoint = math.max(1.0, 0.99 * 100 / (100 - r));
    
    // Cap at 1000x for safety, but extremely rare
    if (_crashPoint > 1000) _crashPoint = 1000.0;

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startFlight();
    });
  }

  void _startFlight() {
    setState(() => _gameState = GameState.flying);
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _timeInFlight += 0.05;
        _gridOffset += 0.05 * math.max(1.0, _multiplier / 5);
        
        // Multiplier growth: 1.0 + exponential curve
        // Slightly faster growth over time
        _multiplier = 1.0 + (math.pow(_timeInFlight, 1.5) * 0.05);
        if (_multiplier < 1.0) _multiplier = 1.0;
        
        // Auto-cashout logic
        if (_autoCashout1 && _isBetPlaced && _cashoutMultiplier == null && _multiplier >= _autoCashoutThreshold1) {
          _onCashOut();
        }
        if (_autoCashout2 && _isBetPlaced2 && _cashoutMultiplier2 == null && _multiplier >= _autoCashoutThreshold2) {
          _onCashOut2();
        }

        // Simulate other players cashing out
        for (var bet in _liveBets) {
          if (bet['cashout'] == null && _random.nextDouble() < 0.02 && _multiplier > 1.2) {
            bet['cashout'] = _multiplier;
          }
        }

        if (_multiplier >= _crashPoint) {
          timer.cancel();
          _crash();
        }
      });
    });
  }

  void _crash() {
    _exitController.forward(from: 0.0);
    setState(() {
      _gameState = GameState.crashed;
      _history.insert(0, double.parse(_multiplier.toStringAsFixed(2)));
      if (_history.length > 10) _history.removeLast();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _exitController.reset();
        _startBettingCycle();
      }
    });
  }

  void _onBetPressed() {
    if (_gameState == GameState.betting && !_isBetPlaced && _userBalance >= _betAmount) {
      setState(() {
        _isBetPlaced = true;
        _userBalance -= _betAmount;
      });
    }
  }

  void _onBetPressed2() {
    if (_gameState == GameState.betting && !_isBetPlaced2 && _userBalance >= _betAmount2) {
      setState(() {
        _isBetPlaced2 = true;
        _userBalance -= _betAmount2;
      });
    }
  }

  void _onCashOut() {
    if (_gameState == GameState.flying && _isBetPlaced && _cashoutMultiplier == null) {
      setState(() {
        _cashoutMultiplier = _multiplier;
        _userBalance += _betAmount * _multiplier;
      });
    }
  }

  void _onCashOut2() {
    if (_gameState == GameState.flying && _isBetPlaced2 && _cashoutMultiplier2 == null) {
      setState(() {
        _cashoutMultiplier2 = _multiplier;
        _userBalance += _betAmount2 * _multiplier;
      });
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _planeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AVIATOR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NeonColors.primary.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '${_userBalance.toStringAsFixed(2)} USD',
                style: const TextStyle(color: NeonColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // History Bar
          _buildHistoryBar(),
          
          // Game Graph
          Expanded(
            flex: 3,
            child: _buildGameGraph(),
          ),
          
          // Selection Tabs
          _buildTabs(),

          // Live Bets Feed
          Expanded(
            flex: 2,
            child: _buildLiveBetsFeed(),
          ),

          // Betting Panel
          _buildBettingPanel(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 30,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: ['All Bets', 'My Bets', 'Top'].map((tab) => Expanded(
          child: Center(
            child: Text(
              tab,
              style: TextStyle(
                color: tab == 'All Bets' ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLiveBetsFeed() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _liveBets.length,
        itemBuilder: (context, index) {
          final bet = _liveBets[index];
          final isCashedOut = bet['cashout'] != null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, size: 10, color: Colors.white24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bet['name'],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                Text(
                  '${bet['bet'].toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCashedOut ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isCashedOut ? Border.all(color: Colors.green.withValues(alpha: 0.3)) : null,
                  ),
                  child: Center(
                    child: Text(
                      isCashedOut ? '${bet['cashout'].toStringAsFixed(2)}x' : '-',
                      style: TextStyle(color: isCashedOut ? Colors.greenAccent : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final val = _history[index];
          final color = val < 2.0 ? Colors.blueAccent : (val < 10.0 ? Colors.purpleAccent : Colors.pinkAccent);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '${val}x',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameGraph() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // The Curve
            Positioned.fill(
              child: CustomPaint(
                painter: AviatorPainter(
                  progress: _gameState == GameState.flying ? math.min(_timeInFlight / 10.0, 1.0) : 0.0,
                  multiplier: _multiplier,
                  isCrashed: _gameState == GameState.crashed,
                  gridOffset: _gridOffset,
                ),
              ),
            ),
            
            // The Multiplier Text
            Center(
              child: _gameState == GameState.betting 
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('WAITING FOR NEXT ROUND', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('$_bettingCountdown', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    ],
                  )
                : _gameState == GameState.waiting
                  ? const Text('READY TO FLY', style: TextStyle(color: NeonColors.primary, fontSize: 24, fontWeight: FontWeight.bold))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            '${_multiplier.toStringAsFixed(2)}x',
                            style: TextStyle(
                              color: _gameState == GameState.crashed ? Colors.red : Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                if (_gameState != GameState.crashed)
                                  Shadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 20 + _multiplier),
                              ],
                            ),
                          ),
                        ),
                        if (_gameState == GameState.crashed)
                          const Text('FLEW AWAY!', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
            
            // The Plane
            if (_gameState == GameState.flying || _gameState == GameState.crashed)
              Positioned(
                left: math.min(_timeInFlight / 10.0, 1.0) * (MediaQuery.of(context).size.width - 64) - 20,
                bottom: (math.pow(math.min(_timeInFlight / 10.0, 1.0), 2) * (MediaQuery.of(context).size.height * 0.3) * 0.8) + 10,
                child: SlideTransition(
                  position: _exitAnimation,
                  child: RotationTransition(
                    turns: const AlwaysStoppedAnimation(0 / 360),
                    child: Image.asset('assets/airplane_sprite.png', width: 40),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBettingPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildSingleBetPanel(1),
          const SizedBox(width: 8),
          _buildSingleBetPanel(2),
        ],
      ),
    );
  }

  Widget _buildSingleBetPanel(int panelId) {
    bool isPanel1 = panelId == 1;
    double amount = isPanel1 ? _betAmount : _betAmount2;
    bool isPlaced = isPanel1 ? _isBetPlaced : _isBetPlaced2;
    double? cashout = isPanel1 ? _cashoutMultiplier : _cashoutMultiplier2;
    
    bool isFlying = _gameState == GameState.flying;
    bool canCashout = isFlying && isPlaced && cashout == null;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            if (isPlaced && cashout == null)
              BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAmountBtn('-', () {
                  if (amount > 10) {
                    setState(() => isPanel1 ? _betAmount -= 10 : _betAmount2 -= 10);
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(amount.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                _buildAmountBtn('+', () {
                  setState(() => isPanel1 ? _betAmount += 10 : _betAmount2 += 10);
                }),
              ],
            ),
            const SizedBox(height: 8),
            // Quick amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [100, 200, 500].map((val) => GestureDetector(
                onTap: () => setState(() => isPanel1 ? _betAmount = val.toDouble() : _betAmount2 = val.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                  child: Text('\$$val', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 8),
            // Auto Bet & Auto Cashout Toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Auto Bet', style: TextStyle(color: Colors.white70, fontSize: 10)),
                SizedBox(
                  height: 20,
                  child: Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: isPanel1 ? _autoBet1 : _autoBet2,
                      onChanged: (val) => setState(() => isPanel1 ? _autoBet1 = val : _autoBet2 = val),
                      activeTrackColor: NeonColors.primary.withValues(alpha: 0.5),
                      activeThumbColor: NeonColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Auto Cashout', style: TextStyle(color: Colors.white70, fontSize: 10)),
                SizedBox(
                  height: 20,
                  child: Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: isPanel1 ? _autoCashout1 : _autoCashout2,
                      onChanged: (val) => setState(() => isPanel1 ? _autoCashout1 = val : _autoCashout2 = val),
                      activeTrackColor: Colors.greenAccent.withValues(alpha: 0.5),
                      activeThumbColor: Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ),
            if (isPanel1 ? _autoCashout1 : _autoCashout2)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAmountBtn('-', () {
                     setState(() => isPanel1 
                        ? (_autoCashoutThreshold1 = math.max(1.1, _autoCashoutThreshold1 - 0.1))
                        : (_autoCashoutThreshold2 = math.max(1.1, _autoCashoutThreshold2 - 0.1)));
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('${(isPanel1 ? _autoCashoutThreshold1 : _autoCashoutThreshold2).toStringAsFixed(1)}x', 
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  _buildAmountBtn('+', () {
                    setState(() => isPanel1 
                        ? (_autoCashoutThreshold1 += 0.1)
                        : (_autoCashoutThreshold2 += 0.1));
                  }),
                ],
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cashout != null 
                      ? Colors.grey.withValues(alpha: 0.3)
                      : (canCashout ? Colors.orange : (isPlaced ? Colors.red : Colors.green)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: isPlaced ? 8 : 0,
                  padding: EdgeInsets.zero,
                ),
                onPressed: isFlying 
                    ? (canCashout ? (isPanel1 ? _onCashOut : _onCashOut2) : null) 
                    : (isPlaced ? null : (isPanel1 ? _onBetPressed : _onBetPressed2)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      canCashout ? 'CASHOUT' : (isPlaced ? (isFlying ? 'FLYING' : 'WAITING') : 'BET'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: canCashout ? 14 : 16),
                    ),
                    if (canCashout)
                      Text((_multiplier * amount).toStringAsFixed(2), style: const TextStyle(fontSize: 10)),
                    if (cashout != null)
                      Text('+${(cashout * amount).toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAmountBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}
