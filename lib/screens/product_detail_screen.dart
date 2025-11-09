import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../db/database_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final int ownerId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.ownerId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          content: Text('$_quantity x ${widget.product.name} ajouté au panier'),
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
                  // ========== GALERIE D'IMAGES ==========
                  if (allPhotos.isNotEmpty)
                    Column(
                      children: [
                        // Image principale avec slider
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

                              // Badge Stock Épuisé
                              if (widget.product.stock == 0)
                                Positioned(
                                  top: 16,
                                  left: 16,
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

                              // Compteur d'images
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

                        // Thumbnails (si plusieurs images)
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

                        // Dots indicateurs
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

                  // ========== INFORMATIONS PRODUIT ==========
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Catégorie + Espèce
                        Row(
                          children: [
                            Chip(
                              label: Text(widget.product.category),
                              backgroundColor: Colors.teal[50],
                            ),
                            if (widget.product.species != null) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(widget.product.species!),
                                backgroundColor: Colors.orange[50],
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Prix
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

                        // Stock
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: widget.product.stock > 10
                                  ? Colors.green
                                  : widget.product.stock > 0
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.product.stock > 0
                                  ? 'En stock (${widget.product.stock} disponibles)'
                                  : 'Rupture de stock',
                              style: TextStyle(
                                fontSize: 16,
                                color: widget.product.stock > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // Description
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

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========== BARRE D'ACHAT ==========
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
                    // Sélecteur de quantité
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
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

                    // Bouton Ajouter au panier
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