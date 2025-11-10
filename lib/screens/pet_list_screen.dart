import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/screens/add_pet_screen.dart';
import 'package:pet_owner_app/screens/nutrition_screen.dart';
import 'package:pet_owner_app/screens/activity_screen.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/screens/settings_screen.dart';
import 'package:pet_owner_app/services/pet_health_service.dart';
import 'package:pet_owner_app/screens/health_tracking_screen.dart';

class PetListScreen extends StatefulWidget {
  final Owner owner;
  final String? purpose; // 'nutrition' or 'activity'

  const PetListScreen({super.key, required this.owner, this.purpose});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  late Future<List<Pet>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPetList();
  }

  void _refreshPetList() {
    setState(() {
      _petsFuture = PetHealthService.getPetsWithAnalysis(widget.owner.id!);
    });
  }

  void _navigateTo(Widget page) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (result == true) {
      _refreshPetList();
    }
  }

  void _onPetSelected(Pet pet) {
    if (widget.purpose == null) {
      _navigateTo(HealthTrackingScreen(pet: pet));
    } else if (widget.purpose == 'nutrition') {
      _navigateTo(NutritionScreen(pet: pet, owner: widget.owner));
    } else if (widget.purpose == 'activity') {
      _navigateTo(ActivityScreen(pet: pet, owner: widget.owner));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purpose == 'nutrition'
            ? 'Suivi Nutritionnel'
            : widget.purpose == 'activity'
                ? 'Suivi d\'Activité'
                : 'Suivi de Santé'), // Modification du titre
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigateTo(SettingsScreen(owner: widget.owner)),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: FutureBuilder<List<Pet>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final pets = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _buildPetCard(context, pet);
            },
          );
        },
      ),
      floatingActionButton: widget.purpose == null
          ? FloatingActionButton(
              onPressed: () => _navigateTo(AddPetScreen(owner: widget.owner)),
              tooltip: 'Ajouter un animal',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Aucun animal pour le moment.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un compagnon'),
            onPressed: () => _navigateTo(AddPetScreen(owner: widget.owner)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet) {
    final analysis = pet.analysis ?? [];
    final isHealthy = analysis.isEmpty;
    final insufficientData = !isHealthy && analysis.first.startsWith('Enregistrez');
    final hasAnomalies = !isHealthy && !insufficientData;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: hasAnomalies ? Colors.red : Colors.transparent, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onPetSelected(pet),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: pet.photo != null && File(pet.photo!).existsSync()
                  ? Image.file(File(pet.photo!), fit: BoxFit.cover, height: double.infinity)
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.pets, size: 50, color: Colors.grey[400]),
                    ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // Correction du dépassement vertical
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (widget.purpose == null) _buildPopupMenu(pet),
                      ],
                    ),
                    Text(
                      pet.breed ?? pet.species,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Row(
                      children: [
                        Icon(
                          isHealthy ? Icons.check_circle : (insufficientData ? Icons.info : Icons.warning),
                          color: isHealthy ? Colors.green : (insufficientData ? Colors.grey : Colors.red),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isHealthy ? 'Routine saine' : analysis.first,
                            style: TextStyle(
                              color: isHealthy ? Colors.green : (insufficientData ? Colors.grey : Colors.red),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailChip(Icons.cake_outlined, '${pet.age ?? '?'} ans'),
                        _buildDetailChip(
                          pet.gender == 'Mâle' ? Icons.male : Icons.female,
                          pet.gender ?? '?',
                        ),
                        _buildDetailChip(Icons.monitor_weight_outlined, '${pet.weight ?? '?'} kg'),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(Pet pet) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _navigateTo(AddPetScreen(owner: widget.owner, pet: pet));
        } else if (value == 'delete') {
          _deletePet(pet.id!);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Modifier')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Supprimer', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.grey[700]),
      label: Text(label, style: const TextStyle(fontSize: 12)), // Correction de la taille de la police
      padding: const EdgeInsets.symmetric(horizontal: 4), // Correction du padding
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Colors.grey[200],
    );
  }

  void _deletePet(int petId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet animal ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deletePet(petId);
              Navigator.pop(context);
              _refreshPetList();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
