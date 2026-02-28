import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  GroupService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> createGroup({
    required String name,
    required String description,
    required String visibility,
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
        message: 'Group visibility must be public or private.',
      );
    }

    final userSnap = await _firestore.collection('users').doc(user.uid).get();
    final roles = userSnap.data()?['roles'] as Map<String, dynamic>? ?? {};
    final isOrganizer = roles['groupOrganizer'] == true;
    final isAdmin = roles['admin'] == true;
    if (!isOrganizer && !isAdmin) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Only group organizers or admins can create groups.',
      );
    }

    await _firestore.collection('groups').add({
      'name': name,
      'description': description,
      'visibility': visibility,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
