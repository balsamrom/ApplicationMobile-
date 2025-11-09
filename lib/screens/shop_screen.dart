import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../db/database_helper.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'admin_products_screen.dart';
import 'favorites_screen.dart';
import 'order_history_screen.dart';

class ShopScreen extends StatefulWidget {
  final int ownerId;

  const ShopScreen({super.key, required this.ownerId});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  int _cartItemCount = 0;
  int _favoritesCount = 0;
  bool _isLoading = true;

  final List<String> _categories = [
    'Tous',
    'Aliments',
    'Accessoires',
    'Soins',
    'Jouets'
  ];

  final List<String> _species = [
    'Tous',
    'Chien',
    'Chat',
    'Oiseau',
    'Rongeur',
    'Reptile',
    'Poisson'
  ];

  String _selectedCategory = 'Tous';
  String _selectedSpecies = 'Tous';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadProducts(),
      _loadCartCount(),
      _loadFavoritesCount(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadProducts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('products');

      setState(() {
        _allProducts = maps.map((map) => Product.fromMap(map)).toList();
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Erreur chargement produits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [widget.ownerId],
      );
      if (mounted) {
        setState(() => _cartItemCount = result.length);
      }
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
    }
  }

  Future<void> _loadFavoritesCount() async {
    try {
      final count = await DatabaseHelper.instance.getFavoritesCount(widget.ownerId);
      if (mounted) {
        setState(() => _favoritesCount = count);
      }
    } catch (e) {
      debugPrint('Erreur chargement favoris: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesCategory = _selectedCategory == 'Tous' ||
            p.category == _selectedCategory;

        final matchesSpecies = _selectedSpecies == 'Tous' ||
            p.species == _selectedSpecies ||
            p.species == null ||
            p.species!.isEmpty;

        final matchesSearch = _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesCategory && matchesSpecies && matchesSearch;
      }).toList();
    });
  }

  Future<void> _addToCart(Product product) async {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Produit en rupture de stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      final existing = await db.query(
        'cart_items',
        where: 'owner_id = ? AND product_id = ?',
        whereArgs: [widget.ownerId, product.id],
      );

      if (existing.isNotEmpty) {
        final currentQty = existing.first['quantity'] as int;
        await db.update(
          'cart_items',
          {'quantity': currentQty + 1},
          where: 'owner_id = ? AND product_id = ?',
          whereArgs: [widget.ownerId, product.id],
        );
      } else {
        await db.insert('cart_items', {
          'owner_id': widget.ownerId,
          'product_id': product.id,
          'quantity': 1,
          'product_name': product.name,
          'product_price': product.finalPrice,
          'product_photo': product.photoPath,
        });
      }

      await _loadCartCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${product.name} ajouté au panier'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur ajout panier: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛍️ Boutique PetShop'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // ❤️ BOUTON FAVORIS avec badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite),
                iconSize: 28,
                tooltip: 'Mes Favoris',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavoritesScreen(ownerId: widget.ownerId),
                    ),
                  );
                  _loadFavoritesCount();
                },
              ),
              if (_favoritesCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$_favoritesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // 📦 BOUTON HISTORIQUE COMMANDES
          IconButton(
            icon: const Icon(Icons.receipt_long),
            iconSize: 28,
            tooltip: 'Mes Commandes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderHistoryScreen(ownerId: widget.ownerId),
                ),
              );
            },
          ),

          // 🛠️ BOUTON ADMIN
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            iconSize: 28,
            tooltip: 'Gestion Produits (Admin)',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProductsScreen(),
                ),
              );
              _loadData();
            },
          ),

          // 🛒 BOUTON PANIER avec badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                iconSize: 28,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(ownerId: widget.ownerId),
                    ),
                  );
                  if (result == true) {
                    _loadCartCount();
                  }
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔍 Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 Rechercher un produit...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),

          // 🏷️ Filtres Catégories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                      _applyFilters();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 🐾 Filtres Espèces
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _species.length,
              itemBuilder: (context, index) {
                final species = _species[index];
                final isSelected = species == _selectedSpecies;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(species),
                    selected: isSelected,
                    selectedColor: Colors.teal.shade100,
                    checkmarkColor: Colors.teal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.teal : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedSpecies = species);
                      _applyFilters();
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(height: 16),

          // 📊 Nombre de résultats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} produit(s) trouvé(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedCategory != 'Tous' ||
                    _selectedSpecies != 'Tous' ||
                    _searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'Tous';
                        _selectedSpecies = 'Tous';
                        _searchQuery = '';
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Réinitialiser'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 🛍️ Grille de produits
          Expanded(
            child: _filteredProducts.isEmpty
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
                    'Aucun produit trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'Tous';
                        _selectedSpecies = 'Tous';
                        _searchQuery = '';
                      });
                      _applyFilters();
                    },
                    child: const Text('Réinitialiser les filtres'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadData,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // ← FIX OVERFLOW
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ProductCard(
                    product: product,
                    ownerId: widget.ownerId,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                            ownerId: widget.ownerId,
                          ),
                        ),
                      );
                      _loadCartCount();
                      _loadFavoritesCount();
                    },
                    onAddToCart: () => _addToCart(product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}