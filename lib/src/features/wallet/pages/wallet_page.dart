import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/user_session.dart';
import '../../../core/services/wallet_service.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/liquid_background.dart';
import '../../../shared/widgets/shiny_button.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleDeposit() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    final success = await WalletService().depositFiat(amount);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deposited ₹$amount!'),
          backgroundColor: Colors.green,
        ),
      );
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MY WALLET',
          style: GoogleFonts.righteous(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Balance Card
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  
                  // Action Tabs
                  _buildTabs(),
                  const SizedBox(height: 24),

                  // Tab Views
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDepositView(),
                        _buildRedeemView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: NeonColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, _) {
        final session = UserSession();
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'TOTAL BALANCE',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    NumberFormat('#,##,###').format(session.balance),
                    style: GoogleFonts.righteous(
                      color: Colors.white,
                      fontSize: 36,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatter.format(session.fiatBalance),
                style: GoogleFonts.inter(
                  color: NeonColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: NeonColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonColors.primary.withValues(alpha: 0.3)),
        ),
        labelColor: NeonColors.primary,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: 'DEPOSIT'),
          Tab(text: 'REDEEM'),
        ],
      ),
    );
  }

  Widget _buildDepositView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT AMOUNT',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAmountInput(),
        const SizedBox(height: 20),
        _buildQuickSelect(),
        const SizedBox(height: 32),
        Center(
          child: ShinyButton(
            label: 'ADD CASH',
            width: double.infinity,
            onPressed: _handleDeposit,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Secure encrypted payments powered by SSL',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.righteous(color: Colors.white, fontSize: 24),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(color: Colors.white10),
          prefixText: '₹ ',
          prefixStyle: GoogleFonts.inter(color: NeonColors.primary, fontSize: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildQuickSelect() {
    final amounts = [100, 500, 1000, 5000];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: amounts.map((amt) {
        return GestureDetector(
          onTap: () => setState(() => _amountController.text = amt.toString()),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            borderRadius: 12,
            child: Text(
              '₹$amt',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRedeemView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(
            'REDEMPTION LOCKED',
            style: GoogleFonts.righteous(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Complete KYC and verify your bank account to enable withdrawals.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: const Text('START KYC VERIFICATION', style: TextStyle(color: NeonColors.primary)),
          ),
        ],
      ),
    );
  }
}
