part of 'app_shell.dart';

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
  bool _showOnlyFavorites = false;
  String? _selectedCategoryChip;
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUserLocation();
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
          (leg['distance'] as Map<String, dynamic>?)?['text'] as String? ??
          '';
      final durationText =
          (leg['duration'] as Map<String, dynamic>?)?['text'] as String? ??
          '';
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
    
    int selectedRating = 0;
    final commentController = TextEditingController();
    Uint8List? selectedImageBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                Future<void> pickImage() async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image == null) return;

                  final bytes = await image.readAsBytes();

                  setModalState(() {
                    selectedImageBytes = bytes;
                  });
                }

                return SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ===== PLACE TITLE =====
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text("Environment: ${data['environmentType'] ?? '-'}"),

                      

                      const SizedBox(height: 8),

FutureBuilder<Map<String, dynamic>?>(
  future: _weatherService.getWeather(
    (data['lat'] as num).toDouble(),
    (data['lng'] as num).toDouble(),
  ),
  builder: (context, snapshot) {
    debugPrint("PLACE DATA:");
debugPrint(data.toString());

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text("Loading weather...");
    }

    if (!snapshot.hasData) {
      return const Text("Weather unavailable");
    }

    final temp = snapshot.data!["temp"];
final weather = snapshot.data!["weather"];
final wind = snapshot.data!["wind"];

String kashtaCondition = "Good";

if (weather == "Rain" || wind > 8) {
  kashtaCondition = "Bad";
}

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Row(
      children: [
        const Icon(Icons.thermostat, color: Colors.orange),
        const SizedBox(width: 6),
        Text("${temp.toStringAsFixed(1)} °C"),
      ],
    ),

    Row(
      children: [
        const Icon(Icons.cloud, color: Colors.grey),
        const SizedBox(width: 6),
        Text("Weather: $weather"),
      ],
    ),

    Row(
      children: [
        const Icon(Icons.air, color: Colors.blue),
        const SizedBox(width: 6),
        Text("Wind: $wind m/s"),
      ],
    ),

    Row(
      children: [
        const Icon(Icons.emoji_nature, color: Colors.green),
        const SizedBox(width: 6),
        Text("Kashta conditions: $kashtaCondition"),
      ],
    ),

  ],
);
  },
),
                      const SizedBox(height: 20),

                      /// ===== RATING =====
                      const Text(
                        "Rate this place",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              setModalState(() {
                                selectedRating = index + 1;
                              });
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 10),

                      /// ===== COMMENT =====
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Write your comment...",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ===== IMAGE PICKER =====
                      ElevatedButton(
                        onPressed: pickImage,
                        child: const Text("Add Image (Optional)"),
                      ),

                      if (selectedImageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.memory(selectedImageBytes!, height: 120),
                        ),

                      const SizedBox(height: 15),

                      /// ===== SUBMIT REVIEW =====
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedRating == 0) return;

                          final navigator = Navigator.of(context);
                          await FirebaseFirestore.instance
                              .collection('places')
                              .doc(placeId)
                              .collection('reviews')
                              .add({
                                'userId':
                                    FirebaseAuth.instance.currentUser?.uid,
                                'rating': selectedRating,
                                'comment': commentController.text.trim(),
                                'imageBase64': selectedImageBytes == null
                                    ? null
                                    : base64Encode(selectedImageBytes!),
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                          navigator.pop();
                        },
                        child: const Text("Submit Review"),
                      ),

                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 10),

                      /// ===== REVIEWS + PHOTOS =====
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('places')
                            .doc(placeId)
                            .collection('reviews')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final reviews = snapshot.data!.docs;

                          double avgRating = 0;
                          if (reviews.isNotEmpty) {
                            final total = reviews.fold<double>(
                              0,
                              (total, doc) =>
                                  total +
                                  ((doc.data()
                                          as Map<String, dynamic>)['rating'] ??
                                      0),
                            );
                            avgRating = total / reviews.length;
                          }

                          if (reviews.isEmpty) {
                            return const Text("No reviews yet.");
                          }

                          /// ===== COLLECT IMAGES =====
                          final images = reviews
                              .map(
                                (doc) =>
                                    (doc.data()
                                        as Map<String, dynamic>)['imageBase64'],
                              )
                              .where((e) => e != null && e != '')
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Average rating: ${avgRating.toStringAsFixed(1)} ⭐",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              /// ===== PHOTOS SECTION =====
                              if (images.isNotEmpty) ...[
                                const Text(
                                  "Photos",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 6,
                                        mainAxisSpacing: 6,
                                      ),
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    final img = images[index];

                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            child: InteractiveViewer(
                                              child: Image.memory(
                                                base64Decode(img),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(img),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),
                              ],

                              /// ===== REVIEWS =====
                              const Text(
                                "Reviews",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              ...reviews.map((doc) {
                                final review =
                                    doc.data() as Map<String, dynamic>;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(
                                            review['rating'] ?? 0,
                                            (index) => const Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(review['comment'] ?? ''),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  LatLng? selectedPoint;
  final PlaceService _placeService = PlaceService();
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
    final nameController = TextEditingController();
    String environmentType = 'desert';
    Uint8List? selectedImageBytes;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image == null) {
                return;
              }
              final bytes = await image.readAsBytes();
              setModalState(() {
                selectedImageBytes = bytes;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add New Place'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Place Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: environmentType,
                    items: const [
                      DropdownMenuItem(value: 'desert', child: Text('Desert')),
                      DropdownMenuItem(value: 'nature', child: Text('Nature')),
                      DropdownMenuItem(value: 'beach', child: Text('Beach')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() {
                        environmentType = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Environment Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: pickImage,
                    child: const Text('Pick Image (Optional)'),
                  ),
                  const SizedBox(height: 10),
                  if (selectedImageBytes != null)
                    Image.memory(selectedImageBytes!, height: 120),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
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
                          name: nameController.text.trim(),
                          environmentType: environmentType,
                          latitude: lat,
                          longitude: lng,
                          imageBase64: selectedImageBytes == null
                              ? null
                              : base64Encode(selectedImageBytes!),
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
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
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
                  final approvedMarkers = visibleDocs.map((doc) {
                    final data = doc.data();
                    final lat = (data['lat'] as num?)?.toDouble();
                    final lng = (data['lng'] as num?)?.toDouble();
                    if (lat == null || lng == null) {
                      return null;
                    }
                    return Marker(
                      markerId: MarkerId(doc.id),
                      position: LatLng(lat, lng),
                      onTap: () {
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
                  }).whereType<Marker>().toSet();

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
                      Positioned(
                        right: 50,
                        bottom: 50,
                        child: FloatingActionButton(
                          heroTag: 'recenter_user_location_button',
                          mini: true,
                          onPressed: _recenterOnUserLocation,
                          child: const Icon(Icons.my_location),
                        ),
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


