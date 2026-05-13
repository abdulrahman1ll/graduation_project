import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'localization.dart';

void showFirestoreError(BuildContext context, FirebaseException e, {Tr? tr}) {
  String message;
  if (e.code == 'permission-denied') {
    message = tr?.t('firestore_permission_denied') ??
        'You do not have permission to perform this action.';
  } else if (e.code == 'unauthenticated') {
    message = tr?.t('firestore_unauthenticated') ?? 'Please sign in again.';
  } else if (e.code == 'invalid-argument') {
    message = e.message ??
        tr?.t('firestore_invalid_fields') ??
        'Some fields are invalid.';
  } else {
    message = tr?.t('firestore_generic_error') ??
        'Something went wrong. Please try again.';
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void logFirestoreReadError(String collection, Object? error) {
  if (!kDebugMode) {
    return;
  }
  if (error is FirebaseException) {
    debugPrint(
      'Firestore read error [$collection] code=${error.code} message=${error.message}',
    );
    final link = extractIndexLink(error.message);
    if (link != null) {
      debugPrint('Firestore index link [$collection]: $link');
    }
    return;
  }
  debugPrint('Firestore read error [$collection]: $error');
}

String? extractIndexLink(String? message) {
  if (message == null) {
    return null;
  }
  final match = RegExp(r'https://\S+').firstMatch(message);
  if (match == null) {
    return null;
  }
  return match.group(0);
}
