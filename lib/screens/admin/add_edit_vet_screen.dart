import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';

class AddEditVetScreen extends StatefulWidget {
  final Owner? vet;

  const AddEditVetScreen({Key? key, this.vet}) : super(key: key);

  @override
  _AddEditVetScreenState createState() => _AddEditVetScreenState();
}

class _AddEditVetScreenState extends State<AddEditVetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vet != null;

    _usernameController = TextEditingController(text: _isEditing ? widget.vet!.username : '');
    _passwordController = TextEditingController();
    _nameController = TextEditingController(text: _isEditing ? widget.vet!.name : '');
  }

  Future<void> _saveVet() async {
    if (_formKey.currentState!.validate()) {
      final owner = Owner(
        id: _isEditing ? widget.vet!.id : null,
        username: _usernameController.text,
        password: _passwordController.text,
        name: _nameController.text,
        isVet: true,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateOwner(owner);
      } else {
        await DatabaseHelper.instance.insertOwner(owner);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Vétérinaire' : 'Ajouter Vétérinaire'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mot de passe', hintText: _isEditing ? 'Laisser vide pour ne pas changer' : ''),
                obscureText: true,
                validator: (value) => (!_isEditing && (value == null || value.isEmpty)) ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom complet du Dr.'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveVet,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 50)),
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
