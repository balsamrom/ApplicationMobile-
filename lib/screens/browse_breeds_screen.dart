import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/dog_api_service.dart';
import '../services/cat_api_service.dart';
import '../models/breed_model.dart';
import '../widgets/breed_card.dart';
import 'breed_detail_screen.dart';

class BrowseBreedsScreen extends StatefulWidget {
  final int ownerId; // ✅ AJOUTÉ

  const BrowseBreedsScreen({
    Key? key,
    required this.ownerId, // ✅ AJOUTÉ
  }) : super(key: key);

  @override
  State<BrowseBreedsScreen> createState() => _BrowseBreedsScreenState();
}

class _BrowseBreedsScreenState extends State<BrowseBreedsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DogApiService _dogApi = DogApiService();
  final CatApiService _catApi = CatApiService();

  List<Breed> _dogBreeds = [];
  List<Breed> _catBreeds = [];
  List<Breed> _filteredBreeds = [];

  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBreeds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    _filterBreeds(_searchQuery);
  }

  Future<void> _loadBreeds() async {
    setState(() => _isLoading = true);

    try {
      final dogs = await _dogApi.getAllBreeds();
      final cats = await _catApi.getAllBreeds();

      setState(() {
        _dogBreeds = dogs;
        _catBreeds = cats;
        _filteredBreeds = dogs; // Par défaut afficher les chiens
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  void _filterBreeds(String query) {
    setState(() {
      _searchQuery = query;
      List<Breed> sourceBreeds =
      _tabController.index == 0 ? _dogBreeds : _catBreeds;

      if (query.isEmpty) {
        _filteredBreeds = sourceBreeds;
      } else {
        _filteredBreeds = sourceBreeds.where((breed) {
          return breed.name.toLowerCase().contains(query.toLowerCase()) ||
              (breed.temperament?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Races d\'animaux',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Chiens'),
            Tab(icon: Icon(Icons.catching_pokemon), text: 'Chats'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une race...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterBreeds('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterBreeds,
            ),
          ),

          // Compteur de résultats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredBreeds.length} race(s) trouvée(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Liste des races
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBreeds.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune race trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredBreeds.length,
              itemBuilder: (context, index) {
                final breed = _filteredBreeds[index];
                return BreedCard(
                  breed: breed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BreedDetailScreen(
                          breed: breed,
                          isPet: _tabController.index == 0
                              ? 'dog'
                              : 'cat',
                          ownerId: widget.ownerId, // ✅ PASSÉ ICI
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}