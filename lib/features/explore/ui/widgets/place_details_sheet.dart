import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/app_language.dart';
import '../../../../core/theme/kashta_colors.dart';
import '../../../../core/utils/localization.dart';

class PlaceDetailsSheet extends StatefulWidget {
  const PlaceDetailsSheet({
    super.key,
    required this.tr,
    required this.data,
    required this.placeId,
    required this.weatherFuture,
    required this.reviewsStream,
    required this.onSubmitReview,
  });

  final Tr tr;
  final Map<String, dynamic> data;
  final String placeId;
  final Future<Map<String, dynamic>?> weatherFuture;
  final Stream<QuerySnapshot> reviewsStream;
  final Future<void> Function({
    required int rating,
    required String comment,
    required Uint8List? selectedImageBytes,
  }) onSubmitReview;

  @override
  State<PlaceDetailsSheet> createState() => _PlaceDetailsSheetState();
}

class _PlaceDetailsSheetState extends State<PlaceDetailsSheet> {
  final TextEditingController _commentController = TextEditingController();

  int _selectedRating = 0;
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _openInGoogleMaps() async {
    final latitude = (widget.data['lat'] as num?)?.toDouble();
    final longitude = (widget.data['lng'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place location is unavailable.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) {
        return;
      }

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  String _localizedEnvironmentValue(Object? value) {
    final raw = (value ?? '').toString().trim();
    switch (raw.toLowerCase()) {
      case 'desert':
        return widget.tr.t('desert');
      case 'beach':
        return widget.tr.t('beach');
      case 'nature':
        return widget.tr.t('nature');
      case 'family':
        return widget.tr.t('family');
      case 'quiet':
        return widget.tr.t('quiet');
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }

  String _localizedWeatherMain(Object? value) {
    final raw = (value ?? '').toString().trim();
    if (widget.tr.language != AppLanguage.ar) {
      return raw;
    }

    switch (raw.toLowerCase()) {
      case 'clear':
        return 'صافي';
      case 'clouds':
        return 'غائم';
      case 'rain':
        return 'ممطر';
      case 'thunderstorm':
        return 'عاصفة رعدية';
      case 'drizzle':
        return 'رذاذ';
      case 'snow':
        return 'ثلج';
      case 'mist':
      case 'fog':
        return 'ضباب';
      case 'haze':
        return 'ضباب خفيف';
      default:
        return raw;
    }
  }

  String _localizedKashtaCondition(Object? value) {
    final raw = (value ?? '').toString().trim();
    if (widget.tr.language != AppLanguage.ar) {
      return raw;
    }

    switch (raw.toLowerCase()) {
      case 'good':
        return 'جيدة';
      case 'moderate':
        return 'متوسطة';
      case 'bad':
      case 'poor':
        return 'غير مناسبة';
      default:
        return raw;
    }
  }

  String _formattedWind(Object? value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return '-';
    }
    final unit = widget.tr.language == AppLanguage.ar ? 'م/ث' : 'm/s';
    return '$raw $unit';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data['name'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.tr.t('environmentLabel')}: '
                '${_localizedEnvironmentValue(widget.data['environmentType'])}',
              ),
              const SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>?>(
                future: widget.weatherFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading weather...");
                  }

                  if (!snapshot.hasData) {
                    return const Text("Weather unavailable");
                  }

                  final temp = snapshot.data!["temp"];
                  final weather = snapshot.data!["weather"].toString().trim();
                  final wind = snapshot.data!["wind"];
                  final displayWeather = _localizedWeatherMain(weather);

                  String kashtaCondition = "Good";
                  if (weather == "Rain" || wind > 8) {
                    kashtaCondition = "Bad";
                  }
                  final displayKashtaCondition =
                      _localizedKashtaCondition(kashtaCondition);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.thermostat,
                            color: KashtaColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text('${temp.toStringAsFixed(1)} \u00B0C'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.cloud, color: KashtaColors.textDark),
                          const SizedBox(width: 6),
                          Text(
                            "${widget.tr.t('weatherLabel')}: $displayWeather",
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.air, color: KashtaColors.softOlive),
                          const SizedBox(width: 6),
                          Text(
                            "${widget.tr.t('windLabel')}: "
                            "${_formattedWind(wind)}",
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_nature,
                            color: KashtaColors.softOlive,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${widget.tr.t('kashtaConditions')}: "
                            "$displayKashtaCondition",
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openInGoogleMaps,
                  icon: const Icon(Icons.navigation_rounded),
                  label: Text(
                    widget.tr.t('openInGoogleMaps'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.tr.t('rateThisPlace'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: KashtaColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: widget.tr.t('writeYourComment'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text(
                  widget.tr.t('addImageOptional'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_selectedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.memory(_selectedImageBytes!, height: 120),
                ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedRating == 0) {
                    return;
                  }

                  await widget.onSubmitReview(
                    rating: _selectedRating,
                    comment: _commentController.text.trim(),
                    selectedImageBytes: _selectedImageBytes,
                  );
                },
                child: Text(
                  widget.tr.t('submitReview'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: widget.reviewsStream,
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
                          ((doc.data() as Map<String, dynamic>)['rating'] ?? 0),
                    );
                    avgRating = total / reviews.length;
                  }

                  if (reviews.isEmpty) {
                    return const Text("No reviews yet.");
                  }

                  final images = reviews
                      .map(
                        (doc) =>
                            (doc.data() as Map<String, dynamic>)['imageBase64'],
                      )
                      .where((e) => e != null && e != '')
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.tr.t('averageRating')}: '
                        '${avgRating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (images.isNotEmpty) ...[
                        Text(
                          widget.tr.t('photos'),
                          style: const TextStyle(
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
                      Text(
                        widget.tr.t('reviews'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...reviews.map((doc) {
                        final review = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    review['rating'] ?? 0,
                                    (index) => const Icon(
                                      Icons.star,
                                      color: KashtaColors.primary,
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
  }
}
