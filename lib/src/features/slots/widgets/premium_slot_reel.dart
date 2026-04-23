import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/slot_engine.dart';

class PremiumSlotReel extends StatefulWidget {
  final List<SlotSymbol> symbols;
  final SlotSymbol targetSymbol;
  final bool isSpinning;
  final Duration delay;
  final VoidCallback onFinished;

  const PremiumSlotReel({
    super.key,
    required this.symbols,
    required this.targetSymbol,
    required this.isSpinning,
    required this.delay,
    required this.onFinished,
  });

  @override
  State<PremiumSlotReel> createState() => _PremiumSlotReelState();
}

class _PremiumSlotReelState extends State<PremiumSlotReel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<SlotSymbol> _reelSymbols = [];
  
  @override
  void initState() {
    super.initState();
    _reelSymbols.addAll(List.generate(30, (index) => widget.symbols[index % widget.symbols.length]));
    
    _controller = AnimationController(vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleStop();
      }
    });
  }

  @override
  void didUpdateWidget(PremiumSlotReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpin();
    }
  }

  void _startSpin() async {
    await Future.delayed(widget.delay);
    if (!mounted) return;
    
    // Smooth start
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInQuad,
    );
    
    _controller.duration = const Duration(milliseconds: 1500);
    _controller.forward(from: 0);
  }

  void _handleStop() {
    // Clunk effect
    HapticFeedback.heavyImpact();
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  for (int i = 0; i < _reelSymbols.length; i++)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (i * 100.0) - (_animation.value * 2500.0) + 100,
                      child: _buildSymbol(_reelSymbols[i]),
                    ),
                  // Overlay the target at the end
                  if (!widget.isSpinning)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 100,
                      child: _buildSymbol(widget.targetSymbol),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSymbol(SlotSymbol symbol) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        symbol.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.white10,
          child: const Icon(Icons.help_outline, color: Colors.white24),
        ),
      ),
    );
  }
}
