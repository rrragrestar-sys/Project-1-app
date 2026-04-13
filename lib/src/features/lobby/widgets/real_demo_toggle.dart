import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class RealDemoToggle extends StatefulWidget {
  const RealDemoToggle({super.key});

  @override
  State<RealDemoToggle> createState() => _RealDemoToggleState();
}

class _RealDemoToggleState extends State<RealDemoToggle> {
  bool isReal = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: NeonColors.grey,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption('REAL', isReal),
          _buildOption('DEMO', !isReal),
        ],
      ),
    );
  }

  Widget _buildOption(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => isReal = label == 'REAL'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? NeonColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: NeonColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.black : NeonColors.textSub,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
