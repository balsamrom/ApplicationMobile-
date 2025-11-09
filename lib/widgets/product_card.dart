import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int ownerId;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.ownerId,
    required this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badges
            Expanded(
              flex: 5, // ✅ Proportion pour l'image
              child: Stack(
                children: [
                  // Image produit
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: product.photoPath != null &&
                        File(product.photoPath!).existsSync()
                        ? Image.file(
                      File(product.photoPath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  // Badge promotion
                  if (product.isOnSale && product.salePercentage != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${product.salePercentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),

                  // Badge stock faible
                  if (product.stock > 0 && product.stock <= 5)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stock: ${product.stock}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),

                  // Badge rupture de stock
                  if (product.stock == 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Rupture',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Infos produit
            Expanded(
              flex: 4, // ✅ Proportion pour les infos (réduit de 5 à 4)
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // ✅ Important
                  children: [
                    // Nom produit (2 lignes max)
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Prix avec promotion
                    if (product.isOnSale && product.salePrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Prix barré (plus petit)
                          Text(
                            '${product.price.toStringAsFixed(3)} DT',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          // Prix soldé
                          Text(
                            '${product.salePrice!.toStringAsFixed(3)} DT',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      )
                    else
                    // Prix normal
                      Text(
                        '${product.price.toStringAsFixed(3)} DT',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}