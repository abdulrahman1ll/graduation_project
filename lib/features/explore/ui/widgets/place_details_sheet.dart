import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/app_language.dart';
import '../../../../core/theme/kashta_colors.dart';
import '../../../../core/utils/localization.dart';
import '../../models/place_suitability.dart';
import '../../../profile/services/favorite_service.dart';

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
  final FavoriteService _favoriteService = FavoriteService();

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

  String _localizedSuitabilityValue(Object? value) {
    final suitability = PlaceSuitability.fromValue(value);
    return suitability?.label(widget.tr) ?? widget.tr.t('not_specified');
  }

  IconData _suitabilityIcon(Object? value) {
    switch (PlaceSuitability.fromValue(value)) {
      case PlaceSuitability.families:
        return Icons.family_restroom_rounded;
      case PlaceSuitability.youth:
        return Icons.person_rounded;
      case PlaceSuitability.both:
        return Icons.groups_rounded;
      case null:
        return Icons.help_outline_rounded;
    }
  }

  String _localizedWeatherMain(Object? value) {
    final raw = (value ?? '').toString().trim();
    if (widget.tr.language != AppLanguage.ar) {
      return raw;
    }

    switch (raw.toLowerCase()) {
      case 'clear':
        return '\u0635\u0627\u0641\u064a';
      case 'clouds':
        return '\u063a\u0627\u0626\u0645';
      case 'rain':
        return '\u0645\u0645\u0637\u0631';
      case 'thunderstorm':
        return '\u0639\u0627\u0635\u0641\u0629 \u0631\u0639\u062f\u064a\u0629';
      case 'drizzle':
        return '\u0631\u0630\u0627\u0630';
      case 'snow':
        return '\u062b\u0644\u062c';
      case 'mist':
      case 'fog':
        return '\u0636\u0628\u0627\u0628';
      case 'haze':
        return '\u0636\u0628\u0627\u0628 \u062e\u0641\u064a\u0641';
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
        return '\u062c\u064a\u062f\u0629';
      case 'moderate':
        return '\u0645\u062a\u0648\u0633\u0637\u0629';
      case 'bad':
      case 'poor':
        return '\u063a\u064a\u0631 \u0645\u0646\u0627\u0633\u0628\u0629';
      default:
        return raw;
    }
  }

  String get _placeDescription =>
      (widget.data['description'] ?? '').toString().trim();

  String _formattedWind(Object? value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return '-';
    }
    final unit = widget.tr.language == AppLanguage.ar ? '\u0645/\u062b' : 'm/s';
    return '$raw $unit';
  }

  _PlaceImageSource? _placeImageSource() {
    return _PlaceImageSource.fromPlaceData(widget.data);
  }

  _PlaceImageSource? _reviewImageSource(Object? imageBase64) {
    return _PlaceImageSource.fromValue(imageBase64);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.58,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return SingleChildScrollView(
          controller: controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlaceImageHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (widget.data['name'] ?? '').toString(),
                            style: const TextStyle(
                              color: KashtaColors.textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildFavoriteButton(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDescription(),
                    _buildInfoRow(
                      icon: Icons.terrain_rounded,
                      text: '${widget.tr.t('environmentLabel')}: '
                          '${_localizedEnvironmentValue(widget.data['environmentType'])}',
                    ),
                    const SizedBox(height: 8),
                    _buildSuitabilityChip(),
                    const SizedBox(height: 12),
                    _buildWeatherSummary(),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 22),
                    _buildReviewForm(),
                    const SizedBox(height: 25),
                    const Divider(),
                    const SizedBox(height: 10),
                    _buildReviewsSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescription() {
    final description = _placeDescription;
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: KashtaColors.textDark,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPlaceImageHeader() {
    final imageSource = _placeImageSource();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: imageSource == null
            ? _buildReviewFallbackHeaderImage()
            : imageSource.buildImage(fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return StreamBuilder<bool>(
      stream: _favoriteService.isFavoriteStream(widget.placeId),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return IconButton.filledTonal(
          tooltip: widget.tr.t('favorites'),
          onPressed: () => _toggleFavorite(),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
          color: isFavorite ? KashtaColors.primary : KashtaColors.textDark,
          style: IconButton.styleFrom(
            backgroundColor: KashtaColors.backgroundCream,
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite() async {
    try {
      await _favoriteService.toggleFavorite(
        placeId: widget.placeId,
        placeData: widget.data,
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.tr.t('operation_failed'))),
      );
    }
  }

  Widget _buildReviewFallbackHeaderImage() {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.reviewsStream,
      builder: (context, snapshot) {
        final reviewImageSource = _firstReviewImageSource(snapshot.data);
        if (reviewImageSource != null) {
          return reviewImageSource.buildImage(fit: BoxFit.cover);
        }

        return _buildImagePlaceholder(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  _PlaceImageSource? _firstReviewImageSource(QuerySnapshot? snapshot) {
    final docs = snapshot?.docs;
    if (docs == null) {
      return null;
    }

    for (final doc in docs) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        final source = _PlaceImageSource.fromPlaceData(data);
        if (source != null) {
          return source;
        }
      }
    }

    return null;
  }

  Widget _buildImagePlaceholder({bool isLoading = false}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KashtaColors.backgroundCream,
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: KashtaColors.primary)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image_not_supported_outlined,
                    color: KashtaColors.softOlive,
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.tr.t('no_image_available'),
                    style: const TextStyle(
                      color: KashtaColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWeatherSummary() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: widget.weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading weather...');
        }

        if (!snapshot.hasData) {
          return const Text('Weather unavailable');
        }

        final temp = snapshot.data!['temp'];
        final weather = snapshot.data!['weather'].toString().trim();
        final wind = snapshot.data!['wind'];
        final displayWeather = _localizedWeatherMain(weather);

        var kashtaCondition = 'Good';
        if (weather == 'Rain' || wind > 8) {
          kashtaCondition = 'Bad';
        }
        final displayKashtaCondition =
            _localizedKashtaCondition(kashtaCondition);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.thermostat,
              text: '${temp.toStringAsFixed(1)} \u00B0C',
              iconColor: KashtaColors.primary,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              icon: Icons.cloud,
              text: "${widget.tr.t('weatherLabel')}: $displayWeather",
              iconColor: KashtaColors.textDark,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              icon: Icons.air,
              text: "${widget.tr.t('windLabel')}: "
                  "${_formattedWind(wind)}",
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              icon: Icons.emoji_nature,
              text: "${widget.tr.t('kashtaConditions')}: "
                  "$displayKashtaCondition",
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildReviewsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.reviewsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final reviews = snapshot.data!.docs;
        var avgRating = 0.0;
        if (reviews.isNotEmpty) {
          final total = reviews.fold<double>(
            0,
            (total, doc) =>
                total +
                (((doc.data() as Map<String, dynamic>)['rating'] as num?)
                        ?.toDouble() ??
                    0),
          );
          avgRating = total / reviews.length;
        }

        final images = reviews
            .map((doc) => (doc.data() as Map<String, dynamic>)['imageBase64'])
            .where((image) => image != null && image.toString().isNotEmpty)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: KashtaColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.tr.t('averageRating')}: '
                  '${avgRating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageSource = _reviewImageSource(images[index]);
                  if (imageSource == null) {
                    return const SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: imageSource.buildImage(fit: BoxFit.contain),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageSource.buildImage(fit: BoxFit.cover),
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
            if (reviews.isEmpty)
              Text(widget.tr.t('no_reviews_yet'))
            else
              ...reviews.map((doc) {
                final review = doc.data() as Map<String, dynamic>;
                final rating = (review['rating'] as num?)?.toInt() ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            rating,
                            (index) => const Icon(
                              Icons.star,
                              color: KashtaColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text((review['comment'] ?? '').toString()),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color iconColor = KashtaColors.softOlive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 19),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: KashtaColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuitabilityChip() {
    final suitableFor = widget.data['suitableFor'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: KashtaColors.backgroundCream,
        border: Border.all(color: KashtaColors.sandBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _suitabilityIcon(suitableFor),
            size: 17,
            color: KashtaColors.softOlive,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${widget.tr.t('suitable_for_display_label')}: '
              '${_localizedSuitabilityValue(suitableFor)}',
              style: const TextStyle(
                color: KashtaColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlaceImageKind { network, memory }

class _PlaceImageSource {
  const _PlaceImageSource._({
    required this.kind,
    required this.value,
  });

  final _PlaceImageKind kind;
  final String value;

  static _PlaceImageSource? fromPlaceData(Map<String, dynamic> data) {
    final candidates = <Object?>[
      data['imageUrl'],
      data['photoUrl'],
      data['imageBase64'],
      if (data['imageUrls'] is Iterable)
        ...(data['imageUrls'] as Iterable).cast<Object?>(),
      data['image'],
      data['imagePath'],
    ];

    for (final candidate in candidates) {
      final source = fromValue(candidate);
      if (source != null) {
        return source;
      }
    }

    return null;
  }

  static _PlaceImageSource? fromValue(Object? value) {
    if (value is Blob) {
      return _PlaceImageSource._(
        kind: _PlaceImageKind.memory,
        value: base64Encode(value.bytes),
      );
    }

    if (value is Uint8List) {
      return _PlaceImageSource._(
        kind: _PlaceImageKind.memory,
        value: base64Encode(value),
      );
    }

    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _PlaceImageSource._(
        kind: _PlaceImageKind.network,
        value: raw,
      );
    }

    final base64Value = _stripDataUriPrefix(raw).replaceAll(
      RegExp(r'\s+'),
      '',
    );
    try {
      base64Decode(base64Value);
      return _PlaceImageSource._(
        kind: _PlaceImageKind.memory,
        value: base64Value,
      );
    } catch (_) {
      return null;
    }
  }

  static String _stripDataUriPrefix(String value) {
    final commaIndex = value.indexOf(',');
    final looksLikeDataUri = value.startsWith('data:image/') &&
        value
            .substring(0, commaIndex == -1 ? 0 : commaIndex)
            .contains('base64');
    if (!looksLikeDataUri || commaIndex == -1) {
      return value;
    }

    return value.substring(commaIndex + 1);
  }

  Widget buildImage({required BoxFit fit}) {
    switch (kind) {
      case _PlaceImageKind.network:
        return Image.network(
          value,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              const _PlaceImageFallback(),
        );
      case _PlaceImageKind.memory:
        return Image.memory(
          base64Decode(value),
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              const _PlaceImageFallback(),
        );
    }
  }
}

class _PlaceImageFallback extends StatelessWidget {
  const _PlaceImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: KashtaColors.backgroundCream),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: KashtaColors.softOlive,
          size: 34,
        ),
      ),
    );
  }
}
