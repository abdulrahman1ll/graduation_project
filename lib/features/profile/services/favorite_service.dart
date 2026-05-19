import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  FavoriteService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User? get _user => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>? get _favorites {
    final user = _user;
    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites');
  }

  Stream<bool> isFavoriteStream(String placeId) {
    final favorites = _favorites;
    if (favorites == null) {
      return Stream.value(false);
    }

    return favorites.doc(placeId).snapshots().map((snapshot) => snapshot.exists);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> favoritesStream() {
    final favorites = _favorites;
    if (favorites == null) {
      return const Stream.empty();
    }

    return favorites.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> toggleFavorite({
    required String placeId,
    required Map<String, dynamic> placeData,
  }) async {
    final favorites = _favorites;
    if (favorites == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Please sign in first.',
      );
    }

    final favoriteRef = favorites.doc(placeId);
    final favoriteSnapshot = await favoriteRef.get();
    if (favoriteSnapshot.exists) {
      await favoriteRef.delete();
      return;
    }

    final reviews = await _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .get();
    final averageRating = _averageRating(reviews);
    final fallbackReviewImage = _firstReviewImage(reviews);
    final lat = (placeData['lat'] as num?)?.toDouble();
    final lng = (placeData['lng'] as num?)?.toDouble();
    final imageBase64 = placeData['imageBase64'] ?? fallbackReviewImage;

    await favoriteRef.set({
      'placeId': placeId,
      'name': (placeData['name'] ?? '').toString(),
      'environmentType': (placeData['environmentType'] ?? '').toString(),
      if (placeData['imageUrl'] != null) 'imageUrl': placeData['imageUrl'],
      if (placeData['photoUrl'] != null) 'photoUrl': placeData['photoUrl'],
      if (placeData['image'] != null) 'image': placeData['image'],
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (placeData['imagePath'] != null) 'imagePath': placeData['imagePath'],
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
      'averageRating': averageRating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String placeId) async {
    final favorites = _favorites;
    if (favorites == null) {
      return;
    }

    await favorites.doc(placeId).delete();
  }

  double _averageRating(QuerySnapshot<Map<String, dynamic>> reviews) {
    if (reviews.docs.isEmpty) {
      return 0;
    }

    final total = reviews.docs.fold<double>(
      0,
      (sum, doc) =>
          sum + ((doc.data()['rating'] as num?)?.toDouble() ?? 0),
    );
    return total / reviews.docs.length;
  }

  Object? _firstReviewImage(QuerySnapshot<Map<String, dynamic>> reviews) {
    for (final doc in reviews.docs) {
      final data = doc.data();
      final image = data['imageBase64'] ??
          data['imageUrl'] ??
          data['photoUrl'] ??
          data['image'];
      if (image != null && image.toString().trim().isNotEmpty) {
        return image;
      }
    }

    return null;
  }
}
