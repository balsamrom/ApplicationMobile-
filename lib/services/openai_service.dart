import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class OpenAIService {
  static final _gemini = Gemini.instance;

  /// Génère le contenu d'un blog avec l'IA
  ///
  /// [title] : Le titre du blog
  /// [category] : La catégorie du blog (Santé, Nutrition, etc.)
  /// [maxLength] : Longueur maximale du contenu généré (par défaut 1000 mots)
  ///
  /// Retourne le contenu généré ou null en cas d'erreur
  static Future<String?> generateBlogContent({
    required String title,
    required String category,
    int maxLength = 1000,
  }) async {
    try {
      final systemPrompt = 'Tu es un vétérinaire expert qui rédige des articles de blog professionnels et informatifs pour les propriétaires d\'animaux.';
      final userPrompt = _buildPrompt(title, category, maxLength);
      final fullPrompt = '$systemPrompt\n\n$userPrompt';

      final response = await _gemini.text(fullPrompt).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('La requête a pris trop de temps');
        },
      );

      if (response != null && response.output != null) {
        return response.output!.trim();
      } else {
        debugPrint('Erreur Gemini API: Aucune réponse générée');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur génération contenu blog: $e');
      return null;
    }
  }

  /// Construit le prompt pour l'IA
  static String _buildPrompt(String title, String category, int maxLength) {
    return '''Écris un article de blog complet et professionnel sur le sujet suivant :

Titre : $title
Catégorie : $category

Instructions :
- L'article doit être rédigé en français
- Il doit être informatif, professionnel et adapté aux propriétaires d'animaux
- L'article doit contenir environ ${maxLength ~/ 100} paragraphes
- Utilise un ton professionnel mais accessible
- Inclus des conseils pratiques et des informations utiles
- Structure l'article avec des paragraphes clairs
- Ne pas inclure de titre dans la réponse, seulement le contenu de l'article

Commence directement par le contenu de l'article :''';
  }

  /// Génère uniquement le titre d'un blog basé sur un sujet
  ///
  /// [topic] : Le sujet ou thème du blog
  /// [category] : La catégorie du blog
  ///
  /// Retourne un titre suggéré ou null en cas d'erreur
  static Future<String?> generateBlogTitle({
    required String topic,
    required String category,
  }) async {
    try {
      final prompt = '''Génère un titre accrocheur et professionnel pour un article de blog vétérinaire.

Sujet : $topic
Catégorie : $category

Le titre doit :
- Être en français
- Être accrocheur et informatif
- Faire entre 5 et 10 mots
- Ne pas contenir de guillemets ou de ponctuation finale

Réponds uniquement avec le titre, sans explication :''';

      final response = await _gemini.text(prompt).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('La requête a pris trop de temps');
        },
      );

      if (response != null && response.output != null) {
        final title = response.output!.trim();
        return title.replaceAll('"', '').replaceAll('.', '');
      } else {
        debugPrint('Erreur Gemini API: Aucune réponse générée');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur génération titre blog: $e');
      return null;
    }
  }
}

