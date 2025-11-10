import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // URL de l'API de traduction (MyMemory est gratuite et sans clé API)
  static const String _apiUrl = 'https://api.mymemory.translated.net/get';

  // Cache local pour éviter de retraduire les mêmes textes
  static final Map<String, String> _cache = {};

  /// Traduit un texte de manière dynamique via API
  ///
  /// [text] : Le texte à traduire
  /// [from] : Langue source (par défaut 'fr' pour français)
  /// [to] : Langue cible (par défaut 'ar' pour arabe)
  ///
  /// Retourne le texte traduit ou le texte original en cas d'erreur
  static Future<String> translate(
      String text, {
        String from = 'fr',
        String to = 'ar',
      }) async {
    // Validation : texte vide
    if (text.trim().isEmpty) {
      return text;
    }

    // Vérifier le cache pour éviter les appels API inutiles
    final cacheKey = '${from}_${to}_$text';
    if (_cache.containsKey(cacheKey)) {
      print('✅ Traduction depuis le cache: $text');
      return _cache[cacheKey]!;
    }

    try {
      print('🌐 Appel API pour traduire: $text');

      // Construction de l'URL avec paramètres
      final uri = Uri.parse(_apiUrl).replace(queryParameters: {
        'q': text,
        'langpair': '$from|$to',
      });

      // Appel API avec timeout de 10 secondes
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La traduction a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifier si la réponse contient une traduction
        if (data['responseData'] != null &&
            data['responseData']['translatedText'] != null) {

          final translatedText = data['responseData']['translatedText'] as String;

          // Sauvegarder dans le cache
          _cache[cacheKey] = translatedText;

          print('✅ Traduction réussie: $text → $translatedText');
          return translatedText;
        } else {
          print('⚠️ Réponse API invalide');
          return text;
        }
      } else {
        print('❌ Erreur API: ${response.statusCode}');
        return text;
      }
    } catch (e) {
      print('❌ Erreur de traduction: $e');
      // En cas d'erreur, retourner le texte original
      return text;
    }
  }

  /// Traduit une liste de textes en une seule fois
  /// Optimisé pour traduire plusieurs éléments d'un coup
  static Future<List<String>> translateBatch(
      List<String> texts, {
        String from = 'fr',
        String to = 'ar',
      }) async {
    final List<String> translations = [];

    for (final text in texts) {
      final translation = await translate(text, from: from, to: to);
      translations.add(translation);

      // Petit délai pour ne pas surcharger l'API
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return translations;
  }

  /// Vide le cache de traduction
  static void clearCache() {
    _cache.clear();
    print('🗑️ Cache de traduction vidé');
  }

  /// Retourne la taille actuelle du cache
  static int getCacheSize() {
    return _cache.length;
  }
}