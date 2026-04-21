import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '00d90bb41bd1aa8875aaa0f729a42613';

  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final main = data['main'] as Map<String, dynamic>?;
    final wind = data['wind'] as Map<String, dynamic>?;
    final weatherList = data['weather'] as List<dynamic>?;
    final firstWeather = weatherList != null && weatherList.isNotEmpty
        ? weatherList.first as Map<String, dynamic>
        : null;

    return {
      'temp': (main?['temp'] as num?)?.toDouble(),
      'weather': (firstWeather?['main'] as String?) ?? 'Unknown',
      'wind': (wind?['speed'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
