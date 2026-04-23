import 'package:flutter/material.dart';

class ReelWidget extends StatefulWidget {
  final List<String> symbols;
  final List<String> result;
  final bool isSpinning;
  final Duration spinDuration;
  final double itemHeight;
  final Widget Function(String symbol, bool isBlurred) symbolBuilder;

  const ReelWidget({
    super.key,
    required this.symbols,
    required this.result,
    required this.isSpinning,
    this.spinDuration = const Duration(seconds: 2),
    this.itemHeight = 80.0,
    required this.symbolBuilder,
  });

  @override
  State<ReelWidget> createState() => _ReelWidgetState();
}

class _ReelWidgetState extends State<ReelWidget> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late List<String> _displaySymbols;
  late int _repeatCount;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _repeatCount = 20; // Number of sets of symbols to show during spin
    _displaySymbols = _buildDisplaySymbols();
  }

  List<String> _buildDisplaySymbols() {
    List<String> list = [];
    // Current state symbols
    list.addAll(widget.result);
    // Add many random symbols for the spin effect
    for (int i = 0; i < _repeatCount; i++) {
      list.addAll(widget.symbols..shuffle());
    }
    // Result symbols at the end
    list.addAll(widget.result);
    return list;
  }

  @override
  void didUpdateWidget(ReelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpin();
    }
  }

  void _startSpin() {
    _displaySymbols = _buildDisplaySymbols();
    _scrollController.jumpTo(0);
    
    final targetOffset = (_displaySymbols.length - widget.result.length) * widget.itemHeight;
    
    _scrollController.animateTo(
      targetOffset,
      duration: widget.spinDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemHeight * widget.result.length,
      child: ListView.builder(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _displaySymbols.length,
        itemBuilder: (context, index) {
          return SizedBox(
            height: widget.itemHeight,
            child: widget.symbolBuilder(
              _displaySymbols[index],
              widget.isSpinning,
            ),
          );
        },
      ),
    );
  }
}
