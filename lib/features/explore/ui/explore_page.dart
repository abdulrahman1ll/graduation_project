import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/ai_recommendation_service.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';
import '../../../widgets/kashta_background.dart';
import '../models/recommended_place.dart';
import '../services/place_service.dart';
import '../services/weather_service.dart';
import 'widgets/add_place_sheet.dart';
import 'widgets/place_details_sheet.dart';
import 'widgets/route_info_card.dart';

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

class _ExplorePageState extends State<ExplorePage> {
  bool _showRecommendations = true;

  int _recommendationRefreshKey = 0;

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
  String? _selectedPlaceType;
  String? _preferredPlaceType;
  String? _temperaturePreference;
  String? _activityPreference;

  final AiRecommendationService _aiRecommendationService =
      AiRecommendationService();

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

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final prefs = data['preferences'] as Map<String, dynamic>?;

    print("FULL USER DATA: $data");
    print("PREFS MAP: $prefs");

    setState(() {
      _preferredPlaceType = prefs?['placeType']?.toString();
      _distancePreference = prefs?['distancePreference']?.toString();
      _temperaturePreference = prefs?['temperaturePreference']?.toString();
      _activityPreference = prefs?['activityPreference']?.toString();
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
    final clickCounts = <String, int>{};
    final positivelyRatedPlaceIds = <String>{};
    final lowRatedPlaceIds = <String>{};

    final interactions = await getUserInteractions();
    for (final i in interactions) {
      final placeId = i['placeId'];
      if (placeId == null) continue;

      if (i['type'] == 'click') {
        clickCounts[placeId] = (clickCounts[placeId] ?? 0) + 1;
      }

      final ratingValue = (i['rating'] as num?)?.toDouble();
      if (i['type'] == 'rating' && ratingValue != null) {
        if (ratingValue <= 2) {
          lowRatedPlaceIds.add(placeId);
        } else if (ratingValue >= 4) {
          positivelyRatedPlaceIds.add(placeId);
        }
      }
    }

    for (final doc in docs) {
      final data = doc.data();
      final placeEnvironmentType =
          data['environmentType']?.toString().toLowerCase() ?? '';
      final matchesPreferredType = placeEnvironmentType == userPref;
      final clickCount = clickCounts[doc.id] ?? 0;
      final hasLowRating = lowRatedPlaceIds.contains(doc.id);
      final hasPositiveRating = positivelyRatedPlaceIds.contains(doc.id);
      final hasStrongInteraction = clickCount >= 2 || hasPositiveRating == true;

      if (hasLowRating) continue;
      if (!matchesPreferredType && !hasStrongInteraction) continue;

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
      // if (distancePref == 'near' && distanceKm > 20) continue;
      // if (distancePref == 'far' && distanceKm < 20) continue;

      final avgRating = await _getAverageRatingForPlace(doc.id);

      results.add(
        RecommendedPlace(
          doc: doc,
          averageRating: avgRating,
          distanceKm: distanceKm,
        ),
      );
    }

    final predictedScores = <String, double>{};

    final seenPlaceIds = <String>{};

    for (final item in results) {
      if (seenPlaceIds.contains(item.doc.id)) continue;
      seenPlaceIds.add(item.doc.id);

      final placeData = item.doc.data() as Map<String, dynamic>;

      final placeEnvironmentType =
          placeData['environmentType']?.toString().toLowerCase() ?? 'desert';

      final distanceKm = (item.distanceKm);
      final placeDistanceBucket =
          distanceKm <= 10 ? 'near' : (distanceKm <= 25 ? 'medium' : 'far');

      final placeAverageRating = item.averageRating;
      final placeRatingCount =
          ((placeData['ratingCount'] as num?)?.toInt()) ?? 0;

      final userClickCountForPlace = clickCounts[item.doc.id] ?? 0;

      print('RECOMMENDED PLACE -> ${placeData['name']} | ${item.doc.id}');
      print(
          'CLICK COUNT -> ${placeData['name']} | ${item.doc.id}: $userClickCountForPlace');
      print(
          'AVG RATING -> ${placeData['name']} | ${item.doc.id}: $placeAverageRating');

      final predicted = await _aiRecommendationService.predictRating(
        preferredPlaceType: _preferredPlaceType?.toLowerCase() ?? 'desert',
        distancePreference: _distancePreference?.toLowerCase() ?? 'near',
        temperaturePreference: _temperaturePreference?.toLowerCase() ?? 'cool',
        placeEnvironmentType: placeEnvironmentType,
        placeDistanceBucket: placeDistanceBucket,
        placeAverageRating: placeAverageRating,
        placeRatingCount: placeRatingCount,
        userClickCountForPlace: userClickCountForPlace,
      );

      final matchesPreference = placeEnvironmentType == userPref;
      final finalOrderingValue =
          '(${matchesPreference ? 1 : 0}, ${predicted ?? 'null'}, $placeAverageRating)';

      print('''
DEBUG PLACE
NAME: ${placeData['name']}
ID: ${item.doc.id}
USER preferredPlaceType: ${_preferredPlaceType?.toLowerCase() ?? 'desert'}
USER distancePreference: ${_distancePreference?.toLowerCase() ?? 'near'}
USER temperaturePreference: ${_temperaturePreference?.toLowerCase() ?? 'cool'}
PLACE environmentType: $placeEnvironmentType
PLACE distanceBucket: $placeDistanceBucket
PLACE averageRating: $placeAverageRating
PLACE ratingCount: $placeRatingCount
USER clickCountForPlace: $userClickCountForPlace
MATCHES_PREFERENCE: $matchesPreference
RAW_AI_SCORE: ${predicted ?? 'null'}
FINAL_ORDERING_VALUE: $finalOrderingValue
''');

      if (predicted != null) {
        predictedScores[item.doc.id] = predicted;
        print('AI SCORE -> ${placeData['name']} | ${item.doc.id}: $predicted');
      } else {
        print('AI SCORE -> ${item.doc.id}: null');
      }
    }

    results.sort((a, b) {
      final aEnvironmentType =
          a.doc.data()['environmentType']?.toString().toLowerCase() ?? '';
      final bEnvironmentType =
          b.doc.data()['environmentType']?.toString().toLowerCase() ?? '';
      final aMatchesPreference = aEnvironmentType == userPref;
      final bMatchesPreference = bEnvironmentType == userPref;

      if (aMatchesPreference != bMatchesPreference) {
        return bMatchesPreference ? 1 : -1;
      }

      final aPred = predictedScores[a.doc.id];
      final bPred = predictedScores[b.doc.id];

      if (aPred != null && bPred != null && aPred != bPred) {
        return bPred.compareTo(aPred);
      }

      return b.averageRating.compareTo(a.averageRating);
    });

    print('FINAL ORDER AFTER SORT:');
    for (final item in results) {
      final placeData = item.doc.data() as Map<String, dynamic>;
      final rawAiScore = predictedScores[item.doc.id];
      final placeEnvironmentType =
          placeData['environmentType']?.toString().toLowerCase() ?? '';
      final matchesPreference = placeEnvironmentType == userPref;
      final finalOrderingValue =
          '(${matchesPreference ? 1 : 0}, ${rawAiScore ?? 'null'}, ${item.averageRating})';
      print(
        'PLACE -> ${placeData['name']} | RAW AI SCORE -> $rawAiScore | MATCHES PREFERENCE -> $matchesPreference | FINAL ORDERING VALUE -> $finalOrderingValue | RATING -> ${item.averageRating}',
      );
    }

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
      final encodedPolyline = (route['overview_polyline']
              as Map<String, dynamic>?)?['points'] as String? ??
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
        tr: widget.tr,
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

          if (mounted) {
            setState(() {
              _recommendationRefreshKey++;
            });
          }

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

    print(
        'userId,placeType,distancePreference,temperaturePreference,activityPreference,placeId,type,rating');

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
    return KashtaBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildExploreHeader(),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6F421D).withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: StreamBuilder<Set<String>>(
                      stream: _favoritePlaceIdsStream(),
                      builder: (context, favoritesSnapshot) {
                        if (favoritesSnapshot.hasError) {
                          logFirestoreReadError(
                            'users/*/favorites',
                            favoritesSnapshot.error,
                          );
                        }

                        final favoriteIds =
                            favoritesSnapshot.data ?? <String>{};

                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('places')
                              .where('status', isEqualTo: 'approved')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              logFirestoreReadError('places', snapshot.error);
                            }

                            final docs = snapshot.data?.docs ?? [];

                            final visibleDocs = docs.where((doc) {
                              final data = doc.data();
                              final environmentType = data['environmentType']
                                  ?.toString()
                                  .toLowerCase();
                              final matchesPlaceType =
                                  _selectedPlaceType == null ||
                                      environmentType == _selectedPlaceType;
                              final matchesFavorite = !_showOnlyFavorites ||
                                  favoriteIds.contains(doc.id);

                              return matchesPlaceType && matchesFavorite;
                            }).toList();

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
                                      print(
                                          'MARKER CLICKED -> ${data['name']} | ${doc.id}');
                                      await _saveInteraction(
                                        placeId: doc.id,
                                        type: 'click',
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _recommendationRefreshKey++;
                                        });
                                      }

