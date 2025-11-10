import 'dart:convert';
import 'package:http/http.dart' as http;

class GeoService {
  /// Retourne la ville (ex: "Tunis") via ipapi.co
  static Future<String?> getCityFromIP() async {
    try {
      final res = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final city = (data['city'] as String?)?.trim();
        return (city == null || city.isEmpty) ? null : city;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
