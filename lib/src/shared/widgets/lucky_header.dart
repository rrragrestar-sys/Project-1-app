import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

class NeonHeader extends StatelessWidget implements PreferredSizeWidget {
  final double balance;
  const NeonHeader({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: NeonColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: NeonColors.primary),
        onPressed: () {},
      ),
      title: Text(
        'NEON NOIR',
        style: GoogleFonts.outfit(
          color: NeonColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: NeonColors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: NeonColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.file_upload_outlined, color: NeonColors.textSub, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
