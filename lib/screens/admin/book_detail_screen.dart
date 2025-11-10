import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetailScreen extends StatelessWidget {
  final dynamic book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final volumeInfo = book['volumeInfo'];
    final imageUrl = volumeInfo['imageLinks']?['thumbnail'] ?? '';
    final title = volumeInfo['title'] ?? 'Titre inconnu';
    final authors = volumeInfo['authors']?.join(', ') ?? 'Auteur inconnu';
    final description = volumeInfo['description'] ?? 'Aucune description disponible.';
    final previewLink = volumeInfo['previewLink'];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imageUrl.isNotEmpty)
              Center(
                child: Image.network(
                  imageUrl.replaceAll('&edge=curl', ''), // Agrandir l'image
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(authors, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: 24),
            Text(description, style: const TextStyle(fontSize: 16), textAlign: TextAlign.justify),
            const SizedBox(height: 32),
            if (previewLink != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.import_contacts),
                label: const Text('Lire un extrait'),
                onPressed: () async {
                  final uri = Uri.parse(previewLink);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
