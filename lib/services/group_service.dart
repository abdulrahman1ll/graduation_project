import 'package:firebase_auth/firebase_auth.dart';

import '../chat/services/group_service.dart' as chat;

class GroupService {
  GroupService({
    FirebaseAuth? auth,
    chat.GroupService? delegate,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _delegate = delegate ?? chat.GroupService(auth: auth);

  final FirebaseAuth _auth;
  final chat.GroupService _delegate;

  Future<String> createGroup({
    required String tripId,
    required String name,
    required String description,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Authentication is required.',
      );
    }

    return _delegate.createGroup(
      tripId,
      name,
      description,
      user.uid,
      imageUrl,
    );
  }
}
