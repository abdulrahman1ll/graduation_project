import 'package:geolocator/geolocator.dart';

class SafetyLocationService {
  Future<String> currentLocationLink() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const SafetyLocationException(
        'Location services are disabled. Enable location and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const SafetyLocationException(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const SafetyLocationException(
        'Location permission denied. Please allow location access and try again.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final latitude = position.latitude.toStringAsFixed(6);
    final longitude = position.longitude.toStringAsFixed(6);
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }
}

class SafetyLocationException implements Exception {
  const SafetyLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
