// lib/services/cat_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/breed_model.dart';

class CatApiService {
  static const String _baseUrl = 'https://api.thecatapi.com/v1';
  static const String _apiKey = 'live_NTL2tFLqQyuX3MbZH41Heic29wufIkL7dJCx1DCsOpFKOcJPQAGg0jggNhtciRMu';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
  };

  // 1️⃣ GET ALL CAT BREEDS
  Future<List<Breed>> getAllBreeds() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/breeds'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Breed.fromCatJson(json)).toList(); // ✅ fromCatJson
      } else {
        throw Exception('Failed to load cat breeds: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting all cat breeds: $e');
      throw Exception('Error: $e');
    }
  }

  // 2️⃣ SEARCH CAT BREED BY NAME
  Future<List<Breed>> searchBreed(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/breeds/search?q=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Breed.fromCatJson(json)).toList(); // ✅ fromCatJson
      } else {
        throw Exception('Failed to search cat breeds: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching cat breed: $e');
      throw Exception('Error: $e');
    }
  }

  // 3️⃣ GET CAT BREED IMAGES
  Future<List<String>> getBreedImages(String breedId, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/images/search?breed_ids=$breedId&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['url'] as String).toList();
      } else {
        throw Exception('Failed to load cat images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting cat breed images: $e');
      return [];
    }
  }

  // 4️⃣ GET RANDOM CAT IMAGES
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
        throw Exception('Failed to load random cat images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting random cat images: $e');
      return [];
    }
  }

  // 5️⃣ GET CAT PRODUCT RECOMMENDATIONS
  List<String> getProductRecommendations(Breed breed) {
    List<String> recommendations = [];

    // Selon le tempérament
    if (breed.temperament != null) {
      if (breed.temperament!.toLowerCase().contains('active') ||
          breed.temperament!.toLowerCase().contains('playful')) {
        recommendations.addAll([
          'Jouets interactifs pour chat',
          'Arbre à chat',
          'Pointeur laser',
        ]);
      }

      if (breed.temperament!.toLowerCase().contains('calm') ||
          breed.temperament!.toLowerCase().contains('quiet')) {
        recommendations.addAll([
          'Panier douillet',
          'Jouets doux',
        ]);
      }
    }

    // Selon le poids (breed.weight est un String!)
    if (breed.weight != null) {
      String weightStr = breed.weight!.split('-').first.trim(); // ✅ CORRIGÉ
      int? weightNum = int.tryParse(weightStr);

      if (weightNum != null) {
        if (weightNum < 4) {
          recommendations.add('Croquettes petite race');
        } else if (weightNum > 6) {
          recommendations.add('Croquettes grande race');
        }
      }
    }

    // Produits de base pour tous les chats
    recommendations.addAll([
      'Litière',
      'Griffoir',
      'Brosse de toilettage',
    ]);

    return recommendations;
  }
}