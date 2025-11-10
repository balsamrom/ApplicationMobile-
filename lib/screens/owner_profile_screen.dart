import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/screens/pet_list_screen.dart';
import 'package:pet_owner_app/screens/settings_screen.dart';
import 'package:pet_owner_app/screens/chatbot_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  final Owner owner;

  const OwnerProfileScreen({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Mon Espace',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen(owner: owner)),
            ),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            Text(
              "Que souhaitez-vous faire ?",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildServicesGrid(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatbotScreen(owner: owner)));
        },
        child: const Icon(Icons.chat),
        tooltip: 'Assistant PetCare',
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: owner.photoPath != null && File(owner.photoPath!).existsSync()
              ? FileImage(File(owner.photoPath!))
              : null,
          child: owner.photoPath == null || !File(owner.photoPath!).existsSync()
              ? const Icon(Icons.person, size: 35)
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bonjour,",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              owner.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildServiceCard(
          context,
          'Mes Animaux',
          Icons.pets,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PetListScreen(owner: owner)),
          ),
        ),
        _buildServiceCard(
          context,
          'Vétérinaires',
          Icons.medical_services,
          Colors.teal,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🐾 Fonctionnalité à venir')),
            );
          },
        ),
        _buildServiceCard(
          context,
          'Nutrition',
          Icons.restaurant_menu,
          Colors.lightGreen,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PetListScreen(owner: owner, purpose: 'nutrition')),
          ),
        ),
        _buildServiceCard(
          context,
          'Activité',
          Icons.directions_run,
          Colors.lightBlue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PetListScreen(owner: owner, purpose: 'activity')),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
