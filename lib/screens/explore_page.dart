import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../features/explore/ui/widgets/add_place_sheet.dart';
import '../features/explore/ui/widgets/place_details_sheet.dart';
import '../services/place_service.dart';
import '../services/weather_service.dart';
import '../utils/firestore_utils.dart';
import '../utils/localization.dart';
import '../widgets/language_app_bar.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class RecommendedPlace {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final double averageRating;
  final double distanceKm;

  RecommendedPlace({
    required this.doc,
    required this.averageRating,
    required this.distanceKm,
  });
}

class _ExplorePageState extends State<ExplorePage> {

  double _calculateDistanceKm({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
}) {
  return Geolocator.distanceBetween(
        startLat,
        startLng,
        endLat,
        endLng,
      ) /
      1000;
}

  bool _showOnlyFavorites = false;
  String? _selectedCategoryChip;
  String? _preferredPlaceType;

  final WeatherService _weatherService = WeatherService();

  static const String _directionsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBwKTf5-oHsyPHv_-qF1r3fbcDU9Nsm2yQ',
  );

  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _hasCenteredOnUserLocation = false;

  Set<Polyline> _routePolylines = <Polyline>{};
  String? _routeDistanceText;
  String? _routeDurationText;
  bool _isFetchingRoute = false;
  String? _distancePreference;

  LatLng? selectedPoint;
  final PlaceService _placeService = PlaceService();

  Future<void> _saveInteraction({
  required String placeId,
  required String type,
  double? rating,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  print("CLICK SAVED: $placeId");

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('interactions')
      .add({
    'placeId': placeId,
    'type': type,
    'rating': rating,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

  Future<void> _loadUserPreferences() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (!doc.exists) return;

  final data = doc.data() as Map<String, dynamic>;
  final prefs = data['preferences'] as Map<String, dynamic>?;

  print("FULL USER DATA: $data");
  print("PREFS MAP: $prefs");

  setState(() {
    _preferredPlaceType = prefs?['placeType']?.toString();
    _distancePreference = prefs?['distancePreference']?.toString();
  });

  print("PREFERRED PLACE TYPE: $_preferredPlaceType");
  print("DISTANCE PREFERENCE: $_distancePreference");
}

  Future<double> _getAverageRatingForPlace(String placeId) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) {
      return 0.0;
    }

    double total = 0;
    for (final doc in reviewsSnapshot.docs) {
      final data = doc.data();
      total += ((data['rating'] ?? 0) as num).toDouble();
    }

    return total / reviewsSnapshot.docs.length;
  }

  Future<List<RecommendedPlace>> _buildRecommendedPlaces(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) async {
  final userPref = _preferredPlaceType?.toLowerCase();
  final distancePref = _distancePreference?.toLowerCase();
  final userLocation = _userLocation;

  if (userPref == null || userLocation == null) return [];

  final results = <RecommendedPlace>[];

  for (final doc in docs) {
    final data = doc.data();

    final placeType = data['environmentType']?.toString().toLowerCase();
    if (placeType != userPref) continue;

    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;

    final distanceKm = _calculateDistanceKm(
      startLat: userLocation.latitude,
      startLng: userLocation.longitude,
      endLat: lat,
      endLng: lng,
    );

    // فلترة حسب near / far
    if (distancePref == 'near' && distanceKm > 20) continue;
    if (distancePref == 'far' && distanceKm < 20) continue;

    final avgRating = await _getAverageRatingForPlace(doc.id);

    results.add(
      RecommendedPlace(
        doc: doc,
        averageRating: avgRating,
        distanceKm: distanceKm,
      ),
    );
  }

  final topPlaces = await getMostClickedPlaces();

results.sort((a, b) {
  int aScore = topPlaces.contains(a.doc.id) ? 1 : 0;
  int bScore = topPlaces.contains(b.doc.id) ? 1 : 0;

  if (aScore != bScore) {
    return bScore.compareTo(aScore);
  }

  return b.averageRating.compareTo(a.averageRating);
});

  return results;
}

  @override
  void initState() {
    super.initState();
    _loadCurrentUserLocation();
    _loadUserPreferences();
    _testInteractions();
    exportInteractionsToConsole();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<Position> getCurrentUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission denied. Please allow location access to use this map feature.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _loadCurrentUserLocation() async {
    try {
      final position = await getCurrentUserLocation();
      if (!mounted) return;

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _centerCameraOnUserLocation();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _centerCameraOnUserLocation() {
    final controller = _mapController;
    final userLocation = _userLocation;
    if (_hasCenteredOnUserLocation ||
        controller == null ||
        userLocation == null) {
      return;
    }

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLocation, zoom: 15),
      ),
    );
    _hasCenteredOnUserLocation = true;
  }

  Future<void> _recenterOnUserLocation() async {
    if (_userLocation == null) {
      await _loadCurrentUserLocation();
    }

    final controller = _mapController;
    final userLocation = _userLocation;
    if (controller == null || userLocation == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLocation, zoom: 15),
      ),
    );
  }

  Future<void> fetchRoute({
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (_userLocation == null) {
      await _loadCurrentUserLocation();
    }

    final userLocation = _userLocation;
    if (userLocation == null) {
      return;
    }

    if (_directionsApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Maps API key is missing.')),
      );
      return;
    }

    setState(() {
      _isFetchingRoute = true;
    });

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${userLocation.latitude},${userLocation.longitude}'
        '&destination=$destinationLatitude,$destinationLongitude'
        '&mode=driving'
        '&key=$_directionsApiKey',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Unable to fetch route right now.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      if (status != 'OK') {
        throw Exception(data['error_message'] ?? 'No route found.');
      }

      final routes = data['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) {
        throw Exception('No route found.');
      }

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>? ?? [];
      if (legs.isEmpty) {
        throw Exception('Route details are unavailable.');
      }

      final leg = legs.first as Map<String, dynamic>;
      final distanceText =
          (leg['distance'] as Map<String, dynamic>?)?['text'] as String? ?? '';
      final durationText =
          (leg['duration'] as Map<String, dynamic>?)?['text'] as String? ?? '';
      final encodedPolyline =
          (route['overview_polyline'] as Map<String, dynamic>?)?['points']
              as String? ??
          '';

      if (encodedPolyline.isEmpty) {
        throw Exception('Route path is unavailable.');
      }

      final routePoints = _decodePolyline(encodedPolyline);
      if (routePoints.isEmpty) {
        throw Exception('Route path is unavailable.');
      }

      if (!mounted) return;
      setState(() {
        _routePolylines = <Polyline>{
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: Colors.orange,
            width: 5,
          ),
        };
        _routeDistanceText = distanceText;
        _routeDurationText = durationText;
        _isFetchingRoute = false;
      });

      await _fitRouteInCamera(
        origin: userLocation,
        destination: LatLng(destinationLatitude, destinationLongitude),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingRoute = false;
        _routePolylines = <Polyline>{};
        _routeDistanceText = null;
        _routeDurationText = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  Future<void> _fitRouteInCamera({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    double minLat = math.min(origin.latitude, destination.latitude);
    double maxLat = math.max(origin.latitude, destination.latitude);
    double minLng = math.min(origin.longitude, destination.longitude);
    double maxLng = math.max(origin.longitude, destination.longitude);

    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  void _showPlaceDetails(Map<String, dynamic> data, String placeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlaceDetailsSheet(
        data: data,
        placeId: placeId,
        weatherFuture: _weatherService.getWeather(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        ),
        reviewsStream: FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection('reviews')
            .snapshots(),
        onSubmitReview: ({
          required int rating,
          required String comment,
          required Uint8List? selectedImageBytes,
        }) async {
          final navigator = Navigator.of(context);
          await FirebaseFirestore.instance
              .collection('places')
              .doc(placeId)
              .collection('reviews')
              .add({
                'userId': FirebaseAuth.instance.currentUser?.uid,
                'rating': rating,
                'comment': comment,
                'imageBase64': selectedImageBytes == null
                    ? null
                    : base64Encode(selectedImageBytes),
                'createdAt': FieldValue.serverTimestamp(),
              });

          await _saveInteraction(
            placeId: placeId,
            type: 'rating',
            rating: rating.toDouble(),
          );

          navigator.pop();
        },
      ),
    );
  }

  Stream<Set<String>> _favoritePlaceIdsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(<String>{});
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  void _openAddPlaceForm(double lat, double lng) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AddPlaceSheet(
        onSubmit: ({
          required BuildContext sheetContext,
          required String name,
          required String environmentType,
          required Uint8List? selectedImageBytes,
        }) async {
          if (name.trim().isEmpty) {
            showFirestoreError(
              sheetContext,
              FirebaseException(
                plugin: 'cloud_firestore',
                code: 'invalid-argument',
                message: widget.tr.t('fill_all_fields'),
              ),
            );
            return;
          }

          try {
            await _placeService.addPlace(
              name: name.trim(),
              environmentType: environmentType,
              latitude: lat,
              longitude: lng,
              imageBase64: selectedImageBytes == null
                  ? null
                  : base64Encode(selectedImageBytes),
            );
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          } on FirebaseException catch (e) {
            if (sheetContext.mounted) {
              showFirestoreError(sheetContext, e);
            }
          } catch (_) {
            if (sheetContext.mounted) {
              showFirestoreError(
                sheetContext,
                FirebaseException(
                  plugin: 'cloud_firestore',
                  code: 'unknown',
                  message: widget.tr.t('save_failed'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getUserInteractions() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('interactions')
      .get();

  return snapshot.docs.map((doc) => doc.data()).toList();
}

Future<List<String>> getMostClickedPlaces() async {
  final interactions = await getUserInteractions();

  Map<String, int> counts = {};

  for (var i in interactions) {
    final placeId = i['placeId'];
    if (placeId != null) {
      counts[placeId] = (counts[placeId] ?? 0) + 1;
    }
  }

  // ترتيب حسب الأكثر ضغط
  var sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).toList();
}


Future<void> exportInteractionsToConsole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final prefsSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final prefsData = prefsSnap.data();
  final prefs = (prefsData?['preferences'] as Map<String, dynamic>?) ?? {};

  final interactionsSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('interactions')
      .get();

  print('userId,placeType,distancePreference,temperaturePreference,activityPreference,placeId,type,rating');

  for (final doc in interactionsSnap.docs) {
    final data = doc.data();

    final placeType = prefs['placeType'] ?? '';
    final distancePreference = prefs['distancePreference'] ?? '';
    final temperaturePreference = prefs['temperaturePreference'] ?? '';
    final activityPreference = prefs['activityPreference'] ?? '';
    final placeId = data['placeId'] ?? '';
    final type = data['type'] ?? '';
    final rating = data['rating'] ?? '';

    print(
      '${user.uid},'
      '$placeType,'
      '$distancePreference,'
      '$temperaturePreference,'
      '$activityPreference,'
      '$placeId,'
      '$type,'
      '$rating',
    );
  }
}

void _testInteractions() async {
    final topPlaces = await getMostClickedPlaces();
  print("TOP PLACES: $topPlaces");
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        appBarWithLanguage(
          tr: widget.tr,
          isArabic: widget.isArabic,
          title: widget.tr.t('explore'),
          onToggleLanguage: widget.onToggleLanguage,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  selected: _showOnlyFavorites,
                  onSelected: (_) {
                    setState(() {
                      _showOnlyFavorites = !_showOnlyFavorites;
                    });
                  },
                  avatar: Icon(
                    _showOnlyFavorites ? Icons.star : Icons.star_border,
                    size: 18,
                    color: _showOnlyFavorites ? Colors.orange : Colors.black54,
                  ),
                  label: Text(widget.tr.t('favorites')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _showOnlyFavorites
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelStyle: TextStyle(
                    color: _showOnlyFavorites ? Colors.orange : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedCategoryChip == 'desert',
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryChip = _selectedCategoryChip == 'desert'
                          ? null
                          : 'desert';
                    });
                  },
                  label: Text(widget.tr.t('desert')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _selectedCategoryChip == 'desert'
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedCategoryChip == 'desert'
                        ? Colors.orange
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedCategoryChip == 'beach',
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryChip = _selectedCategoryChip == 'beach'
                          ? null
                          : 'beach';
                    });
                  },
                  label: Text(widget.tr.t('beach')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _selectedCategoryChip == 'beach'
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedCategoryChip == 'beach'
                        ? Colors.orange
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedCategoryChip == 'family',
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryChip = _selectedCategoryChip == 'family'
                          ? null
                          : 'family';
                    });
                  },
                  label: Text(widget.tr.t('family')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _selectedCategoryChip == 'family'
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedCategoryChip == 'family'
                        ? Colors.orange
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: StreamBuilder<Set<String>>(
            stream: _favoritePlaceIdsStream(),
            builder: (context, favoritesSnapshot) {
              if (favoritesSnapshot.hasError) {
                logFirestoreReadError(
                  'users/*/favorites',
                  favoritesSnapshot.error,
                );
              }

              final favoriteIds = favoritesSnapshot.data ?? <String>{};

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    logFirestoreReadError('places', snapshot.error);
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final visibleDocs = _showOnlyFavorites
                      ? docs
                            .where((doc) => favoriteIds.contains(doc.id))
                            .toList()
                      : docs;

                  final approvedMarkers = visibleDocs
                      .map((doc) {
                        final data = doc.data();
                        final lat = (data['lat'] as num?)?.toDouble();
                        final lng = (data['lng'] as num?)?.toDouble();
                        if (lat == null || lng == null) {
                          return null;
                        }

                        return Marker(
                          markerId: MarkerId(doc.id),
                          position: LatLng(lat, lng),
                          onTap: () async {
  await _saveInteraction(
    placeId: doc.id,
    type: 'click',
  );

  fetchRoute(
    destinationLatitude: lat,
    destinationLongitude: lng,
  );
  _showPlaceDetails(data, doc.id);
}

,

                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        );
                        
                      })
                      .whereType<Marker>()
                      .toSet();

                  final allMarkers = <Marker>{
                    ...approvedMarkers,
                    if (_userLocation != null)
                      Marker(
                        markerId: const MarkerId('user_location'),
                        position: _userLocation!,
                        infoWindow: const InfoWindow(title: 'Your Location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),
                    if (selectedPoint != null)
                      Marker(
                        markerId: const MarkerId('selected_point'),
                        position: selectedPoint!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                      ),
                  };

                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(21.5433, 39.1728),
                          zoom: 12,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _centerCameraOnUserLocation();
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        zoomGesturesEnabled: true,
scrollGesturesEnabled: true,
                        onTap: (point) {
                          setState(() {
                            selectedPoint = point;
                          });
                          fetchRoute(
                            destinationLatitude: point.latitude,
                            destinationLongitude: point.longitude,
                          );
                          _openAddPlaceForm(point.latitude, point.longitude);
                        },
                        markers: allMarkers,
                        polylines: _routePolylines,
                      ),

                      if (_isFetchingRoute ||
                          (_routeDistanceText != null &&
                              _routeDurationText != null))
                        Positioned(
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
                              child: _isFetchingRoute
                                  ? const Text('Loading route...')
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Distance: $_routeDistanceText'),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Estimated time: $_routeDurationText',
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),



                      FutureBuilder<List<RecommendedPlace>>(
                        future: _buildRecommendedPlaces(docs),
                        builder: (context, recommendationSnapshot) {
                          if (!recommendationSnapshot.hasData ||
                              recommendationSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final recommendedPlaces =
                              recommendationSnapshot.data!;

                          return Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 150,
                              color: Colors.white,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: recommendedPlaces.length,
                                itemBuilder: (context, index) {
                                  final item = recommendedPlaces[index];
                                  final place = item.doc.data();

                                  return GestureDetector(
                                    onTap: () {
                                      final lat =
                                          (place['lat'] as num).toDouble();
                                      final lng =
                                          (place['lng'] as num).toDouble();

                                      fetchRoute(
                                        destinationLatitude: lat,
                                        destinationLongitude: lng,
                                      );

                                      _showPlaceDetails(place, item.doc.id);
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.all(8),
                                      child: Container(
                                        width: 160,
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place['name'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(place['environmentType'] ?? ''),
                                            const SizedBox(height: 8),
                                            Row(
  children: [
    const Icon(Icons.star, color: Colors.orange, size: 16),
    const SizedBox(width: 4),
    Text(item.averageRating.toStringAsFixed(1)),
  ],
),
const SizedBox(height: 6),
Row(
  children: [
    const Icon(Icons.place, size: 16, color: Colors.blue),
    const SizedBox(width: 4),
    Text("${item.distanceKm.toStringAsFixed(1)} km"),
  ],
),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}



