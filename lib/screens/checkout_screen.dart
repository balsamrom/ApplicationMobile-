import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../db/database_helper.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount; // montant des articles (hors livraison)
  final int ownerId;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.ownerId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _deliveryMethod = 'Livraison à domicile';
  String _paymentMethod = 'Paiement à la livraison';
  bool _isProcessing = false;

  // ====== Frais en fonction de la ville ======
  final Map<String, double> _feesByCity = const {
    'tunis': 7,
    'sousse': 10,
    'sfax': 15,
  };

  String? _extractCityFromAddress(String addr) {
    final a = addr.toLowerCase();
    if (a.contains('tunis')) return 'tunis';
    if (a.contains('sousse')) return 'sousse';
    if (a.contains('sfax')) return 'sfax';
    return null;
  }

  double _computeDeliveryFee(String address) {
    final cityKey = _extractCityFromAddress(address) ?? 'other';
    return _feesByCity[cityKey] ?? 12; // par défaut 12
  }

  Future<void> _confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // 1) Frais selon l'adresse
        final addr = _addressController.text.trim();
        final double deliveryFee = _computeDeliveryFee(addr);

        // 2) Total final
        final double finalAmount = (widget.totalAmount + deliveryFee);

        // 3) Créer la commande avec deliveryFee
        final order = Order(
          ownerId: widget.ownerId,
          orderDate: DateTime.now().toIso8601String(),
          totalAmount: finalAmount,
          status: 'En cours',
          deliveryAddress: addr,
          phoneNumber: _phoneController.text.trim(),
          deliveryMethod: _deliveryMethod,
          paymentMethod: _paymentMethod,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          deliveryFee: deliveryFee, // ✅
        );

        final orderId = await txn.insert('orders', order.toMap());

        // 4) Insérer les articles
        for (var item in widget.cartItems) {
          await txn.insert('order_items', {
            'order_id': orderId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.productPrice,
          });

          // Décrémenter le stock
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item.quantity, item.productId],
          );
        }

        // 5) Vider le panier
        await txn.delete(
          'cart_items',
          where: 'owner_id = ?',
          whereArgs: [widget.ownerId],
        );

        if (!mounted) return;

        // 6) Naviguer vers la confirmation (on passe le fee)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: orderId,
              ownerId: widget.ownerId,
              deliveryFee: deliveryFee,       // ✅
              totalAmount: finalAmount,       // ✅
            ),
          ),
        );
      });
    } catch (e) {
      setState(() => _isProcessing = false);
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
    final double subtotal = widget.totalAmount;
    final double previewFee = _computeDeliveryFee(_addressController.text.trim());
    final double previewTotal = subtotal + previewFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Traitement de votre commande...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}), // pour rafraîchir le total en tapant l’adresse
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Récapitulatif
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.teal[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Récapitulatif',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ...widget.cartItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item.productName} x${item.quantity}', style: const TextStyle(fontSize: 14))),
                              Text(
                                '${(item.productPrice * item.quantity).toStringAsFixed(3)} DT',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 24),
                      _line('Sous-total', '${subtotal.toStringAsFixed(3)} DT'),
                      _line('Frais de livraison (estim.)', '${previewFee.toStringAsFixed(3)} DT'),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '${previewTotal.toStringAsFixed(3)} DT',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Informations de livraison
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.teal[700]),
                  const SizedBox(width: 8),
                  const Text('Informations de livraison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Adresse complète *',
                  hintText: 'Rue, ville, code postal (ex: ... Tunis ...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Veuillez entrer votre adresse';
                  if (value.trim().length < 10) return 'Adresse trop courte';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone *',
                  hintText: 'Ex: 20 123 456',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Veuillez entrer votre numéro';
                  if (value.trim().length < 8) return 'Numéro invalide';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Mode de livraison
              Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.teal[700]),
                  const SizedBox(width: 8),
                  const Text('Mode de livraison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Livraison à domicile'),
                      subtitle: const Text('Délai: 2-3 jours ouvrables'),
                      value: 'Livraison à domicile',
                      groupValue: _deliveryMethod,
                      onChanged: (value) => setState(() => _deliveryMethod = value!),
                      secondary: const Icon(Icons.home),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('Retrait en magasin'),
                      subtitle: const Text('Gratuit - Disponible dès demain'),
                      value: 'Retrait en magasin',
                      groupValue: _deliveryMethod,
                      onChanged: (value) => setState(() => _deliveryMethod = value!),
                      secondary: const Icon(Icons.store),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mode de paiement
              Row(
                children: [
                  Icon(Icons.payment, color: Colors.teal[700]),
                  const SizedBox(width: 8),
                  const Text('Mode de paiement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Paiement à la livraison'),
                      subtitle: const Text('En espèces ou par carte'),
                      value: 'Paiement à la livraison',
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value!),
                      secondary: const Icon(Icons.money),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('Carte bancaire (Simulation)'),
                      subtitle: const Text('Paiement sécurisé en ligne'),
                      value: 'Carte bancaire',
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value!),
                      secondary: const Icon(Icons.credit_card),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              Row(
                children: [
                  Icon(Icons.note, color: Colors.teal[700]),
                  const SizedBox(width: 8),
                  const Text('Notes (optionnel)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Précisions sur la livraison, instructions...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Bouton Commander
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _confirmOrder,
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text('Confirmer la commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
