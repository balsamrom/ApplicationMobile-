import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/owner.dart';
import '../data/first_aid_data.dart';
import '../models/first_aid_item.dart';
import 'first_aid_detail_screen.dart';

class FirstAidScreen extends StatefulWidget {
  final Owner owner;
  const FirstAidScreen({super.key, required this.owner});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  bool _isOffline = false;

  // Fonction pour obtenir l'icône selon le type d'urgence
  IconData _getIconForItem(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('cardiaque') || lowerTitle.contains('cœur') || lowerTitle.contains('coeur')) {
      return Icons.favorite;
    } else if (lowerTitle.contains('hémorragie') || lowerTitle.contains('hemorragie') || lowerTitle.contains('saignement')) {
      return Icons.water_drop;
    } else if (lowerTitle.contains('intoxication') || lowerTitle.contains('empoisonnement') || lowerTitle.contains('poison')) {
      return Icons.warning;
    } else if (lowerTitle.contains('chaleur') || lowerTitle.contains('hyperthermie') || lowerTitle.contains('température') || lowerTitle.contains('temperature')) {
      return Icons.thermostat;
    } else if (lowerTitle.contains('brûlure') || lowerTitle.contains('brulure')) {
      return Icons.local_fire_department;
    } else if (lowerTitle.contains('fracture') || lowerTitle.contains('cassure') || lowerTitle.contains('os') || lowerTitle.contains('brisé')) {
      return Icons.accessible;
    } else if (lowerTitle.contains('étouffement') || lowerTitle.contains('etouffement') || lowerTitle.contains('respiration')) {
      return Icons.air;
    } else if (lowerTitle.contains('morsure') || lowerTitle.contains('piqûre') || lowerTitle.contains('piqure')) {
      return Icons.pets;
    } else if (lowerTitle.contains('convulsion') || lowerTitle.contains('crise')) {
      return Icons.electric_bolt;
    } else if (lowerTitle.contains('plaie') || lowerTitle.contains('blessure')) {
      return Icons.healing;
    } else {
      return Icons.medical_services;
    }
  }

  // Fonction pour obtenir le badge de priorité
  Widget _getPriorityBadge(String priority) {
    Color bgColor;
    String text;

    switch (priority.toLowerCase()) {
      case 'critique':
        bgColor = const Color(0xFFE53935);
        text = 'CRITIQUE';
        break;
      case 'urgent':
        bgColor = const Color(0xFFFF6F00);
        text = 'URGENT';
        break;
      case 'modere':
        bgColor = const Color(0xFFFFA726);
        text = 'MODÉRÉ';
        break;
      default:
        bgColor = Colors.grey;
        text = 'INFO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Trousse de premiers secours',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white70, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Mode Offline',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Bannière "Fiches disponibles hors ligne"
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fiches disponibles hors ligne',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accès garanti sans connexion internet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Titre de section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.emergency, color: Colors.red.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Urgences par priorité',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),

          // Liste des urgences
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: firstAidItems.length,
              itemBuilder: (context, index) {
                final item = firstAidItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FirstAidDetailScreen(
                              item: item,
                              owner: widget.owner,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Icône circulaire
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: item.priorityColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForItem(item.title),
                                color: item.priorityColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Contenu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF212121),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _getPriorityBadge(item.priority.toString().split('.').last),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Agir en ${item.timeToAction}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Flèche
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Numéros d'urgence
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9800), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_in_talk, color: Colors.orange.shade700, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Numéros d\'urgence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appel du centre antipoison vétérinaire...'),
                        backgroundColor: Color(0xFF009688),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Centre antipoison vétérinaire',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.phone, color: Colors.red.shade600, size: 22),
                      ],
                    ),
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