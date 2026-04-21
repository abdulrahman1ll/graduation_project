import 'package:flutter/material.dart';

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
      child: Card(
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: isFetchingRoute
              ? const Text('Loading route...')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Distance: $routeDistanceText'),
                    const SizedBox(height: 4),
                    Text('Estimated time: $routeDurationText'),
                  ],
                ),
        ),
      ),
    );
  }
}
