import 'dart:convert';
import 'package:http/http.dart' as http;

class AiRecommendationService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  Future<double?> predictRating({
    required String preferredPlaceType,
    required String distancePreference,
    required String temperaturePreference,
    required String placeEnvironmentType,
    required String placeDistanceBucket,
    required double placeAverageRating,
    required int placeRatingCount,
    required int userClickCountForPlace,
  }) async {
    final url = Uri.parse('$baseUrl/predict');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'preferredPlaceType': preferredPlaceType,
        'distancePreference': distancePreference,
        'temperaturePreference': temperaturePreference,
        'placeEnvironmentType': placeEnvironmentType,
        'placeDistanceBucket': placeDistanceBucket,
        'placeAverageRating': placeAverageRating,
        'placeRatingCount': placeRatingCount,
        'userClickCountForPlace': userClickCountForPlace,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('AI API RESPONSE: $data');

      final value = data['predicted_rating'];
      if (value is num) {
        return value.toDouble();
      }
    }

    return null;
  }
}
