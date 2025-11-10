import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/pet.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onNutrition;

  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onNutrition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: pet.photo == null
            ? const Icon(Icons.pets)
            : CircleAvatar(backgroundImage: FileImage(File(pet.photo!))),
        title: Text('${pet.name} (${pet.species})'),
        subtitle: Text('Race: ${pet.breed ?? '-'} • Age: ${pet.age ?? '-'}'),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit?.call();
            } else if (value == 'delete') {
              onDelete?.call();
            } else if (value == 'nutrition') {
              onNutrition?.call();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Modifier'),
            ),
            const PopupMenuItem(
              value: 'nutrition',
              child: Text('Nutrition'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer'),
            ),
          ],
        ),
      ),
    );
  }
}
