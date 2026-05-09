import 'package:flutter/material.dart';

class KashtaBackground extends StatelessWidget {
  const KashtaBackground({
    super.key,
    required this.child,
    this.overlayColor = const Color(0xFFF8EFE2),
    this.overlayOpacity = 0.72,
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
            'assets/kas.png',
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
