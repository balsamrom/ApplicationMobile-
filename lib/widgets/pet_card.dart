import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pet.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const PetCard({super.key, required this.pet, this.onTap, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: pet.photo == null ? const Icon(Icons.pets) : CircleAvatar(backgroundImage: FileImage(File(pet.photo!))),
        title: Text('${pet.name} (${pet.species})'),
        subtitle: Text('Race: ${pet.breed ?? '-'} • Age: ${pet.age ?? '-'}'),
        onTap: onTap,
        trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') onEdit?.call(); if (v == 'delete') onDelete?.call(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Modifier')), PopupMenuItem(value: 'delete', child: Text('Supprimer'))]),
      ),
    );
  }
}