import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../db/database_helper.dart';
import '../models/owner.dart';
import 'login_screen.dart';
import 'owner_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  bool _isVet = false;
  File? _diplomaImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _diplomaImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _username.text.trim();
    final password = _password.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();

    // Enregistrement dans la base locale
    final owner = Owner(
      username: username,
      password: password,
      email: email,
      phone: phone,
      isVet: _isVet,
      diplomaPath: _isVet ? _diplomaImage?.path : null, name: '',
    );

    await DatabaseHelper.instance.insertOwner(owner);

    // Redirection selon le rôle
    if (_isVet) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Nom d’utilisateur'),
                validator: (value) => value!.isEmpty ? 'Entrez un nom d’utilisateur' : null,
              ),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                validator: (value) => value!.isEmpty ? 'Entrez un mot de passe' : null,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Entrez un email' : null,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (value) => value!.isEmpty ? 'Entrez un numéro' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _isVet,
                    onChanged: (val) => setState(() => _isVet = val!),
                  ),
                  const Text('Je suis vétérinaire'),
                ],
              ),
              if (_isVet) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Uploader diplôme'),
                ),
                if (_diplomaImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(_diplomaImage!, height: 150),
                  ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Créer mon compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

