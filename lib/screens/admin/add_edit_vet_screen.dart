import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';
import '../../models/veterinary.dart';

class AddEditVetScreen extends StatefulWidget {
  // CORRIGÉ: Le widget attend maintenant un objet Veterinary (qui peut être nul si on ajoute)
  final Veterinary? vet;

  const AddEditVetScreen({Key? key, this.vet}) : super(key: key);

  @override
  _AddEditVetScreenState createState() => _AddEditVetScreenState();
}

class _AddEditVetScreenState extends State<AddEditVetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vet != null;

    // On initialise les contrôleurs avec les données existantes si on est en mode édition
    _usernameController = TextEditingController(text: _isEditing ? widget.vet!.owner.username : '');
    _passwordController = TextEditingController(); // Le mot de passe est toujours vide pour la sécurité
    _nameController = TextEditingController(text: _isEditing ? widget.vet!.owner.name : '');
    _specialtyController = TextEditingController(text: _isEditing ? widget.vet!.specialty : '');
    _addressController = TextEditingController(text: _isEditing ? widget.vet!.address : '');
    _latitudeController = TextEditingController(text: _isEditing ? widget.vet!.latitude?.toString() : '');
    _longitudeController = TextEditingController(text: _isEditing ? widget.vet!.longitude?.toString() : '');
  }

  Future<void> _saveVet() async {
    if (_formKey.currentState!.validate()) {
      if (_isEditing) {
        // Mode MISE À JOUR
        final dataToUpdate = {
          'name': _nameController.text,
          'specialty': _specialtyController.text,
          'address': _addressController.text,
          'latitude': double.tryParse(_latitudeController.text),
          'longitude': double.tryParse(_longitudeController.text),
          'username': _usernameController.text,
        };
        if (_passwordController.text.isNotEmpty) {
          dataToUpdate['password'] = _passwordController.text;
        }
        await DatabaseHelper.instance.updateVeterinaryProfile(dataToUpdate, widget.vet!.owner.id!);
      } else {
        // Mode CRÉATION
        final newVetOwner = Owner(
          username: _usernameController.text,
          password: _passwordController.text, // Le mot de passe est requis à la création
          name: _nameController.text,
          isVet: true,
        );
        final newVetId = await DatabaseHelper.instance.insertOwner(newVetOwner);
        final vetData = {
            'specialty': _specialtyController.text,
            'address': _addressController.text,
            'latitude': double.tryParse(_latitudeController.text),
            'longitude': double.tryParse(_longitudeController.text),
        };
        await DatabaseHelper.instance.updateVeterinaryProfile(vetData, newVetId);
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
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Spécialité'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
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
