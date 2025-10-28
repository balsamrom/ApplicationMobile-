import 'dart:io';
import 'package:flutter/material.dart';
import '../models/owner.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final Owner owner;
  const SettingsScreen({super.key, required this.owner});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _language = 'Français';
  bool _private = true;

  Future<void> _updateSettings() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres modifiés')),
    );
  }

  // Ouvre la fenêtre de modification du profil
  void _editProfile() {
    final nameController = TextEditingController(text: widget.owner.name);
    final emailController = TextEditingController(text: widget.owner.email ?? '');
    final phoneController = TextEditingController(text: widget.owner.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.owner.photoPath != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: FileImage(File(widget.owner.photoPath!)),
                )
              else
                const CircleAvatar(radius: 40, child: Icon(Icons.person)),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = Owner(
                id: widget.owner.id,
                username: widget.owner.username,
                password: widget.owner.password,
                name: nameController.text.trim(),
                photoPath: widget.owner.photoPath,
                email: emailController.text.trim(),
                phone: phoneController.text.trim(),
              );
              await DatabaseHelper.instance.updateOwner(updated);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil mis à jour avec succès')),
              );
              setState(() {}); // rafraîchir si nécessaire
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
              title: const Text('Notifications'),
            ),
            ListTile(
              title: const Text('Langue'),
              trailing: DropdownButton<String>(
                value: _language,
                items: ['Français', 'Anglais']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _language = v ?? _language),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.person),
              label: const Text('Modifier le profil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
