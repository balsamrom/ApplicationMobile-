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
import 'package:pet_owner_app/screens/blog_list_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  final Owner owner;

  const OwnerProfileScreen({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        title: const Text(
          'Mon Espace',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatbotScreen(owner: owner)),
            );
          },
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          tooltip: 'Assistant PetCare',
        ),
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

        // 📝 Blogs Vétérinaires
        _buildServiceCard(
          context,
          'Blogs Vétérinaires',
          Icons.article,
          Colors.indigo,
              () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BlogListScreen(owner: owner)),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // 🛍️ Carte spéciale profil / boutique en ligne
  // --------------------------------------------------------------
  Widget _buildProfileCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
