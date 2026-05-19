import 'package:flutter/material.dart';

import '../core/theme/kashta_colors.dart';

class KashtaBackground extends StatelessWidget {
  const KashtaBackground({
    super.key,
    required this.child,
    this.overlayColor = KashtaColors.backgroundCream,
    this.overlayOpacity = 0.35,
  });

  final Widget child;
  final Color overlayColor;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/orr.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: overlayColor.withValues(alpha: overlayOpacity),
          ),
        ),
        child,
      ],
    );
  }
}
