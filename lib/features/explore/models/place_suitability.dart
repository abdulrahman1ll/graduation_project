import '../../../core/utils/localization.dart';

enum PlaceSuitability {
  families('families'),
  youth('youth'),
  both('both');

  const PlaceSuitability(this.value);

  final String value;

  static PlaceSuitability? fromValue(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    for (final suitability in PlaceSuitability.values) {
      if (suitability.value == raw) {
        return suitability;
      }
    }
    return null;
  }

  String label(Tr tr) {
    switch (this) {
      case PlaceSuitability.families:
        return tr.t('suitable_families');
      case PlaceSuitability.youth:
        return tr.t('suitable_youth');
      case PlaceSuitability.both:
        return tr.t('suitable_both');
    }
  }
}
