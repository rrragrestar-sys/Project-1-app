import 'package:flutter/material.dart';
import '../models/slot_engine.dart';


class SlotReelWidget extends StatefulWidget {
  final List<SlotSymbol> symbols;
  final SlotSymbol resultSymbol;
  final bool isSpinning;
  final Duration delay;
  final VoidCallback onFinished;

  const SlotReelWidget({
    super.key,
    required this.symbols,
    required this.resultSymbol,
    required this.isSpinning,
    this.delay = Duration.zero,
    required this.onFinished,
  });

  @override
  State<SlotReelWidget> createState() => _SlotReelWidgetState();
}

class _SlotReelWidgetState extends State<SlotReelWidget> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  final double _itemHeight = 100.0;
  final int _extraItems = 30; // Number of items to scroll through
  late List<SlotSymbol> _reelItems;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _generateReelItems();
  }

  void _generateReelItems() {
    // Lead symbols + random filler + result symbol + tail icons
    final random = List.generate(_extraItems, (_) => widget.symbols[0]); // Simple filler
    _reelItems = [
      ...widget.symbols, // Initial view
      ...random,
      widget.resultSymbol,
      ...widget.symbols.take(2), // Buffer after result
    ];
  }

  @override
  void didUpdateWidget(SlotReelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpin();
    }
  }

  Future<void> _startSpin() async {
    _scrollController.jumpTo(0);
    await Future.delayed(widget.delay);
    
    if (!mounted) return;

    final targetOffset = (_reelItems.length - 3) * _itemHeight;
    
    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(seconds: 3),
      curve: Curves.elasticOut,
    );
    
    widget.onFinished();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: _itemHeight * 3,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reelItems.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: _itemHeight,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        _reelItems[index].imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.diamond,
                          color: _getSymbolColor(_reelItems[index].id),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Glass overlay for current row indicator
            Center(
              child: Container(
                height: _itemHeight,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Colors.yellowAccent.withValues(alpha: 0.3), width: 2),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSymbolColor(String id) {
    switch (id) {
      case 'gem_red': return Colors.red;
      case 'gem_blue': return Colors.blue;
      case 'gem_green': return Colors.green;
      case 'wild': return Colors.orange;
      default: return Colors.white;
    }
  }
}
