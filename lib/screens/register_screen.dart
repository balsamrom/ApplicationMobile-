import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bcrypt/bcrypt.dart';
import '../db/database_helper.dart';
import '../models/owner.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers pour les champs de texte
  final TextEditingController _username = TextEditingController();
  final TextEditingController _name = TextEditingController(); // Ajout du nom complet
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  // Variables d'état
  bool _isVet = false;
  File? _profileImage;
  File? _diplomaImage;
  bool _isLoading = false;

  // --- Sélecteurs d'images ---
  Future<void> _pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDiplomaImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _diplomaImage = File(pickedFile.path);
      });
    }
  }

  // --- Méthode d'inscription ---
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isVet && _diplomaImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En tant que vétérinaire, le diplôme est obligatoire.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Hachage du mot de passe
      final plainPassword = _password.text.trim();
      final salt = BCrypt.gensalt();
      final hashedPassword = BCrypt.hashpw(plainPassword, salt);

      final newUser = Owner(
        username: _username.text.trim(),
        name: _name.text.trim(), // Utilisation du nom complet
        password: hashedPassword, // Sauvegarde du mot de passe haché
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        photoPath: _profileImage?.path, // Sauvegarde du chemin de la photo de profil
        isVet: _isVet,
        diplomaPath: _isVet ? _diplomaImage?.path : null,
        // Le statut de validation du vétérinaire sera géré plus tard
      );

      await DatabaseHelper.instance.insertOwner(newUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé avec succès ! Vous pouvez maintenant vous connecter.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'inscription : $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Validateurs ---
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Le champ "$fieldName" est obligatoire';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Entrez un mot de passe';
    if (value.length < 8) return '8 caractères minimum';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Au moins une majuscule';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins un chiffre';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Entrez un email';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format d’email invalide';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo de profil
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt, color: Colors.grey[800])
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Champs du formulaire
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Nom d’utilisateur', border: OutlineInputBorder()),
                validator: (val) => _validateRequired(val, 'Nom d’utilisateur'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
                validator: (val) => _validateRequired(val, 'Nom complet'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Checkbox Vétérinaire
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Je suis un professionnel vétérinaire'),
                        value: _isVet,
                        onChanged: (val) => setState(() => _isVet = val),
                      ),
                      if (_isVet)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              Text(
                                'Pour garantir la sécurité de notre plateforme, veuillez télécharger une copie de votre diplôme. Il sera vérifié par un administrateur.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _pickDiplomaImage,
                                icon: const Icon(Icons.upload_file),
                                label: Text(_diplomaImage == null ? 'Choisir un fichier' : 'Changer de fichier'),
                              ),
                              if (_diplomaImage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text('Fichier : ${_diplomaImage!.path.split('/').last}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton d'inscription
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Créer mon compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
