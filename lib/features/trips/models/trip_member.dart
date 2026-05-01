import 'package:cloud_firestore/cloud_firestore.dart';

class TripMember {
  const TripMember({
    required this.userId,
    required this.status,
    required this.joinedAt,
  });

  final String userId;
  final String status;
  final Timestamp? joinedAt;

  factory TripMember.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return TripMember(
      userId: (map['userId'] ?? documentId ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      joinedAt:
          map['joinedAt'] is Timestamp ? map['joinedAt'] as Timestamp : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'status': status,
      'joinedAt': joinedAt,
    };
  }
}
