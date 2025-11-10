import 'package:flutter/material.dart';
import 'order_history_screen.dart';
import 'shop_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final int orderId;
  final int ownerId;
  final double deliveryFee;   // ✅
  final double totalAmount;   // ✅ (articles + frais)

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.ownerId,
    required this.deliveryFee,
    required this.totalAmount,
  });

  String _getEstimatedDeliveryDate() {
    final deliveryDate = DateTime.now().add(const Duration(days: 3));
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${deliveryDate.day} ${months[deliveryDate.month - 1]} ${deliveryDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation de succès
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 90,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                const Text(
                  '🎉 Commande confirmée !',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Merci pour votre confiance',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Numéro de commande
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade600]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Numéro de commande', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.tag, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '#${orderId.toString().padLeft(6, '0')}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Informations
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.email_outlined, 'Confirmation envoyée', 'Vérifiez votre email', Colors.blue),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.local_shipping_outlined, 'Livraison estimée', _getEstimatedDeliveryDate(), Colors.orange),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.track_changes, 'Suivi disponible', 'Dans "Mes commandes"', Colors.purple),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.attach_money, 'Frais de livraison', '${deliveryFee.toStringAsFixed(3)} DT', Colors.teal), // ✅
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Montant total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text('${totalAmount.toStringAsFixed(3)} DT', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nous traitons votre commande dans les plus brefs délais',
                          style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Boutons
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => OrderHistoryScreen(ownerId: ownerId)),
                            (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.history, size: 24),
                    label: const Text('Voir mes commandes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => ShopScreen(ownerId: ownerId)),
                            (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                    label: const Text('Continuer mes achats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
