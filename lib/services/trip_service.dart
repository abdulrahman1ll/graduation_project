import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  TripService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> createTrip({
    required String title,
    required String description,
    required int peopleCount,
    required String locationUrl,
    required DateTime tripDate,
    required String visibility,
    String? groupId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Authentication is required.',
      );
    }
    if (visibility != 'public' && visibility != 'private') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Trip visibility must be public or private.',
      );
    }

    final docRef = await _firestore.collection('trips').add({
      'title': title,
      'description': description,
      'peopleCount': peopleCount,
      'locationUrl': locationUrl,
      'tripDate': Timestamp.fromDate(tripDate),
      'visibility': visibility,
      'groupId': groupId?.trim().isEmpty ?? true ? null : groupId!.trim(),
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}
