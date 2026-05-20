import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaceService {
  PlaceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> addPlace({
    required String name,
    String? description,
    required String environmentType,
    required double latitude,
    required double longitude,
    String? imageBase64,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Authentication is required.',
      );
    }

    final trimmedDescription = description?.trim() ?? '';
    final placeData = <String, dynamic>{
      'name': name.trim(),
      'environmentType': environmentType,
      'lat': latitude,
      'lng': longitude,
      'imageBase64': imageBase64,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    if (trimmedDescription.isNotEmpty) {
      placeData['description'] = trimmedDescription;
    }

    await _firestore.collection('places').add(placeData);
  }

  Future<void> approvePlace({
    required String placeId,
    required String suitableFor,
  }) async {
    final normalizedSuitableFor = suitableFor.trim().toLowerCase();
    if (normalizedSuitableFor != 'families' &&
        normalizedSuitableFor != 'youth' &&
        normalizedSuitableFor != 'both') {
      throw ArgumentError.value(suitableFor, 'suitableFor');
    }

    await _firestore.collection('places').doc(placeId).update({
      'status': 'approved',
      'suitableFor': normalizedSuitableFor,
    });
  }

  Future<void> rejectPlace(String placeId) async {
    await _firestore.collection('places').doc(placeId).update({
      'status': 'rejected',
    });
  }

  Future<void> deletePlace(String placeId) async {
    final placeRef = _firestore.collection('places').doc(placeId);
    final reviewsSnapshot = await placeRef.collection('reviews').get();
    var batch = _firestore.batch();
    var operationCount = 0;

    for (final review in reviewsSnapshot.docs) {
      batch.delete(review.reference);
      operationCount++;

      if (operationCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }

    batch.delete(placeRef);
    await batch.commit();
  }

  Future<void> deleteReview({
    required String placeId,
    required String reviewId,
  }) async {
    await _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }
}
