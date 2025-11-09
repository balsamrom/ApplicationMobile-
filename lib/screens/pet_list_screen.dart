import 'dart:io';
import 'package:flutter/material.dart';
import '../models/owner.dart';
import '../models/pet.dart';
import '../db/database_helper.dart';
import 'add_pet_screen.dart';

class PetListScreen extends StatefulWidget {
  final Owner owner;
  const PetListScreen({super.key, required this.owner});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  List<Pet> pets = [];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final list = await DatabaseHelper.instance.getPetsByOwner(widget.owner.id!);
    setState(() => pets = list);
  }

  Future<void> _deletePet(int id) async {
    await DatabaseHelper.instance.deletePet(id);
    _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mes animaux (${widget.owner.name})')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditPetScreen(ownerId: widget.owner.id!)),
          );
          _loadPets();
        },
        child: const Icon(Icons.add),
      ),
      body: pets.isEmpty
          ? const Center(child: Text('Aucun animal'))
          : ListView.builder(
        itemCount: pets.length,
        itemBuilder: (_, i) {
          final pet = pets[i];
          return Card(
            child: ListTile(
              leading: pet.photo == null ? const Icon(Icons.pets) : CircleAvatar(backgroundImage: FileImage(File(pet.photo!))),
              title: Text('${pet.name} (${pet.species})'),
              subtitle: Text('Race: ${pet.breed ?? "-"} • Age: ${pet.age ?? "-"}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditPetScreen(ownerId: widget.owner.id!, pet: pet)),
                    );
                    _loadPets();
                  }
                  if (v == 'delete') {
                    await _deletePet(pet.id!);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}