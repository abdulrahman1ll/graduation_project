import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedPlace {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final double averageRating;
  final double distanceKm;

  RecommendedPlace({
    required this.doc,
    required this.averageRating,
    required this.distanceKm,
  });
}
