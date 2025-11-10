import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Owner owner;
  const SettingsScreen({super.key, required this.owner});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Owner _currentOwner;

  @override
  void initState() {
    super.initState();
    _currentOwner = widget.owner;
  }

  ImageProvider? _getImageProvider(String? path) {
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildSectionTitle('Compte'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Modifier le profil',
            onTap: _editProfile,
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            onTap: () { /* TODO: Implement change password */ },
          ),
          const Divider(),
          _buildSectionTitle('Application'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none),
            title: const Text('Notifications'),
            value: true, // Replace with actual notification state
            onChanged: (bool value) { /* TODO: Handle notification state */ },
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Langue',
            trailing: const Text('Français'),
            onTap: () { /* TODO: Implement language selection */ },
          ),
          const Divider(),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Déconnexion',
            color: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final backgroundImage = _getImageProvider(_currentOwner.photoPath);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: backgroundImage,
            child: backgroundImage == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentOwner.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                _currentOwner.email ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[600]),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _currentOwner.name);
    final phoneController = TextEditingController(text: _currentOwner.phone ?? '');
    String? tempPhotoPath = _currentOwner.photoPath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dialogBackgroundImage = _getImageProvider(tempPhotoPath);

          return AlertDialog(
            title: const Text('Modifier le profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: dialogBackgroundImage,
                        child: dialogBackgroundImage == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Theme.of(context).primaryColor,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () async {
                              final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setDialogState(() {
                                  tempPhotoPath = pickedFile.path;
                                });
                              }
                            },
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
                  TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Téléphone')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  final updatedOwner = _currentOwner.copyWith(
                    name: nameController.text,
                    phone: phoneController.text,
                    photoPath: tempPhotoPath,
                  );
                  await DatabaseHelper.instance.updateOwner(updatedOwner);
                  setState(() {
                    _currentOwner = updatedOwner;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
