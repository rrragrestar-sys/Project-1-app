import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A high-fidelity Slot Machine Reel focusing on "Game Feel" and mechanical weight.
/// 
/// Features:
/// - EaseIn momentum build
/// - Linear high-speed spin
/// - ElasticOut "Mechanical Clunk" stop with overshoot
/// - Haptic feedback integration
class RealisticSlotReel extends StatefulWidget {
  final List<String> symbolImages;
  final int targetIndex;
  final bool isSpinning;
  final double itemHeight;
  final Duration duration;
  final VoidCallback? onFinished;

  const RealisticSlotReel({
    super.key,
    required this.symbolImages,
    required this.targetIndex,
    required this.isSpinning,
    this.itemHeight = 120.0,
    this.duration = const Duration(milliseconds: 3500),
    this.onFinished,
  });

  @override
  State<RealisticSlotReel> createState() => _RealisticSlotReelState();
}

class _RealisticSlotReelState extends State<RealisticSlotReel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _currentOffset = 0.0;
  int _lastTickIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    // We start at a static position
    _animation = AlwaysStoppedAnimation(widget.targetIndex * widget.itemHeight);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerHeavyHaptic();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void didUpdateWidget(RealisticSlotReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpin();
    }
  }

  void _startSpin() {
    // Calculate total distance to travel
    // We want at least 5-10 full rotations for that "blur" feel
    const int fullRotations = 8;
    final int totalSymbols = widget.symbolImages.length;
    final double distance = (fullRotations * totalSymbols * widget.itemHeight) + 
                           (widget.targetIndex * widget.itemHeight);

    // Create a multi-stage animation for better "weight"
    // Stage 1: EaseIn (0.0 -> 0.2)
    // Stage 2: Linear (0.2 -> 0.8)
    // Stage 3: ElasticOut (0.8 -> 1.0)
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: _currentOffset, end: distance * 0.2)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: distance * 0.2, end: distance * 0.8)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: distance * 0.8, end: distance)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.reset();
    _controller.forward();
  }

  void _triggerLightHaptic() {
    // STUB: Trigger light haptic for each symbol passing
    // HapticFeedback.lightImpact(); 
    debugPrint("Haptic: Click");
  }

  void _triggerHeavyHaptic() {
    // STUB: Trigger heavy haptic on final snap
    HapticFeedback.heavyImpact();
    debugPrint("Haptic: CLUNK");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.itemHeight * 0.8,
      height: widget.itemHeight * 3, // Show 3 items at a time
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            _currentOffset = _animation.value;
            
            // Trigger haptics based on symbol passing
            int currentIndex = (_currentOffset / widget.itemHeight).floor();
            if (currentIndex != _lastTickIndex) {
              _lastTickIndex = currentIndex;
              _triggerLightHaptic();
            }

            return Stack(
              children: _buildSymbols(),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSymbols() {
    final List<Widget> symbols = [];
    final int totalCount = widget.symbolImages.length;
    
    // We only need to render the symbols that are currently visible
    // Based on the current offset, we calculate which indices to show
    final double relativeOffset = _currentOffset % (totalCount * widget.itemHeight);
    
    // Render enough symbols to cover the view (at least 5 to handle overshoot)
    for (int i = -1; i < 5; i++) {
      final double yPos = (i * widget.itemHeight) - (relativeOffset % widget.itemHeight);
      final int symbolIndex = ((relativeOffset / widget.itemHeight).floor() + i) % totalCount;
      
      // Ensure index is positive
      final int safeIndex = (symbolIndex + totalCount) % totalCount;

      symbols.add(
        Positioned(
          top: yPos,
          left: 0,
          right: 0,
          height: widget.itemHeight,
          child: _buildSymbolItem(widget.symbolImages[safeIndex]),
        ),
      );
    }
    
    return symbols;
  }

  Widget _buildSymbolItem(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Center(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          // Placeholder for missing assets during development
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.star, 
            color: Colors.amber, 
            size: widget.itemHeight * 0.5
          ),
        ),
      ),
    );
  }
}
