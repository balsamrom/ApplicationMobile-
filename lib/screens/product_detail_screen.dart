// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
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
  bool _isAddingToCart = false;

  Future<void> _addToCart() async {
    if (widget.product.stock <= 0) {
      _showMessage('❌ Produit en rupture de stock', Colors.red);
      return;
    }

    if (_quantity > widget.product.stock) {
      _showMessage('❌ Stock insuffisant (${widget.product.stock} disponible)', Colors.red);
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final db = await DatabaseHelper.instance.database;

      // Vérifier si déjà dans le panier
      final existing = await db.query(
        'cart_items',
        where: 'owner_id = ? AND product_id = ?',
        whereArgs: [widget.ownerId, widget.product.id],
      );

      if (existing.isNotEmpty) {
        // Mettre à jour la quantité
        final currentQty = existing.first['quantity'] as int;
        final newQty = currentQty + _quantity;

        if (newQty > widget.product.stock) {
          _showMessage('❌ Stock insuffisant', Colors.red);
          return;
        }

        await db.update(
          'cart_items',
          {'quantity': newQty},
          where: 'owner_id = ? AND product_id = ?',
          whereArgs: [widget.ownerId, widget.product.id],
        );
      } else {
        // Ajouter nouveau
        await db.insert('cart_items', {
          'owner_id': widget.ownerId,
          'product_id': widget.product.id,
          'quantity': _quantity,
          'product_name': widget.product.name,
          'product_price': widget.product.price,
          'product_photo': widget.product.photoPath,
        });
      }

      _showMessage('✅ $_quantity × ${widget.product.name} ajouté au panier', Colors.green);

      // Attendre un peu puis retourner
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage('❌ Erreur: $e', Colors.red);
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Détails du produit'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📷 Photo du produit
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.white,
              child: widget.product.photoPath != null &&
                  widget.product.photoPath!.isNotEmpty
                  ? Image.file(
                File(widget.product.photoPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
                  : _buildPlaceholder(),
            ),

            // 📋 Informations produit
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${widget.product.price.toStringAsFixed(3)} DT',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Catégorie et Espèce
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(widget.product.category),
                        backgroundColor: Colors.teal.shade50,
                        labelStyle: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.product.species != null &&
                          widget.product.species!.isNotEmpty)
                        Chip(
                          label: Text(widget.product.species!),
                          backgroundColor: Colors.orange.shade50,
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stock
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.product.stock > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.product.stock > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.product.stock > 0
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: widget.product.stock > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.product.stock > 0
                              ? 'En stock: ${widget.product.stock} unité(s)'
                              : 'Rupture de stock',
                          style: TextStyle(
                            color: widget.product.stock > 0
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 24),

                  // Sélecteur de quantité
                  if (widget.product.stock > 0) ...[
                    const Text(
                      'Quantité',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          onPressed: _quantity < widget.product.stock
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ${(widget.product.price * _quantity).toStringAsFixed(3)} DT',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 80), // Espace pour le bouton fixe
                ],
              ),
            ),
          ],
        ),
      ),

      // Bouton Ajouter au panier (fixé en bas)
      bottomNavigationBar: widget.product.stock > 0
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isAddingToCart ? null : _addToCart,
            icon: _isAddingToCart
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.shopping_cart),
            label: Text(
              _isAddingToCart
                  ? 'Ajout en cours...'
                  : 'Ajouter au panier',
              style: const TextStyle(
                fontSize: 18,
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
      )
          : null,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.grey,
        ),
      ),
    );
  }
}