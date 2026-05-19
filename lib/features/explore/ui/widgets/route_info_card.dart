import 'package:flutter/material.dart';

import '../../../../core/theme/kashta_colors.dart';

const Color _routePrimary = Color(0xFFD97845);
const Color _routeTextSecondary = Color(0xFF7A6A5B);

class RouteInfoCard extends StatelessWidget {
  const RouteInfoCard({
    super.key,
    required this.isFetchingRoute,
    required this.routeDistanceText,
    required this.routeDurationText,
  });

  final bool isFetchingRoute;
  final String? routeDistanceText;
  final String? routeDurationText;

  @override
  Widget build(BuildContext context) {
    if (!isFetchingRoute &&
        (routeDistanceText == null || routeDurationText == null)) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KashtaColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x148A5A2B),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: isFetchingRoute
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: _routePrimary,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading route...',
                      style: TextStyle(
                        color: _routeTextSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Distance: $routeDistanceText',
                      style: const TextStyle(
                        color: KashtaColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimated time: $routeDurationText',
                      style: const TextStyle(
                        color: _routeTextSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
