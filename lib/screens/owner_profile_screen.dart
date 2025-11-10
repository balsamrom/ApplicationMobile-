import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/screens/pet_list_screen.dart';
import 'package:pet_owner_app/screens/settings_screen.dart';
import 'package:pet_owner_app/screens/chatbot_screen.dart';
import 'package:pet_owner_app/screens/shop_screen.dart';
import 'package:pet_owner_app/screens/veterinary/simple_vet_screen.dart';
import 'package:pet_owner_app/screens/veterinary/book_search_screen.dart';
import 'package:pet_owner_app/screens/first_aid_screen.dart'; // ✅ ajout import

class OwnerProfileScreen extends StatelessWidget {
  final Owner owner;

  const OwnerProfileScreen({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        title: const Text(
          'Mon Espace',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Paramètres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen(owner: owner)),
            ),
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildServicesGrid(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatbotScreen(owner: owner)),
          );
        },
        child: const Icon(Icons.chat),
        tooltip: 'Assistant PetCare',
      ),
    );
  }

  // --------------------------------------------------------------
  // 🧩 En-tête utilisateur
  // --------------------------------------------------------------
  Widget _buildWelcomeHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: owner.photoPath != null &&
              File(owner.photoPath!).existsSync()
              ? FileImage(File(owner.photoPath!))
              : null,
          child: owner.photoPath == null ||
              !File(owner.photoPath!).existsSync()
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

  // --------------------------------------------------------------
  // 🧩 Grille des services disponibles
  // --------------------------------------------------------------
  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 🐶 Mes Animaux
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

        // 🩺 Vétérinaires
        _buildServiceCard(
          context,
          'Vétérinaires',
          Icons.medical_services,
          Colors.teal,
              () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SimpleVetScreen(owner: owner)),
          ),
        ),

        // 📚 Bibliothèque
        _buildServiceCard(
          context,
          'Bibliothèque',
          Icons.book_outlined,
          Colors.blue,
              () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookSearchScreen()),
          ),
        ),

        // 🥕 Nutrition
        _buildServiceCard(
          context,
          'Nutrition',
          Icons.restaurant_menu,
          Colors.lightGreen,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PetListScreen(owner: owner, purpose: 'nutrition'),
            ),
          ),
        ),

        // 🏃 Activité
        _buildServiceCard(
          context,
          'Activité',
          Icons.directions_run,
          Colors.lightBlue,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PetListScreen(owner: owner, purpose: 'activity'),
            ),
          ),
        ),

        // 🚑 Trousse de premiers secours (visible uniquement si ce n’est pas un vétérinaire)
        if (!owner.isVet)
          _buildServiceCard(
            context,
            'Trousse de premiers secours',
            Icons.healing,
            Colors.red,
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FirstAidScreen(owner: owner)),
            ),
          ),

        // 🛍️ Boutique en ligne (carte stylée)
        _buildProfileCard(
          'Shop',
          'Boutique en ligne',
          Icons.shopping_bag,
          Colors.purpleAccent,
              () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ShopScreen(ownerId: owner.id ?? 0)),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------
  // 🧩 Carte de service standard
  // --------------------------------------------------------------
  Widget _buildServiceCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
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
            ),
          ],
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

  // --------------------------------------------------------------
  // 🛍️ Carte spéciale profil / boutique en ligne
  // --------------------------------------------------------------
  Widget _buildProfileCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
