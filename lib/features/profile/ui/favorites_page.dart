import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/localization.dart';
import '../../../core/widgets/language_app_bar.dart';
import '../../../widgets/kashta_background.dart';
import '../services/favorite_service.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
    required this.onOpenPlace,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;
  final void Function({
    required String placeId,
    required double lat,
    required double lng,
    required bool openDetailsOnLoad,
  }) onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final favoriteService = FavoriteService();

    return Scaffold(
      appBar: appBarWithLanguage(
        tr: tr,
        isArabic: isArabic,
        title: tr.t('favorites'),
        onToggleLanguage: onToggleLanguage,
      ),
      body: KashtaBackground(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: favoriteService.favoritesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(tr.t('operation_failed')));
            }

            final favorites = snapshot.data?.docs ?? [];
            if (favorites.isEmpty) {
              return Center(
                child: Text(
                  tr.t('no_favorite_places_yet'),
                  style: const TextStyle(
                    color: KashtaColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final doc = favorites[index];
                final data = doc.data();

                return _FavoritePlaceTile(
                  tr: tr,
                  placeId: doc.id,
                  data: data,
                  onOpenPlace: onOpenPlace,
                  onRemove: () => favoriteService.removeFavorite(doc.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FavoritePlaceTile extends StatelessWidget {
  const _FavoritePlaceTile({
    required this.tr,
    required this.placeId,
    required this.data,
    required this.onOpenPlace,
    required this.onRemove,
  });

  final Tr tr;
  final String placeId;
  final Map<String, dynamic> data;
  final void Function({
    required String placeId,
    required double lat,
    required double lng,
    required bool openDetailsOnLoad,
  }) onOpenPlace;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? tr.t('untitled_place')).toString();
    final environmentType = _localizedEnvironmentValue(
      data['environmentType'],
    );
    final averageRating = (data['averageRating'] as num?)?.toDouble();
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 64,
            height: 64,
            child: _FavoriteImage(data: data),
          ),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${tr.t('environmentLabel')}: $environmentType'),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: KashtaColors.primary,
                    size: 17,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    averageRating == null
                        ? '-'
                        : averageRating.toStringAsFixed(1),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite_rounded),
          color: KashtaColors.primary,
          onPressed: onRemove,
        ),
        onTap: lat == null || lng == null
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr.t('place_location_unavailable'))),
                );
              }
            : () => onOpenPlace(
                  placeId: placeId,
                  lat: lat,
                  lng: lng,
                  openDetailsOnLoad: true,
                ),
      ),
    );
  }

  String _localizedEnvironmentValue(Object? value) {
    final raw = (value ?? '').toString().trim();
    switch (raw.toLowerCase()) {
      case 'desert':
        return tr.t('desert');
      case 'beach':
        return tr.t('beach');
      case 'nature':
        return tr.t('nature');
      case 'family':
        return tr.t('family');
      case 'quiet':
        return tr.t('quiet');
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }
}

class _FavoriteImage extends StatelessWidget {
  const _FavoriteImage({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final source = _FavoriteImageSource.fromData(data);
    if (source == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: KashtaColors.backgroundCream),
        child: Icon(
          Icons.image_outlined,
          color: KashtaColors.softOlive,
        ),
      );
    }

    return source.build();
  }
}

enum _FavoriteImageKind { network, memory }

class _FavoriteImageSource {
  const _FavoriteImageSource._({
    required this.kind,
    required this.value,
  });

  final _FavoriteImageKind kind;
  final String value;

  static _FavoriteImageSource? fromData(Map<String, dynamic> data) {
    final candidates = <Object?>[
      data['imageUrl'],
      data['photoUrl'],
      data['imageBase64'],
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

  static _FavoriteImageSource? fromValue(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _FavoriteImageSource._(
        kind: _FavoriteImageKind.network,
        value: raw,
      );
    }

    final commaIndex = raw.indexOf(',');
    final base64Value = (raw.startsWith('data:image/') && commaIndex != -1)
        ? raw.substring(commaIndex + 1)
        : raw;
    final normalizedBase64 = base64Value.replaceAll(RegExp(r'\s+'), '');

    try {
      base64Decode(normalizedBase64);
      return _FavoriteImageSource._(
        kind: _FavoriteImageKind.memory,
        value: normalizedBase64,
      );
    } catch (_) {
      return null;
    }
  }

  Widget build() {
    switch (kind) {
      case _FavoriteImageKind.network:
        return Image.network(
          value,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined),
        );
      case _FavoriteImageKind.memory:
        return Image.memory(
          base64Decode(value),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined),
        );
    }
  }
}
