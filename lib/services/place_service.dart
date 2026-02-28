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

    await _firestore.collection('places').add({
      'name': name.trim(),
      'environmentType': environmentType,
      'lat': latitude,
      'lng': longitude,
      'imageBase64': imageBase64,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> approvePlace(String placeId) async {
    await _firestore.collection('places').doc(placeId).update({
      'status': 'approved',
    });
  }

  Future<void> rejectPlace(String placeId) async {
    await _firestore.collection('places').doc(placeId).update({
      'status': 'rejected',
    });
  }
}
