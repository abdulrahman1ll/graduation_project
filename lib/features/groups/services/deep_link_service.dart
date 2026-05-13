import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/localization.dart';
import 'invite_service.dart';
import '../ui/group_chat_page.dart';

class DeepLinkService {
  DeepLinkService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    InviteService? inviteService,
    GlobalKey<NavigatorState>? navigatorKey,
    this.trProvider,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _inviteService = inviteService ?? const InviteService(),
        navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final InviteService _inviteService;
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLinks _appLinks = AppLinks();
  Tr Function()? trProvider;

  StreamSubscription<Uri?>? _uriSubscription;
  bool _initialized = false;

  Future<void> init(BuildContext context) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (!context.mounted) {
        return;
      }
      if (initialUri != null) {
        await _handleUri(context, initialUri);
      }
    } catch (error) {
      debugPrint('DeepLinkService init error: $error');
    }

    _uriSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        final currentContext = navigatorKey.currentContext;
        if (currentContext == null || !currentContext.mounted) {
          return;
        }
        await _handleUri(currentContext, uri);
      },
      onError: (Object error) {
        debugPrint('DeepLinkService.uriLinkStream error: $error');
      },
    );
  }

  Future<void> _handleUri(BuildContext context, Uri uri) async {
    debugPrint('DeepLink received: $uri');

    final groupId = _extractGroupId(uri);
    if (groupId == null) {
      debugPrint('DeepLink ignored: missing groupId');
      return;
    }
    debugPrint('DeepLink groupId: $groupId');

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('DeepLink ignored: no signed in user');
      await _showMessageDialog(
        context: context,
        title: 'Sign in required',
        message: 'Please sign in to join this group.',
      );
      return;
    }

    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      final groupSnapshot = await groupRef.get();
      if (!groupSnapshot.exists) {
        debugPrint('Group not found');
        if (!context.mounted) {
          return;
        }
        await _showMessageDialog(
          context: context,
          title: 'Group not found',
          message: 'This invite link is no longer valid.',
        );
        return;
      }

      final memberSnapshot =
          await groupRef.collection('members').doc(user.uid).get();
      if (!memberSnapshot.exists) {
        final groupData = groupSnapshot.data() ?? const <String, dynamic>{};
        final tripId = (groupData['tripId'] ?? '').toString().trim();
        final batch = _firestore.batch();
        batch.set(
            groupRef.collection('members').doc(user.uid), <String, dynamic>{
          'userId': user.uid,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
        });
        batch.update(groupRef, <String, dynamic>{
          'members': FieldValue.arrayUnion(<String>[user.uid]),
        });
        if (tripId.isNotEmpty) {
          final tripRef = _firestore.collection('trips').doc(tripId);
          batch.set(
            tripRef,
            <String, dynamic>{
              'memberIds': FieldValue.arrayUnion(<String>[user.uid]),
            },
            SetOptions(merge: true),
          );
          batch.set(
            tripRef.collection('members').doc(user.uid),
            <String, dynamic>{
              'userId': user.uid,
              'status': 'pending',
              'joinedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        await batch.commit();
        debugPrint('DeepLink member created for ${user.uid}');
      } else {
        debugPrint('DeepLink member already exists for ${user.uid}');
      }

      debugPrint('join success: $groupId');
      if (!context.mounted) {
        return;
      }
      final tr = trProvider?.call();
      if (tr == null) {
        debugPrint('DeepLink ignored: missing localization provider');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GroupChatPage(groupId: groupId, tr: tr),
        ),
      );
    } catch (error) {
      debugPrint('DeepLink join error: $error');
      if (!context.mounted) {
        return;
      }
      await _showMessageDialog(
        context: context,
        title: 'Unable to join group',
        message: 'Something went wrong while opening this invite.',
      );
    }
  }

  Future<void> dispose() async {
    await _uriSubscription?.cancel();
    _uriSubscription = null;
    _initialized = false;
  }

  String? _extractGroupId(Uri uri) {
    final asString = uri.toString();
    final extracted = _inviteService.extractGroupId(asString);
    if (extracted != null) {
      return extracted;
    }

    final isFallbackInvite = uri.scheme == 'app' && uri.host == 'join';
    final isWebInvite = uri.scheme == 'https' &&
        uri.host == 'kashta.app' &&
        uri.path == '/join';
    if (!isFallbackInvite && !isWebInvite) {
      return null;
    }

    final groupId = uri.queryParameters['groupId']?.trim();
    if (groupId == null || groupId.isEmpty) {
      return null;
    }
    return groupId;
  }

  Future<void> _showMessageDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
