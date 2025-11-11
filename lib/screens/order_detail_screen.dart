import 'package:flutter/material.dart';
import '../models/order.dart';
import '../db/database_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<OrderItem> _items = [];
  bool _isLoading = true;

  // Statuts possibles
  final List<String> _statuses = [
    'En cours',
    'En préparation',
    'En livraison',
    'Livrée'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
  }

  Future<void> _loadOrderItems() async {
    setState(() => _isLoading = true);
    final items =
    await DatabaseHelper.instance.getOrderItems(widget.order.id!);
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  int get _currentStatusIndex {
    return _statuses.indexOf(widget.order.status);
  }

  Color _getStatusColor(int index) {
    if (index < _currentStatusIndex) return Colors.green;
    if (index == _currentStatusIndex) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'En cours':
        return Icons.shopping_bag;
      case 'En préparation':
        return Icons.inventory;
      case 'En livraison':
        return Icons.local_shipping;
      case 'Livrée':
        return Icons.check_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    await DatabaseHelper.instance
        .updateOrderStatus(widget.order.id!, newStatus);
    setState(() {
      widget.order.status = newStatus;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses.map((status) {
            return RadioListTile<String>(
              title: Text(status),
              value: status,
              groupValue: widget.order.status,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context);
                  _updateStatus(value);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusDescription(
      String status, bool isCompleted, bool isCurrent) {
    if (isCompleted) {
      return '✓ Complété';
    }
    if (isCurrent) {
      switch (status) {
        case 'En cours':
          return 'Votre commande a été reçue';
        case 'En préparation':
          return 'Nous préparons votre commande';
        case 'En livraison':
          return 'Votre commande est en route';
        case 'Livrée':
          return 'Commande livrée avec succès';
        default:
          return '';
      }
    }
    return 'En attente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${widget.order.id}'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showStatusChangeDialog,
            tooltip: 'Modifier le statut',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== EN-TÊTE ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade600],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Montant Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.order.totalAmount.toStringAsFixed(3)} DT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(widget.order.orderDate),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ========== TIMELINE DE STATUT ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suivi de commande',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTimeline(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ========== ADRESSE DE LIVRAISON ==========
            if (widget.order.deliveryAddress != null &&
                widget.order.deliveryAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adresse de livraison',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on,
                              color: Colors.teal[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.order.deliveryAddress!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ========== DÉTAILS COMMANDE ==========
            if (widget.order.phoneNumber != null ||
                widget.order.deliveryMethod != null ||
                widget.order.paymentMethod != null ||
                (widget.order.notes != null &&
                    widget.order.notes!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails de la commande',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          if (widget.order.phoneNumber != null)
                            _buildDetailRow(
                              Icons.phone,
                              'Téléphone',
                              widget.order.phoneNumber!,
                            ),
                          if (widget.order.deliveryMethod != null)
                            _buildDetailRow(
                              Icons.local_shipping,
                              'Mode de livraison',
                              widget.order.deliveryMethod!,
                            ),
                          if (widget.order.paymentMethod != null)
                            _buildDetailRow(
                              Icons.payment,
                              'Mode de paiement',
                              widget.order.paymentMethod!,
                            ),
                          if (widget.order.notes != null &&
                              widget.order.notes!.isNotEmpty)
                            _buildDetailRow(
                              Icons.note,
                              'Notes',
                              widget.order.notes!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ========== DÉTAILS COMMANDE ==========
            if (widget.order.phoneNumber != null ||
                widget.order.deliveryMethod != null ||
                widget.order.paymentMethod != null ||
                (widget.order.notes != null &&
                    widget.order.notes!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails de la commande',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          if (widget.order.phoneNumber != null)
                            _buildDetailRow(
                              Icons.phone,
                              'Téléphone',
                              widget.order.phoneNumber!,
                            ),
                          if (widget.order.deliveryMethod != null)
                            _buildDetailRow(
                              Icons.local_shipping,
                              'Mode de livraison',
                              widget.order.deliveryMethod!,
                            ),
                          if (widget.order.paymentMethod != null)
                            _buildDetailRow(
                              Icons.payment,
                              'Mode de paiement',
                              widget.order.paymentMethod!,
                            ),
                          if (widget.order.notes != null &&
                              widget.order.notes!.isNotEmpty)
                            _buildDetailRow(
                              Icons.note,
                              'Notes',
                              widget.order.notes!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ========== PRODUITS COMMANDÉS ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produits commandés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._items.map((item) => _buildOrderItemCard(item)),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: List.generate(_statuses.length, (index) {
        final status = _statuses[index];
        final isCompleted = index < _currentStatusIndex;
        final isCurrent = index == _currentStatusIndex;
        final color = _getStatusColor(index);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline à gauche
              Column(
                children: [
                  // Icône
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? color
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : _getStatusIcon(status),
                      color: isCompleted || isCurrent
                          ? Colors.white
                          : Colors.grey,
                      size: 24,
                    ),
                  ),
                  // Ligne verticale
                  if (index < _statuses.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isCompleted ? color : Colors.grey[300],
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Contenu à droite
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w600,
                          color:
                          isCompleted || isCurrent ? color : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(status, isCompleted, isCurrent),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal[700], size: 20),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              Icon(Icons.shopping_bag, color: Colors.teal[700], size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantité: ${item.quantity}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${item.totalPrice.toStringAsFixed(3)} DT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}