import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip_member.dart';

class TripService {
  TripService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<TripMember>> watchTripMembers(String tripId) {
    // ignore: avoid_print
    print('Reading members from trip.members');

    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('members')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TripMember.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(growable: false),
        );
  }

  Stream<TripMember?> watchTripMember(String tripId, String userId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return TripMember.fromMap(
        snapshot.data() ?? const <String, dynamic>{},
        documentId: snapshot.id,
      );
    });
  }

  Future<void> updateAttendance(
    String tripId,
    String userId,
    String status,
  ) async {
    if (status != 'going' && status != 'not_going' && status != 'pending') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Invalid attendance status.',
      );
    }

    final memberRef = _firestore
        .collection('trips')
        .doc(tripId)
        .collection('members')
        .doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(memberRef);
      if (snapshot.exists) {
        transaction.update(memberRef, <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      transaction.set(memberRef, <String, dynamic>{
        'userId': userId,
        'status': status,
        'joinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String> createTrip({
    required String title,
    required String description,
    required String locationName,
    String? mapLink,
    required DateTime tripDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Authentication is required.',
      );
    }

    final docRef = await _firestore.collection('trips').add({
      'title': title,
      'description': description,
      'locationName': locationName,
      'mapLink': mapLink?.trim().isEmpty ?? true ? null : mapLink!.trim(),
      'tripDate': Timestamp.fromDate(tripDate),
      'groupId': null,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> syncGroupMembersToTrip({
    required String groupId,
    required String tripId,
  }) async {
    final groupSnapshot =
        await _firestore.collection('groups').doc(groupId).get();
    final groupData = groupSnapshot.data() ?? const <String, dynamic>{};
    final memberIds = (groupData['members'] as List<dynamic>?)
            ?.map((member) => member.toString().trim())
            .where((memberId) => memberId.isNotEmpty)
            .toSet()
            .toList(growable: false) ??
        const <String>[];

    for (var index = 0; index < memberIds.length; index += 450) {
      final batch = _firestore.batch();
      final chunk = memberIds.skip(index).take(450);
      for (final userId in chunk) {
        final memberRef = _firestore
            .collection('trips')
            .doc(tripId)
            .collection('members')
            .doc(userId);
        batch.set(memberRef, <String, dynamic>{
          'userId': userId,
          'status': 'pending',
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
