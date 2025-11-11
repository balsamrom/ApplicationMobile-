import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/owner.dart';
import '../../models/cabinet.dart';
import './book_appointment_screen.dart';

class VeterinaryDetailScreen extends StatelessWidget {
  final Owner vet;   // Vétérinaire = Owner avec isVet = 1
  final Owner owner; // Utilisateur connecté (client)
  final Cabinet? cabinet;

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  const VeterinaryDetailScreen({
    Key? key,
    required this.vet,
    required this.owner,
    this.cabinet,
  }) : super(key: key);

  Future<void> _launchMaps(BuildContext context) async {
    if (cabinet?.latitude != null && cabinet?.longitude != null) {
      final query = '${cabinet!.latitude},${cabinet!.longitude}';
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _showSnack(context, 'Impossible d\'ouvrir Google Maps.', Colors.red);
        }
      }
    } else {
      if (context.mounted) {
        _showSnack(context, 'Coordonnées GPS non disponibles pour ce cabinet.', accentOrange);
      }
    }
  }

  void _showSnack(BuildContext context, String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${vet.name}'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ----- En-tête -----
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryPurple, primaryPurple.withOpacity(0.1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: lightPurpleBackground,
                    backgroundImage: vet.photoPath != null && vet.photoPath!.isNotEmpty
                        ? FileImage(File(vet.photoPath!))
                        : null,
                    child: (vet.photoPath == null || vet.photoPath!.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: primaryPurple)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dr. ${vet.name}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vet.diplomaPath != null
                          ? 'Vétérinaire diplômé'
                          : 'Profil en attente de validation',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ----- Infos principales -----
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.location_on, cabinet?.address ?? 'Adresse non fournie', accentOrange),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.phone, vet.phone ?? 'Téléphone non fourni', primaryPurple),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.email, vet.email ?? 'Email non fourni', lightPurple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ----- Boutons d’action -----
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

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
