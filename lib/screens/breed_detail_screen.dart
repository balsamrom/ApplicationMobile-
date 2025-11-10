import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/breed_model.dart';
import '../services/dog_api_service.dart';
import '../services/cat_api_service.dart';
import 'shop_screen.dart'; // ✅ IMPORT SHOP

class BreedDetailScreen extends StatefulWidget {
  final Breed breed;
  final String isPet; // 'dog' ou 'cat'
  final int ownerId; // ✅ NOUVEAU

  const BreedDetailScreen({
    Key? key,
    required this.breed,
    required this.isPet,
    required this.ownerId, // ✅ NOUVEAU
  }) : super(key: key);

  @override
  State<BreedDetailScreen> createState() => _BreedDetailScreenState();
}

class _BreedDetailScreenState extends State<BreedDetailScreen> {
  final DogApiService _dogApi = DogApiService();
  final CatApiService _catApi = CatApiService();

  List<String> _breedImages = [];
  List<String> _recommendations = [];
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _loadBreedImages();
    _loadRecommendations();
  }

  Future<void> _loadBreedImages() async {
    try {
      List<String> images;
      if (widget.isPet == 'dog') {
        images = await _dogApi.getBreedImages(widget.breed.id as int, limit: 5);
      } else {
        images = await _catApi.getBreedImages(widget.breed.id.toString(), limit: 5);
      }

      setState(() {
        _breedImages = images;
        _isLoadingImages = false;
      });
    } catch (e) {
      setState(() => _isLoadingImages = false);
    }
  }

  void _loadRecommendations() {
    if (widget.isPet == 'dog') {
      _recommendations = _dogApi.getProductRecommendations(widget.breed);
    } else {
      _recommendations = _catApi.getProductRecommendations(widget.breed);
    }
  }

  // ✅ NOUVELLE FONCTION - Navigation vers Shop
  void _navigateToShop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopScreen(
          ownerId: widget.ownerId,
        ),
      ),
    ).then((_) {
      // Afficher message après retour du shop
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💡 Astuce: Cherchez "${_recommendations.first}" dans le shop',
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.orange,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.breed.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: widget.breed.imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: widget.breed.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.pets, size: 100),
                ),
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 100),
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.public,
                            'Origine',
                            widget.breed.origin ?? 'N/A',
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.access_time,
                            'Espérance de vie',
                            widget.breed.lifeSpan ?? 'N/A',
                          ),
                          if (widget.breed.weight != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              Icons.monitor_weight,
                              'Poids',
                              '${widget.breed.weight!} kg',
                            ),
                          ],
                          if (widget.breed.breedGroup != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              Icons.category,
                              'Groupe',
                              widget.breed.breedGroup!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tempérament
                  if (widget.breed.temperament != null) ...[
                    _buildSectionTitle('Tempérament'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.breed.temperament!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bred For
                  if (widget.breed.bredFor != null) ...[
                    _buildSectionTitle('Élevé pour'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.breed.bredFor!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Galerie photos
                  _buildSectionTitle('Galerie Photos'),
                  SizedBox(
                    height: 120,
                    child: _isLoadingImages
                        ? const Center(child: CircularProgressIndicator())
                        : _breedImages.isEmpty
                        ? const Center(
                      child: Text('Aucune image disponible'),
                    )
                        : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _breedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _breedImages[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Produits Recommandés
                  _buildSectionTitle('🛒 Produits Recommandés'),
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Parfait pour votre ${widget.breed.name}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._recommendations.map((product) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      product,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),

                          // ✅ BOUTON AMÉLIORÉ
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToShop,
                              icon: const Icon(Icons.shopping_cart, size: 24),
                              label: const Text(
                                'Voir les produits',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}