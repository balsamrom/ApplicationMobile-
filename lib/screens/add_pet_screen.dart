import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';
import '../db/database_helper.dart';

class AddEditPetScreen extends StatefulWidget {
  final int ownerId;
  final Pet? pet;

  const AddEditPetScreen({super.key, required this.ownerId, this.pet});

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
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
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _savePet() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedSpecies == null || _selectedGender == null) return;

    final pet = Pet(
      id: widget.pet?.id,
      ownerId: widget.ownerId,
      name: name,
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final breeds = _selectedSpecies != null ? _breedMap[_selectedSpecies!] ?? [] : [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.pet == null ? 'Ajouter animal' : 'Modifier animal')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: _photoPath == null
                ? const CircleAvatar(radius: 50, child: Icon(Icons.pets, size: 50))
                : CircleAvatar(radius: 50, backgroundImage: FileImage(File(_photoPath!))),
          ),
          TextButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo),
            label: const Text('Sélectionner photo'),
          ),
          const SizedBox(height: 10),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedSpecies,
            decoration: const InputDecoration(labelText: 'Espèce'),
            isDense: true,
            items: _speciesList.map<DropdownMenuItem<String>>((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSpecies = val;
                _selectedBreed = null;
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedBreed,
            decoration: const InputDecoration(labelText: 'Race'),
            isDense: true,
            items: breeds.map<DropdownMenuItem<String>>((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: (val) => setState(() => _selectedBreed = val),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(labelText: 'Genre'),
            isDense: true,
            items: _genderList.map<DropdownMenuItem<String>>((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Âge'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Poids (kg)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _savePet, child: const Text('Enregistrer')),
        ],
      ),
    );
  }
}