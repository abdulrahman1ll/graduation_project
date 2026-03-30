import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_role.dart';

class Member {
  const Member({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final GroupRole role;
  final DateTime? joinedAt;

  factory Member.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return Member(
      userId: (data['userId'] ?? snapshot.id).toString(),
      role: GroupRole.fromValue((data['role'] ?? 'member').toString()),
      joinedAt: _readDateTime(data['joinedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'role': role.value,
      'joinedAt': joinedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(joinedAt!),
    };
  }

  Member copyWith({
    String? userId,
    GroupRole? role,
    DateTime? joinedAt,
  }) {
    return Member(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
