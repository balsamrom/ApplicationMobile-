// lib/services/unsplash_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UnsplashService {
  // 🔑 Ton Access Key Unsplash
  static const String _accessKey = 'c4LWmAKTUOJFNlfKZqwKCaeRcrCPqvEgXCwT_Ipm1GE';
  static const String _baseUrl = 'https://api.unsplash.com';

  // 1️⃣ Recherche photos par mot-clé
  static Future<List<UnsplashPhoto>> searchPhotos({
    required String query,
    int perPage = 20,
  }) async {
    try {
      final url = '$_baseUrl/search/photos?query=$query&per_page=$perPage&orientation=squarish';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Client-ID $_accessKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => UnsplashPhoto.fromJson(json)).toList();
      } else {
        throw Exception('Erreur Unsplash: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur searchPhotos: $e');
      return [];
    }
  }

  // 2️⃣ Photo aléatoire par catégorie
  static Future<UnsplashPhoto?> getRandomPhoto({
    required String query,
  }) async {
    try {
      final url = '$_baseUrl/photos/random?query=$query&orientation=squarish';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Client-ID $_accessKey'},
      );

      if (response.statusCode == 200) {
        return UnsplashPhoto.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('❌ Erreur getRandomPhoto: $e');
      return null;
    }
  }

  // 3️⃣ Télécharger une photo (déclenche le tracking Unsplash)
  static Future<void> triggerDownload(String downloadUrl) async {
    try {
      await http.get(
        Uri.parse(downloadUrl),
        headers: {'Authorization': 'Client-ID $_accessKey'},
      );
    } catch (e) {
      print('❌ Erreur triggerDownload: $e');
    }
  }

  // 4️⃣ Helper: Obtenir le bon query selon catégorie/espèce (PHOTOS DE PRODUITS)
  static String getSearchQuery(String? category, String? species) {
    final queries = {
      'Aliments': {
        'Chien': 'dog food kibble bag product',
        'Chat': 'cat food can product package',
        'Oiseau': 'bird seed bag food product',
        'Rongeur': 'hamster food package product',
        'Reptile': 'reptile food product',
        'Poisson': 'fish food flakes product',
        'Tous': 'pet food product package',
      },
      'Accessoires': {
        'Chien': 'dog collar leash product',
        'Chat': 'cat bed scratching post product',
        'Oiseau': 'bird cage product',
        'Rongeur': 'hamster wheel cage product',
        'Reptile': 'terrarium tank product',
        'Poisson': 'aquarium filter pump product',
        'Tous': 'pet accessories product',
      },
      'Soins': {
        'Chien': 'dog shampoo brush grooming product',
        'Chat': 'cat grooming brush product',
        'Oiseau': 'bird bath spray product',
        'Rongeur': 'small pet care product',
        'Reptile': 'reptile vitamin spray product',
        'Poisson': 'aquarium water treatment product',
        'Tous': 'pet care grooming product',
      },
      'Jouets': {
        'Chien': 'dog toy ball rope product',
        'Chat': 'cat toy mouse feather product',
        'Oiseau': 'bird toy mirror bell product',
        'Rongeur': 'hamster toy tunnel product',
        'Reptile': 'reptile hide cave product',
        'Poisson': 'aquarium decoration ornament',
        'Tous': 'pet toy product',
      },
    };

    // Si catégorie et espèce existent
    if (category != null && species != null && queries[category]?.containsKey(species) == true) {
      return queries[category]![species]!;
    }

    // Si juste catégorie
    if (category != null && queries[category] != null) {
      return queries[category]!['Tous']!;
    }

    // Fallback général
    return 'pet products ${category ?? ''} ${species ?? ''}'.trim();
  }
}

// 📦 Modèle UnsplashPhoto
class UnsplashPhoto {
  final String id;
  final String regularUrl;
  final String smallUrl;
  final String thumbUrl;
  final String downloadUrl;
  final String photographerName;
  final String photographerUsername;
  final String? description;

  UnsplashPhoto({
    required this.id,
    required this.regularUrl,
    required this.smallUrl,
    required this.thumbUrl,
    required this.downloadUrl,
    required this.photographerName,
    required this.photographerUsername,
    this.description,
  });

  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    return UnsplashPhoto(
      id: json['id'],
      regularUrl: json['urls']['regular'],
      smallUrl: json['urls']['small'],
      thumbUrl: json['urls']['thumb'],
      downloadUrl: json['links']['download_location'],
      photographerName: json['user']['name'],
      photographerUsername: json['user']['username'],
      description: json['description'] ?? json['alt_description'],
    );
  }

  // Attribution requise par Unsplash
  String get attribution => 'Photo by $photographerName on Unsplash';
  String get profileUrl => 'https://unsplash.com/@$photographerUsername?utm_source=petshop&utm_medium=referral';
}