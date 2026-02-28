import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RoleProvider extends ChangeNotifier {
  RoleProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged);
    final current = _auth.currentUser;
    if (current != null) {
      _attachUserRolesListener(current.uid);
    }
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _rolesSub;

  Map<String, dynamic> _roles = const <String, dynamic>{};
  Map<String, dynamic> get roles => _roles;
  bool get isAdmin => _roles['admin'] == true;

  Future<void> _onAuthStateChanged(User? user) async {
    await _rolesSub?.cancel();
    _rolesSub = null;

    if (user == null) {
      if (kDebugMode) {
        debugPrint('CURRENT UID: ${_auth.currentUser?.uid}');
        debugPrint('CURRENT EMAIL: ${_auth.currentUser?.email}');
      }
      _roles = const <String, dynamic>{};
      notifyListeners();
      return;
    }

    if (kDebugMode) {
      debugPrint('CURRENT UID: ${user.uid}');
      debugPrint('CURRENT EMAIL: ${user.email}');
    }

    await user.getIdToken(true);
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get(
      const GetOptions(source: Source.server),
    );
    if (!userDoc.exists) {
      await userDocRef.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'roles': {
          'regularUser': true,
        },
      }, SetOptions(merge: true));
    }
    _attachUserRolesListener(user.uid);
  }

  void _attachUserRolesListener(String uid) {
    _rolesSub = _firestore.collection('users').doc(uid).snapshots().listen(
      (snap) {
        final data = snap.data() ?? const <String, dynamic>{};
        _roles = _parseRoles(data);
        if (kDebugMode) {
          debugPrint('SNAP EXISTS: ${snap.exists}');
          debugPrint('SNAP DATA: ${snap.data()}');
          debugPrint('FINAL PARSED ROLES: $_roles');
          debugPrint('IS ADMIN: ${_roles['admin'] == true}');
        }
        notifyListeners();
      },
      onError: (error, stack) {
        _roles = const <String, dynamic>{};
        if (kDebugMode) {
          debugPrint('FIRESTORE ERROR: $error');
          debugPrint('STACK TRACE: $stack');
        }
        notifyListeners();
      },
    );
  }

  Map<String, dynamic> _parseRoles(Map<String, dynamic> data) {
    final rawRoles = data['roles'];
    if (rawRoles is Map) {
      return rawRoles.map((key, value) => MapEntry(key.toString(), value));
    }

    const keys = <String>[
      'regularUser',
      'groupOrganizer',
      'contributor',
      'admin',
    ];

    final parsed = <String, dynamic>{};
    for (final key in keys) {
      final dotted = data['roles.$key'];
      final flat = data[key];
      if (dotted is bool) {
        parsed[key] = dotted;
      } else if (flat is bool) {
        parsed[key] = flat;
      }
    }
    return parsed;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _rolesSub?.cancel();
    super.dispose();
  }
}
