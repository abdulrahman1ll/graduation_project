import 'package:flutter/material.dart';

import '../theme/kashta_colors.dart';
import '../utils/localization.dart';

PreferredSizeWidget appBarWithLanguage({
  required Tr tr,
  required bool isArabic,
  required String title,
  required VoidCallback onToggleLanguage,
  List<Widget> actions = const <Widget>[],
}) {
  return AppBar(
    title: Text(title),
    actions: [
      ...actions,
      TextButton(
        onPressed: onToggleLanguage,
        child: Text(
          isArabic ? 'EN' : 'AR',
          style: const TextStyle(
            color: KashtaColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
