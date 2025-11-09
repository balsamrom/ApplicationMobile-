import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/owner.dart';
import '../../models/veterinary.dart';
import './book_appointment_screen.dart';

class VeterinaryDetailScreen extends StatelessWidget {
  final Veterinary vet;
  final Owner owner; // L'utilisateur qui consulte la page

  // Couleurs harmonisées avec Services Vétérinaires
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  const VeterinaryDetailScreen({
    Key? key,
    required this.vet,
    required this.owner,
  }) : super(key: key);

  Future<void> _launchMaps(BuildContext context) async {
    if (vet.latitude != null && vet.longitude != null) {
      final query = '${vet.latitude},${vet.longitude}';
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Impossible d\'ouvrir Google Maps.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Coordonnées GPS non disponibles pour ce vétérinaire.'),
            backgroundColor: accentOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${vet.owner.name}'),
        backgroundColor: primaryPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // En-tête avec dégradé
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryPurple,
                    primaryPurple.withOpacity(0.1),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: lightPurpleBackground,
                        backgroundImage: vet.owner.photoPath != null && vet.owner.photoPath!.isNotEmpty
                            ? FileImage(File(vet.owner.photoPath!))
                            : null,
                        child: (vet.owner.photoPath == null || vet.owner.photoPath!.isEmpty)
                            ? const Icon(Icons.person, size: 60, color: primaryPurple)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dr. ${vet.owner.name}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: lightPurpleBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vet.specialty ?? 'Spécialité non définie',
                        style: const TextStyle(
                          fontSize: 16,
                          color: primaryPurple,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.location_on,
                            vet.address ?? 'Adresse non fournie',
                            accentOrange,
                          ),
                          const Divider(height: 24, thickness: 1),
                          _buildInfoRow(
                            Icons.phone,
                            vet.owner.phone ?? 'Téléphone non fourni',
                            primaryPurple,
                          ),
                          const Divider(height: 24, thickness: 1),
                          _buildInfoRow(
                            Icons.email,
                            vet.owner.email ?? 'Email non fourni',
                            lightPurple,
                          ),
                          const Divider(height: 24, thickness: 1),
                          _buildInfoRow(
                            Icons.star,
                            '${vet.rating?.toStringAsFixed(1) ?? 'N/A'} / 5.0',
                            Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionButton(
                    context,
                    label: 'Prendre rendez-vous',
                    icon: Icons.calendar_today,
                    color: primaryPurple,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookAppointmentScreen(
                            vet: vet,
                            owner: owner,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    label: 'Voir sur la carte',
                    icon: Icons.map,
                    color: accentOrange,
                    onPressed: () => _launchMaps(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}