                                      fetchRoute(
                                        destinationLatitude: lat,
                                        destinationLongitude: lng,
                                      );
                                      _showPlaceDetails(data, doc.id);
                                    },
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
                                  infoWindow:
                                      const InfoWindow(title: 'Your Location'),
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
                                  zoomControlsEnabled: false,
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
                                    _openAddPlaceForm(
                                        point.latitude, point.longitude);
                                  },
                                  markers: allMarkers,
                                  polylines: _routePolylines,
                                ),
                                RouteInfoCard(
                                  isFetchingRoute: _isFetchingRoute,
                                  routeDistanceText: _routeDistanceText,
                                  routeDurationText: _routeDurationText,
                                ),
                                _buildMapZoomControls(),
                                FutureBuilder<List<RecommendedPlace>>(
                                  key: ValueKey(_recommendationRefreshKey),
                                  future: _buildRecommendedPlaces(visibleDocs),
                                  builder: (context, recommendationSnapshot) {
                                    if (!recommendationSnapshot.hasData ||
                                        recommendationSnapshot.data!.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    final recommendedPlaces =
                                        recommendationSnapshot.data!;

                                    if (!_showRecommendations) {
                                      return Positioned(
                                        bottom: 18,
                                        right: 18,
                                        child: FloatingActionButton(
                                          mini: true,
                                          backgroundColor:
                                              const Color(0xFF8B4A23),
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          onPressed: () {
                                            setState(() {
                                              _showRecommendations = true;
                                            });
                                          },
                                          child: const Icon(Icons.auto_awesome),
                                        ),
                                      );
                                    }

                                    return Stack(
                                      children: [
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 292,
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              14,
                                              16,
                                              16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFFFFFBF5)
                                                      .withValues(alpha: 0.92),
                                                  const Color(0xFFFFFBF5)
                                                      .withValues(alpha: 0.74),
                                                  const Color(0xFFFFFBF5)
                                                      .withValues(alpha: 0.18),
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(28),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF3B2415)
                                                      .withValues(alpha: 0.10),
                                                  blurRadius: 22,
                                                  offset: const Offset(0, -8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF8B4A23)
                                                            .withValues(
                                                                alpha: 0.11),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .auto_awesome_rounded,
                                                        color:
                                                            Color(0xFF8B4A23),
                                                        size: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    const Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Recommended for you',
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xFF2F2118),
                                                              fontSize: 17,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            'Based on your preferences',
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xFF7B6653),
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    padding: EdgeInsets.zero,
                                                    itemCount: recommendedPlaces
                                                        .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final item =
                                                          recommendedPlaces[
                                                              index];
                                                      final place =
                                                          item.doc.data();

                                                      return GestureDetector(
                                                        onTap: () {
                                                          final lat =
                                                              (place['lat']
                                                                      as num)
                                                                  .toDouble();
                                                          final lng =
                                                              (place['lng']
                                                                      as num)
                                                                  .toDouble();

                                                          fetchRoute(
                                                            destinationLatitude:
                                                                lat,
                                                            destinationLongitude:
                                                                lng,
                                                          );

                                                          _showPlaceDetails(
                                                            place,
                                                            item.doc.id,
                                                          );
                                                        },
                                                        child:
                                                            _buildRecommendationCard(
                                                          place: place,
                                                          item: item,
                                                          rank: index + 1,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 222,
                                          right: 12,
                                          child: IconButton(
                                            icon:
                                                const Icon(Icons.close_rounded),
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFFFFBF5)
                                                      .withValues(alpha: 0.86),
                                              foregroundColor:
                                                  const Color(0xFF5B3922),
                                              elevation: 2,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _showRecommendations = false;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.tr.t('explore'),
                  textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF2F2118),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: widget.onToggleLanguage,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B4A23),
                  backgroundColor:
                      const Color(0xFFFFFBF5).withValues(alpha: 0.74),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                child: Text(
                  widget.isArabic ? 'EN' : 'AR',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.tr.t('exploreSubtitle'),
            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: const Color(0xFF7B6653).withValues(alpha: 0.94),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildExploreSearchPill(),
          _buildPlaceTypeFilterBar(),
        ],
      ),
    );
  }

  Widget _buildPlaceTypeFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      child: SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildPlaceTypeChip(
              label: widget.tr.t('all'),
              icon: Icons.public_rounded,
              value: null,
            ),
            const SizedBox(width: 8),
            _buildPlaceTypeChip(
              label: widget.tr.t('desert'),
              icon: Icons.local_florist_rounded,
              value: 'desert',
            ),
            const SizedBox(width: 8),
            _buildPlaceTypeChip(
              label: widget.tr.t('beach'),
              icon: Icons.waves_rounded,
              value: 'beach',
            ),
            const SizedBox(width: 8),
            _buildPlaceTypeChip(
              label: widget.tr.t('nature'),
              icon: Icons.park_rounded,
              value: 'nature',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceTypeChip({
    required String label,
    required IconData icon,
    required String? value,
  }) {
    final isSelected = _selectedPlaceType == value;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedPlaceType = isSelected ? null : value;
        });
      },
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : const Color(0xFF7A6656),
      ),
      label: Text(label),
      selectedColor: const Color(0xFF8B4A23),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF8B4A23)
            : Colors.white.withValues(alpha: 0.50),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF5B3922),
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
      ),
    );
  }

  Widget _buildExploreSearchPill() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF2).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.64)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F421D).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF6D482B),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.tr.t('exploreSearchHint'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF5B3922).withValues(alpha: 0.78),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: const Color(0xFFE3C9A8),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.tune_rounded,
            color: Color(0xFF6D482B),
            size: 25,
          ),
        ],
      ),
    );
  }

  Widget _buildMapZoomControls() {
    return Positioned(
      top: 18,
      left: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B2415).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mapZoomButton(
              icon: Icons.add_rounded,
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomIn());
              },
            ),
            Container(
              width: 30,
              height: 1,
              color: const Color(0xFFE6CFB2),
            ),
            _mapZoomButton(
              icon: Icons.remove_rounded,
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomOut());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: const Color(0xFF5B3922),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 42, height: 40),
      splashRadius: 22,
    );
  }

  Widget _buildRecommendationCard({
    required Map<String, dynamic> place,
    required RecommendedPlace item,
    required int rank,
  }) {
    final environmentType = place['environmentType']?.toString() ?? '';
    final imageProvider = _placeImageProvider(place['imageBase64']?.toString());

    return Container(
      width: 224,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F421D).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(21),
            ),
            child: SizedBox(
              height: 82,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageProvider != null)
                    Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    )
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFE8C29A),
                            Color(0xFFD8A06A),
                            Color(0xFFC98A55),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4A23),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2F2118),
                      fontSize: 15,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2E4CF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          environmentType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6D482B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFD8A06A),
                        size: 17,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF3C2A1D),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF8B6A52),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${item.distanceKm.toStringAsFixed(1)} km away',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF75604C),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _placeImageProvider(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return null;
    }

    try {
      return MemoryImage(base64Decode(imageBase64));
    } catch (_) {
      return null;
    }
  }
}
