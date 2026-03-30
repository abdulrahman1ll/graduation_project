import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  const Group({
    required this.id,
    required this.tripId,
    required this.name,
    required this.description,
    required this.members,
    required this.imageUrl,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String tripId;
  final String name;
  final String description;
  final List<String> members;
  final String? imageUrl;
  final String createdBy;
  final DateTime? createdAt;

  factory Group.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final members = (data['members'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];

    return Group(
      id: snapshot.id,
      tripId: (data['tripId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      members: members,
      imageUrl: _readString(data['imageUrl']),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: _readDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'tripId': tripId,
      'name': name,
      'description': description,
      'members': members,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  Group copyWith({
    String? id,
    String? tripId,
    String? name,
    String? description,
    List<String>? members,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String? _readString(Object? value) {
    final parsed = value?.toString().trim();
    if (parsed == null || parsed.isEmpty || parsed == 'null') {
      return null;
    }
    return parsed;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
