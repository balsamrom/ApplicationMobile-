import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/owner.dart';
import '../../models/cabinet.dart';
import '../../db/database_helper.dart';

class VetProfileEditorScreen extends StatefulWidget {
  final Owner vet;
  final Cabinet? cabinet;

  const VetProfileEditorScreen({
    Key? key,
    required this.vet,
    this.cabinet,
  }) : super(key: key);

  @override
  _VetProfileEditorScreenState createState() => _VetProfileEditorScreenState();
}

class _VetProfileEditorScreenState extends State<VetProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _diplomaController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String? _profileImagePath;

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vet.name);
    _emailController = TextEditingController(text: widget.vet.email ?? '');
    _phoneController = TextEditingController(text: widget.vet.phone ?? '');
    _diplomaController = TextEditingController(text: widget.vet.diplomaPath ?? '');
    _profileImagePath = widget.vet.photoPath;

    final cab = widget.cabinet;
    _addressController = TextEditingController(text: cab?.address ?? '');
    _latitudeController = TextEditingController(text: cab?.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: cab?.longitude?.toString() ?? '');
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImagePath = pickedFile.path);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // --- Mise à jour du Owner (vétérinaire)
    final updatedVet = widget.vet.copyWith(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      photoPath: _profileImagePath,
      diplomaPath: _diplomaController.text,
    );

    await DatabaseHelper.instance.updateOwner(updatedVet);

    // --- Sauvegarde / mise à jour du Cabinet
    final newCabinet = Cabinet(
      veterinaryId: widget.vet.id!,
      address: _addressController.text,
      latitude: double.tryParse(_latitudeController.text),
      longitude: double.tryParse(_longitudeController.text),
    );
    await DatabaseHelper.instance.saveCabinet(newCabinet);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis à jour avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        backgroundColor: primaryPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker('Photo de profil', _profileImagePath, _pickImage),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Nom complet',
                icon: Icons.person,
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _diplomaController,
                label: 'Diplôme ou spécialité',
                icon: Icons.school,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Informations du Cabinet'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Adresse du cabinet',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      icon: Icons.map,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      icon: Icons.map,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, String? imagePath, VoidCallback onPick) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryPurple)),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryPurple, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: imagePath != null && imagePath.isNotEmpty
                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                    : Container(
                  color: lightPurpleBackground,
                  child: const Icon(Icons.person, size: 80, color: primaryPurple),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: accentOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: onPick,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: lightPurple),
        prefixIcon: Icon(icon, color: primaryPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPurple),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryPurple)),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveProfile,
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'Enregistrer les modifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      ),
    );
  }
}
