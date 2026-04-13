import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class GameCard extends StatelessWidget {
  final String title;
  final String provider;
  final String imageUrl;
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.title,
    required this.provider,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            provider.toUpperCase(),
            style: const TextStyle(color: NeonColors.textSub, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
