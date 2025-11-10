import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

  // Couleurs harmonisées avec Services Vétérinaires
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  Future<void> _searchBooks() async {
    if (_searchController.text.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final query = Uri.encodeComponent(_searchController.text);
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _books = data['items'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur de l\'API: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue: $e';
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
        title: const Text('Recherche de Livres Vétérinaires'),
        backgroundColor: primaryPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Entrez un sujet ou un titre',
        labelStyle: const TextStyle(color: lightPurple),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: primaryPurple),
          onPressed: _searchBooks,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPurple),
        ),
      ),
      onSubmitted: (_) => _searchBooks(),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
            child: CircularProgressIndicator(color: primaryPurple)
        ),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Expanded(
        child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            )
        ),
      );
    }
    if (_books.isEmpty) {
      return Expanded(
        child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 80, color: lightPurple.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Aucun livre trouvé.\nLancez une recherche.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            )
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index]['volumeInfo'];
          final thumbnailUrl = book['imageLinks']?['thumbnail'] ?? '';
          final infoUrl = book['infoLink'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: lightPurpleBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: thumbnailUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.book, size: 40, color: primaryPurple);
                    },
                  ),
                )
                    : const Icon(Icons.book, size: 40, color: primaryPurple),
              ),
              title: Text(
                book['title'] ?? 'Titre inconnu',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  book['authors']?.join(', ') ?? 'Auteur inconnu',
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: accentOrange, size: 18),
              onTap: infoUrl != null ? () => _launchURL(infoUrl) : null,
            ),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le lien $url'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}