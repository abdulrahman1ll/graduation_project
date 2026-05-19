import 'package:flutter/material.dart';

import '../../../../core/theme/kashta_colors.dart';
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
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      child: SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            FilterChip(
              selected: showOnlyFavorites,
              onSelected: onFavoritesChanged,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              avatar: Icon(
                showOnlyFavorites ? Icons.star : Icons.star_border,
                size: 18,
                color: showOnlyFavorites
                    ? Colors.white
                    : KashtaColors.textDark,
              ),
              label: Text(tr.t('favorites')),
              selectedColor: KashtaColors.primary,
              side: BorderSide(
                color: showOnlyFavorites
                    ? KashtaColors.primary
                    : KashtaColors.sandBorder,
              ),
              backgroundColor: KashtaColors.cardSurface.withValues(alpha: 0.78),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelStyle: TextStyle(
                color: showOnlyFavorites
                    ? Colors.white
                    : KashtaColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: tr.t('desert'),
              icon: Icons.local_florist_rounded,
              isSelected: selectedCategoryChip == 'desert',
              onSelected: () => onCategorySelected(
                selectedCategoryChip == 'desert' ? null : 'desert',
              ),
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: tr.t('beach'),
              icon: Icons.waves_rounded,
              isSelected: selectedCategoryChip == 'beach',
              onSelected: () => onCategorySelected(
                selectedCategoryChip == 'beach' ? null : 'beach',
              ),
            ),
            const SizedBox(width: 8),
            _CategoryChip(
              label: tr.t('family'),
              icon: Icons.family_restroom_rounded,
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
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : KashtaColors.textDark,
      ),
      label: Text(label),
      selectedColor: KashtaColors.primary,
      side: BorderSide(
        color: isSelected
            ? KashtaColors.primary
            : KashtaColors.sandBorder,
      ),
      backgroundColor: KashtaColors.cardSurface.withValues(alpha: 0.78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : KashtaColors.textDark,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
