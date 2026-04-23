import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class BannerData {
  final String title;
  final String subtitle;
  final String label;
  final String imagePath;
  final String primaryButtonText;
  final Color accentColor;

  BannerData({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.imagePath,
    required this.primaryButtonText,
    required this.accentColor,
  });
}

class NeonCarousel extends StatefulWidget {
  const NeonCarousel({super.key});

  @override
  State<NeonCarousel> createState() => _NeonCarouselState();
}

class _NeonCarouselState extends State<NeonCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<BannerData> _banners = [
    BannerData(
      title: 'WELCOME\nBONUS',
      subtitle: 'Get 100% Match on your first deposit.\nLimited time offer for new kings!',
      label: 'EXCITING OFFER',
      imagePath: 'assets/banner_welcome.png',
      primaryButtonText: 'CLAIM NOW',
      accentColor: Colors.purpleAccent,
    ),
    BannerData(
      title: 'NEON\nMASTERS',
      subtitle: 'Join the high-stakes battle.\n250,000 Coins Prize Pool!',
      label: 'ACTIVE TOURNAMENT',
      imagePath: 'assets/banner.png',
      primaryButtonText: 'ENTER NOW',
      accentColor: Colors.cyan,
    ),
    BannerData(
      title: 'FORTUNE\nGEMS 3',
      subtitle: 'Discover hidden treasures and big wins.\nPlay the newest slot sensation!',
      label: 'NEW GAME',
      imagePath: 'assets/fortune_gems_3.png',
      primaryButtonText: 'PLAY NOW',
      accentColor: Colors.orangeAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220, // Increased height to prevent overflow
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _buildBannerCard(_banners[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildBannerCard(BannerData banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(banner.imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.9),
              Colors.black.withValues(alpha: 0.2),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: banner.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: banner.accentColor),
              ),
              child: Text(
                banner.label,
                style: TextStyle(
                  color: banner.accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              banner.title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              banner.subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildButton(banner.primaryButtonText, banner.accentColor, Colors.black),
                const SizedBox(width: 12),
                _buildButton('RULES', NeonColors.grey, Colors.white),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: bg != NeonColors.grey
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (index) {
        final isSelected = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isSelected ? 24 : 6,
          decoration: BoxDecoration(
            color: isSelected ? NeonColors.primary : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: NeonColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
