import 'package:flutter/material.dart';

import '../utils/localization.dart';

PreferredSizeWidget appBarWithLanguage({
  required Tr tr,
  required bool isArabic,
  required String title,
  required VoidCallback onToggleLanguage,
}) {
  return AppBar(
    title: Text(title),
    actions: [
      TextButton(
        onPressed: onToggleLanguage,
        child: Text(
          isArabic ? 'EN' : 'AR',
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
