import 'package:flutter/material.dart';

import '../../../../core/utils/localization.dart';

class ExploreFilterBar extends StatelessWidget {
  const ExploreFilterBar({
    super.key,
    required this.tr,
    required this.showOnlyFavorites,
    required this.selectedCategoryChip,
    required this.onFavoritesChanged,
    required this.onCategorySelected,
  });

  final Tr tr;
  final bool showOnlyFavorites;
  final String? selectedCategoryChip;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            FilterChip(
              selected: showOnlyFavorites,
              onSelected: onFavoritesChanged,
              avatar: Icon(
                showOnlyFavorites ? Icons.star : Icons.star_border,
                size: 18,
                color: showOnlyFavorites ? Colors.orange : Colors.black54,
              ),
              label: Text(tr.t('favorites')),
              selectedColor: Colors.orange.withValues(alpha: 0.16),
              checkmarkColor: Colors.orange,
              side: BorderSide(
                color: showOnlyFavorites
                    ? Colors.orange
                    : Colors.orange.shade200,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              labelStyle: TextStyle(
                color: showOnlyFavorites ? Colors.orange : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: tr.t('desert'),
              isSelected: selectedCategoryChip == 'desert',
              onSelected: () => onCategorySelected(
                selectedCategoryChip == 'desert' ? null : 'desert',
              ),
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: tr.t('beach'),
              isSelected: selectedCategoryChip == 'beach',
              onSelected: () => onCategorySelected(
                selectedCategoryChip == 'beach' ? null : 'beach',
              ),
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: tr.t('family'),
              isSelected: selectedCategoryChip == 'family',
              onSelected: () => onCategorySelected(
                selectedCategoryChip == 'family' ? null : 'family',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      label: Text(label),
      selectedColor: Colors.orange.withValues(alpha: 0.16),
      checkmarkColor: Colors.orange,
      side: BorderSide(
        color: isSelected ? Colors.orange : Colors.orange.shade200,
      ),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
