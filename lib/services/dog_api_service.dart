// lib/services/dog_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/breed_model.dart';

class DogApiService {
  static const String _baseUrl = 'https://api.thedogapi.com/v1';
  static const String _apiKey = 'live_4iC0CvBdpZ2O0188NRwSnp2CAMAh6rkkvICx5tFG2UhXEfkJKEYqmc8hYNFP32u7';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
  };

  // 1️⃣ GET ALL BREEDS
  Future<List<Breed>> getAllBreeds() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/breeds'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Breed.fromDogJson(json)).toList(); // ✅ fromDogJson
      } else {
        throw Exception('Failed to load breeds: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting all breeds: $e');
      throw Exception('Error: $e');
    }
  }

  // 2️⃣ SEARCH BREED BY NAME
  Future<List<Breed>> searchBreed(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/breeds/search?q=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Breed.fromDogJson(json)).toList(); // ✅ fromDogJson
      } else {
        throw Exception('Failed to search breeds: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching breed: $e');
      throw Exception('Error: $e');
    }
  }

  // 3️⃣ GET BREED IMAGES
  Future<List<String>> getBreedImages(int breedId, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/images/search?breed_ids=$breedId&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['url'] as String).toList();
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting breed images: $e');
      return [];
    }
  }

  // 4️⃣ GET RANDOM DOG IMAGES
  Future<List<String>> getRandomImages({int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/images/search?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['url'] as String).toList();
      } else {
        throw Exception('Failed to load random images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting random images: $e');
      return [];
    }
  }

  // 5️⃣ GET BREED BY ID
  Future<Breed?> getBreedById(int breedId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/breeds/$breedId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Breed.fromDogJson(json.decode(response.body)); // ✅ fromDogJson
      } else {
        throw Exception('Failed to load breed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting breed by id: $e');
      return null;
    }
  }

  // 6️⃣ GET PRODUCT RECOMMENDATIONS
  List<String> getProductRecommendations(Breed breed) {
    List<String> recommendations = [];

    // Selon le tempérament
    if (breed.temperament != null) {
      if (breed.temperament!.toLowerCase().contains('active') ||
          breed.temperament!.toLowerCase().contains('energetic')) {
        recommendations.addAll([
          'Croquettes haute énergie',
          'Jouets interactifs',
          'Équipement d\'extérieur',
        ]);
      }

      if (breed.temperament!.toLowerCase().contains('intelligent')) {
        recommendations.add('Jouets puzzle');
      }
    }

    // Selon la taille (breed.weight est un String!)
    if (breed.weight != null) {
      // Extraction du premier nombre du poids (ex: "20-30" → 20)
      String weightStr = breed.weight!.split('-').first.trim(); // ✅ CORRIGÉ
      int? weightNum = int.tryParse(weightStr);

      if (weightNum != null) {
        if (weightNum < 10) {
          recommendations.add('Croquettes petite race');
        } else if (weightNum > 25) {
          recommendations.add('Croquettes grande race');
        }
      }
    }

    // Selon le groupe de race
    if (breed.breedGroup != null) {
      if (breed.breedGroup!.contains('Sporting')) {
        recommendations.add('Équipement d\'entraînement');
      }
      if (breed.breedGroup!.contains('Herding')) {
        recommendations.add('Jouets d\'agilité');
      }
    }

    return recommendations.isEmpty
        ? ['Croquettes chien', 'Jouets basiques']
        : recommendations;
  }
}