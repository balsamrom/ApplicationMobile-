import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../db/database_helper.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final int ownerId;
  final String? recommendedFor;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.ownerId,
    this.recommendedFor,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  List<Product> _similarProducts = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _loadSimilarProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final isFav = await DatabaseHelper.instance.isFavorite(
      widget.ownerId,
      widget.product.id!,
    );
    setState(() => _isFavorite = isFav);
  }

  Future<void> _loadSimilarProducts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'id != ? AND (category = ? OR species = ?)',
        whereArgs: [
          widget.product.id,
          widget.product.category,
          widget.product.species ?? '',
        ],
        limit: 6,
      );

      setState(() {
        _similarProducts = maps.map((map) => Product.fromMap(map)).toList();
      });
    } catch (e) {
      debugPrint('Erreur chargement produits similaires: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await DatabaseHelper.instance.removeFromFavorites(
          widget.ownerId,
          widget.product.id!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Retiré des favoris'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await DatabaseHelper.instance.addToFavorites(
          widget.ownerId,
          widget.product.id!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❤️ Ajouté aux favoris'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      debugPrint('Erreur favoris: $e');
    }
  }

  Future<void> _shareProduct() async {
    try {
      final shareText = '🛍️ Regarde ce produit!\n\n'
          '${widget.product.name}\n'
          '${widget.product.finalPrice.toStringAsFixed(3)} DT\n\n'
          '${widget.product.description}\n\n'
          '#PetShop #${widget.product.category}';

      await Clipboard.setData(ClipboardData(text: shareText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Texte copié! Vous pouvez le partager maintenant'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur partage: $e');
    }
  }

  Future<void> _addToCart() async {
    if (widget.product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit en rupture de stock')),
      );
      return;
    }

    if (_quantity > widget.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuffisant (max: ${widget.product.stock})')),
      );
      return;
    }

    final cartItem = CartItem(
      ownerId: widget.ownerId,
      productId: widget.product.id!,
      quantity: _quantity,
      productName: widget.product.name,
      productPrice: widget.product.finalPrice,
      productPhoto: widget.product.photoPath,
    );

    await DatabaseHelper.instance.addToCart(cartItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $_quantity x ${widget.product.name} ajouté au panier'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showFullImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPhotos = widget.product.allPhotos;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          ),

          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProduct,
            tooltip: 'Partager',
          ),

          if (widget.product.isOnSale)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  '-${widget.product.salePercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (allPhotos.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: allPhotos.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _showFullImage(allPhotos[index]),
                                    child: Image.file(
                                      File(allPhotos[index]),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  );
                                },
                              ),

                              if (widget.recommendedFor != null)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.orange, Colors.deepOrange],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.pets,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pour ${widget.recommendedFor}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (widget.product.stock == 0)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ÉPUISÉ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              if (allPhotos.length > 1)
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1}/${allPhotos.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (allPhotos.length > 1)
                          Container(
                            height: 80,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: allPhotos.length,
                              itemBuilder: (context, index) {
                                final isSelected = index == _currentImageIndex;
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: 60,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.teal
                                            : Colors.grey[300]!,
                                        width: isSelected ? 3 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        File(allPhotos[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        if (allPhotos.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              allPhotos.length,
                                  (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? Colors.teal
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      height: 300,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 100, color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(widget.product.category),
                              backgroundColor: Colors.teal[50],
                              avatar: const Icon(
                                Icons.category,
                                size: 18,
                                color: Colors.teal,
                              ),
                            ),
                            if (widget.product.species != null)
                              Chip(
                                label: Text(widget.product.species!),
                                backgroundColor: Colors.orange[50],
                                avatar: const Icon(
                                  Icons.pets,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (widget.product.isOnSale)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.product.price.toStringAsFixed(3)} DT',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${widget.product.finalPrice.toStringAsFixed(3)} DT',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Économisez ${(widget.product.price - widget.product.finalPrice).toStringAsFixed(3)} DT',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Text(
                            '${widget.product.price.toStringAsFixed(3)} DT',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.product.stock > 10
                                ? Colors.green[50]
                                : widget.product.stock > 0
                                ? Colors.orange[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.product.stock > 10
                                  ? Colors.green
                                  : widget.product.stock > 0
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.product.stock > 10
                                    ? Icons.check_circle
                                    : widget.product.stock > 0
                                    ? Icons.warning
                                    : Icons.cancel,
                                color: widget.product.stock > 10
                                    ? Colors.green
                                    : widget.product.stock > 0
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.product.stock > 10
                                      ? 'En stock (${widget.product.stock} disponibles)'
                                      : widget.product.stock > 0
                                      ? 'Stock limité (${widget.product.stock} restants)'
                                      : 'Rupture de stock',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: widget.product.stock > 10
                                        ? Colors.green[700]
                                        : widget.product.stock > 0
                                        ? Colors.orange[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 32),

                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),

                        if (_similarProducts.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const Text(
                            'Produits similaires',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _similarProducts.length,
                              itemBuilder: (context, index) {
                                final product = _similarProducts[index];
                                return Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: ProductCard(
                                    product: product,
                                    ownerId: widget.ownerId,
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            product: product,
                                            ownerId: widget.ownerId,
                                          ),
                                        ),
                                      );
                                    },
                                    onAddToCart: () async {
                                      final cartItem = CartItem(
                                        ownerId: widget.ownerId,
                                        productId: product.id!,
                                        quantity: 1,
                                        productName: product.name,
                                        productPrice: product.finalPrice,
                                        productPhoto: product.photoPath,
                                      );
                                      await DatabaseHelper.instance.addToCart(cartItem);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('✅ ${product.name} ajouté'),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (widget.product.stock > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _quantity < widget.product.stock
                                ? () => setState(() => _quantity++)
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addToCart,
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(
                          'Ajouter ${(_quantity * widget.product.finalPrice).toStringAsFixed(3)} DT',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}