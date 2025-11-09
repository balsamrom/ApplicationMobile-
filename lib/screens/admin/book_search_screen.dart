import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'book_detail_screen.dart'; // Importer le nouvel écran de détail

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({Key? key}) : super(key: key);

  @override
  _BookSearchScreenState createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final String _apiKey = 'AIzaSyCgMYSBApyyPdlTefYo298N3vGCcyIDmk0'; // Votre clé API

  Future<void> _searchBooks() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _books = [];
    });

    final query = _searchController.text;
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query&key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _books = data['items'] ?? [];
          if (_books.isEmpty) {
            _errorMessage = 'Aucun livre trouvé pour cette recherche.';
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur de l\'API: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion. Vérifiez votre réseau.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher des Livres'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ex: Soins pour chats, dressage...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (_) => _searchBooks(),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage.isNotEmpty)
            Expanded(child: Center(child: Text(_errorMessage)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final bookData = _books[index];
                  final volumeInfo = bookData['volumeInfo'];
                  final imageUrl = volumeInfo['imageLinks']?['thumbnail'];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: imageUrl != null
                          ? Image.network(imageUrl, width: 60, fit: BoxFit.cover)
                          : const Icon(Icons.book_outlined, size: 50, color: Colors.grey),
                      title: Text(volumeInfo['title'] ?? 'Titre inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(volumeInfo['authors']?.join(', ') ?? 'Auteur inconnu'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigation vers l'écran de détail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(book: bookData),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
