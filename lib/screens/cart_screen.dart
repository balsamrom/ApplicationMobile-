import 'package:flutter/material.dart';
import 'dart:io';
import '../models/cart_item.dart';
import '../db/database_helper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final int ownerId;

  const CartScreen({super.key, required this.ownerId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [widget.ownerId],
      );

      setState(() {
        _cartItems = maps.map((map) => CartItem.fromMap(map)).toList();
        _calculateTotal();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    _totalAmount = _cartItems.fold(
      0.0,
          (sum, item) => sum + (item.productPrice * item.quantity),
    );
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(item);
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'cart_items',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [item.id],
      );
      await _loadCartItems();
    } catch (e) {
      debugPrint('Erreur mise à jour quantité: $e');
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'cart_items',
        where: 'id = ?',
        whereArgs: [item.id],
      );
      await _loadCartItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article retiré du panier'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur suppression article: $e');
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider tout le panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete(
          'cart_items',
          where: 'owner_id = ?',
          whereArgs: [widget.ownerId],
        );
        await _loadCartItems();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Panier vidé')),
          );
        }
      } catch (e) {
        debugPrint('Erreur vidage panier: $e');
      }
    }
  }

  Future<void> _goToCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre panier est vide')),
      );
      return;
    }

    // Vérifier les stocks avant d'aller au checkout
    try {
      final db = await DatabaseHelper.instance.database;

      for (var item in _cartItems) {
        final productResult = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (productResult.isEmpty) {
          throw Exception('Produit ${item.productName} introuvable');
        }

        final stock = (productResult.first['stock'] as num).toInt();
        if (stock < item.quantity) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Stock insuffisant pour ${item.productName}\nDisponible: $stock',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      // Naviguer vers l'écran de checkout
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            cartItems: _cartItems,
            totalAmount: _totalAmount,
            ownerId: widget.ownerId,
          ),
        ),
      );

      // Si la commande a été passée, recharger le panier
      if (result == true && mounted) {
        await _loadCartItems();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Mon Panier'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCart,
              tooltip: 'Vider le panier',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Continuer mes achats'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image produit
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.productPhoto != null &&
                              File(item.productPhoto!)
                                  .existsSync()
                              ? Image.file(
                            File(item.productPhoto!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Infos produit
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.productPrice.toStringAsFixed(2)} TND',
                                style: TextStyle(
                                  color: Colors.teal[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Contrôles quantité
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _updateQuantity(
                                      item,
                                      item.quantity - 1,
                                    ),
                                    icon: const Icon(
                                        Icons.remove_circle_outline),
                                    color: Colors.red,
                                    iconSize: 28,
                                  ),
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _updateQuantity(
                                      item,
                                      item.quantity + 1,
                                    ),
                                    icon: const Icon(
                                        Icons.add_circle_outline),
                                    color: Colors.green,
                                    iconSize: 28,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Bouton supprimer + sous-total
                        Column(
                          children: [
                            IconButton(
                              onPressed: () => _removeItem(item),
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                            ),
                            Text(
                              '${(item.productPrice * item.quantity).toStringAsFixed(2)} TND',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Résumé et bouton commander
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${_cartItems.length} article${_cartItems.length > 1 ? 's' : ''}):',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_totalAmount.toStringAsFixed(2)} TND',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _goToCheckout,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text(
                        'Passer la commande',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
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