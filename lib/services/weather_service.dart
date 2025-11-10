import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:pet_owner_app/consts.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> getWeather() async {
    try {
      final position = await _determinePosition();
      final response = await http.get(Uri.parse(
          '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$WEATHER_API_KEY&units=metric&lang=fr'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Clé API invalide. Veuillez la vérifier dans consts.dart.');
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      // Fait remonter l'erreur pour que l'UI puisse l'afficher
      rethrow;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Le service de localisation est désactivé.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('L\'accès à la localisation est refusé.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('L\'accès à la localisation est refusé de manière permanente.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
