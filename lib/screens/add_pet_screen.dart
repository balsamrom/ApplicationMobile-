import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/db/database_helper.dart';

class AddPetScreen extends StatefulWidget {
  final Owner owner;
  final Pet? pet;

  const AddPetScreen({super.key, required this.owner, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  String? _photoPath;

  final List<String> _speciesList = [
    'Chien', 'Chat', 'Oiseau', 'Rongeur', 'Reptile',
    'Poisson', 'Lapin', 'Furet', 'Cheval', 'Vache',
    'Mouton', 'Chèvre', 'Porc', 'Poulet', 'Canard', 'Oie', 'Dinde'
  ];

  final Map<String, List<String>> _breedMap = {
    'Chien': ['Labrador', 'Golden Retriever', 'Berger Allemand', 'Bulldog Français', 'Beagle', 'Boxer', 'Yorkshire', 'Chihuahua', 'Shih Tzu'],
    'Chat': ['Siamois', 'Persan', 'Bengal', 'Maine Coon', 'Ragdoll', 'Sphynx', 'British Shorthair', 'Norvégien', 'Scottish Fold'],
    'Oiseau': ['Perroquet', 'Canari', 'Perruche', 'Mandarin', 'Cacatoès', 'Faisan', 'Toucan'],
    'Rongeur': ['Hamster', 'Cochon d\'Inde', 'Rat', 'Souris', 'Gerbille', 'Chinchilla'],
    'Reptile': ['Tortue', 'Iguane', 'Serpent', 'Caméléon', 'Gecko'],
    'Poisson': ['Poisson Rouge', 'Betta', 'Guppy', 'Poisson Clown', 'Neon', 'Molly'],
    'Lapin': ['Nain', 'Hollandais', 'Angora', 'Fauve de Bourgogne', 'Lop', 'Rex'],
    'Furet': ['Standard', 'Albinos', 'Sable', 'Angora'],
    'Cheval': ['Arabe', 'Frison', 'Selle Français', 'Pur-Sang', 'Appaloosa', 'Clydesdale'],
    'Vache': ['Holstein', 'Charolaise', 'Limousine', 'Montbéliarde', 'Simmental'],
    'Mouton': ['Merinos', 'Suffolk', 'Romane', 'Texel', 'Dorset'],
    'Chèvre': ['Alpine', 'Saanen', 'Boer', 'Nubienne', 'Toggenburg'],
    'Porc': ['Large White', 'Landrace', 'Duroc', 'Piétrain', 'Mangalica'],
    'Poulet': ['Leghorn', 'Plymouth Rock', 'Sussex', 'Orpington', 'Rhode Island Red'],
    'Canard': ['Colvert', 'Rouen', 'Muscovy', 'Pekin', 'Coureur Indien'],
    'Oie': ['Toulouse', 'Embden', 'Romagne', 'Pilgrim'],
    'Dinde': ['Bronze', 'Noire', 'Blanche', 'Bourbon Red']
  };

  final List<String> _genderList = ['Mâle', 'Femelle'];

  String? _selectedSpecies;
  String? _selectedBreed;
  String? _selectedGender;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _ageController.text = widget.pet!.age?.toString() ?? '';
      _weightController.text = widget.pet!.weight?.toString() ?? '';
      _photoPath = widget.pet!.photo;
      _selectedSpecies = widget.pet!.species;
      _selectedBreed = widget.pet!.breed;
      _selectedGender = widget.pet!.gender;
    }
  }

  Future<void> _pickPhoto() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      final pet = Pet(
        id: widget.pet?.id,
        ownerId: widget.owner.id!,
        name: _nameController.text.trim(),
        species: _selectedSpecies!,
        breed: _selectedBreed,
        gender: _selectedGender!,
        age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text.trim()),
        weight: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text.trim()),
        photo: _photoPath,
      );

      if (widget.pet == null) {
        await DatabaseHelper.instance.insertPet(pet);
      } else {
        await DatabaseHelper.instance.updatePet(pet);
      }

      Navigator.pop(context, true); // Retourner true pour indiquer le succès
    }
  }

  @override
  Widget build(BuildContext context) {
    final breeds = _selectedSpecies != null ? _breedMap[_selectedSpecies!] ?? [] : [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        title: Text(
          widget.pet == null ? 'Ajouter un animal' : 'Modifier l\'animal',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildPhotoPicker(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) => value!.isEmpty ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSpecies,
              decoration: const InputDecoration(labelText: 'Espèce'),
              items: _speciesList
                  .map<DropdownMenuItem<String>>(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSpecies = val;
                  _selectedBreed = null;
                });
              },
              validator: (value) => value == null ? 'L\'espèce est requise' : null,
            ),
            const SizedBox(height: 16),
            if (breeds.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedBreed,
                decoration: const InputDecoration(labelText: 'Race'),
                items: breeds
                    .map<DropdownMenuItem<String>>(
                        (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBreed = val),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Genre'),
              items: _genderList
                  .map<DropdownMenuItem<String>>(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedGender = val),
              validator: (value) => value == null ? 'Le genre est requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Âge'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.pet == null ? 'Enregistrer' : 'Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _photoPath != null && File(_photoPath!).existsSync()
                ? FileImage(File(_photoPath!))
                : null,
            child: _photoPath == null || !File(_photoPath!).existsSync()
                ? const Icon(Icons.pets, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Theme.of(context).primaryColor,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _pickPhoto,
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
    );
  }
}
