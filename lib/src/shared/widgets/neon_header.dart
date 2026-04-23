import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/user_session.dart';

class NeonHeader extends StatelessWidget implements PreferredSizeWidget {
  const NeonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final coinFormat = NumberFormat('#,##,###');
    final fiatFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, _) {
        final session = UserSession();
        final balance = session.balance;
        final fiat = session.fiatBalance;

        return AppBar(
          backgroundColor: NeonColors.background,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: NeonColors.primary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            'LUCKY KING',
            style: GoogleFonts.righteous(
              color: Colors.amberAccent,
              fontSize: 22,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
          actions: [
            Tooltip(
              message: 'Approx. ${fiatFormat.format(fiat)}',
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: NeonColors.grey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: NeonColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      coinFormat.format(balance),
                      style: GoogleFonts.inter(
                        color: NeonColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.add_circle_outline_rounded, color: Colors.greenAccent, size: 18),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
