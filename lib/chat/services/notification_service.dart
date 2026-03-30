import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<String?> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return _messaging.getToken();
  }

  Future<void> subscribeToGroup(String groupId) {
    return _messaging.subscribeToTopic(topicForGroup(groupId));
  }

  Future<void> unsubscribeFromGroup(String groupId) {
    return _messaging.unsubscribeFromTopic(topicForGroup(groupId));
  }

  String topicForGroup(String groupId) {
    final safeGroupId = groupId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
    return 'group_$safeGroupId';
  }
}
