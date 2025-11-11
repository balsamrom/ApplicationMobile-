import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bcrypt/bcrypt.dart';
import '../db/database_helper.dart';
import '../models/owner.dart';
import 'login_screen.dart';
import '../widgets/auth_background.dart';
import '../theme/app_theme.dart';

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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Photo de profil
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? Icon(Icons.camera_alt, color: Colors.white, size: 40)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Champs du formulaire
                  _buildFormField(
                    controller: _username,
                    label: 'Nom d'utilisateur',
                    icon: Icons.person_outline,
                    validator: (val) => _validateRequired(val, 'Nom d'utilisateur'),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    controller: _name,
                    label: 'Nom complet',
                    icon: Icons.badge_outlined,
                    validator: (val) => _validateRequired(val, 'Nom complet'),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    controller: _password,
                    label: 'Mot de passe',
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    controller: _phone,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // Checkbox Vétérinaire
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text(
                              'Je suis un professionnel vétérinaire',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            value: _isVet,
                            onChanged: (val) => setState(() => _isVet = val),
                            activeColor: AppTheme.primaryColor,
                          ),
                          if (_isVet)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  Text(
                                    'Pour garantir la sécurité de notre plateforme, veuillez télécharger une copie de votre diplôme. Il sera vérifié par un administrateur.',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.secondaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: OutlinedButton.icon(
                                      onPressed: _pickDiplomaImage,
                                      icon: const Icon(Icons.upload_file, color: Colors.white),
                                      label: Text(
                                        _diplomaImage == null ? 'Choisir un fichier' : 'Changer de fichier',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide.none,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  if (_diplomaImage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        'Fichier : ${_diplomaImage!.path.split('/').last}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Bouton d'inscription
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Créer mon compte',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Login Link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Déjà un compte ? Se connecter',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
