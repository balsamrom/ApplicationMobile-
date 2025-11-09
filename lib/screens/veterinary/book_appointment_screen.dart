import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';
import '../../models/pet.dart';
import '../../models/veterinary.dart';
import '../../models/veterinary_appointment.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Veterinary vet;
  final Owner owner;
  final VeterinaryAppointment? appointment;

  const BookAppointmentScreen({
    Key? key,
    required this.vet,
    required this.owner,
    this.appointment,
  }) : super(key: key);

  @override
  BookAppointmentScreenState createState() => BookAppointmentScreenState();
}

class BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  Pet? _selectedPet;
  late Future<List<Pet>> _petsFuture;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  // Couleurs harmonisées avec Services Vétérinaires
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    _petsFuture = DatabaseHelper.instance.getPetsByOwner(widget.owner.id!);

    if (widget.appointment != null) {
      final appointment = widget.appointment!;
      _selectedDate = appointment.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(appointment.dateTime);
      _reasonController.text = appointment.reason;

      _petsFuture.then((pets) {
        if (pets.isNotEmpty && mounted) {
          final petToSelect = pets.firstWhere((p) => p.id == appointment.petId, orElse: () => pets.first);
          setState(() {
            _selectedPet = petToSelect;
          });
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPet == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Veuillez sélectionner un animal.'),
              backgroundColor: accentOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final appointmentDateTime = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
          _selectedTime!.hour, _selectedTime!.minute
      );

      final newAppointment = VeterinaryAppointment(
        id: widget.appointment?.id,
        veterinaryId: widget.vet.owner.id!,
        veterinaryName: widget.vet.owner.name,
        petId: _selectedPet!.id!,
        petName: _selectedPet!.name,
        dateTime: appointmentDateTime,
        reason: _reasonController.text,
        status: widget.appointment?.status ?? 'scheduled',
        createdAt: widget.appointment?.createdAt ?? DateTime.now(),
      );

      if(widget.appointment == null) {
        await DatabaseHelper.instance.bookAppointment(newAppointment);
      } else {
        await DatabaseHelper.instance.updateAppointment(newAppointment);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null ? 'Prendre Rendez-vous' : 'Modifier le RDV'),
        backgroundColor: primaryPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVetInfoCard(),
              const SizedBox(height: 24),
              _buildPetSelector(),
              const SizedBox(height: 16),
              _buildDateTimePicker(),
              const SizedBox(height: 16),
              _buildReasonField(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVetInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryPurple, width: 2),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: lightPurpleBackground,
                backgroundImage: widget.vet.owner.photoPath != null && widget.vet.owner.photoPath!.isNotEmpty
                    ? FileImage(File(widget.vet.owner.photoPath!))
                    : null,
                child: (widget.vet.owner.photoPath == null || widget.vet.owner.photoPath!.isEmpty)
                    ? const Icon(Icons.person, color: primaryPurple, size: 30)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dr. ${widget.vet.owner.name}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightPurpleBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.vet.specialty ?? 'Spécialiste',
                      style: const TextStyle(
                        color: primaryPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSelector() {
    return FutureBuilder<List<Pet>>(
      future: _petsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Erreur de chargement des animaux: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryPurple),
          );
        }
        final pets = snapshot.data ?? [];
        if (pets.isEmpty) {
          return Card(
            color: lightPurpleBackground,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Vous devez ajouter un animal avant de prendre RDV.',
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryPurple),
              ),
            ),
          );
        }
        return DropdownButtonFormField<Pet>(
          value: _selectedPet,
          items: pets.map((pet) => DropdownMenuItem<Pet>(
            value: pet,
            child: Text(pet.name),
          )).toList(),
          onChanged: (value) => setState(() => _selectedPet = value),
          decoration: InputDecoration(
            labelText: 'Choisir un animal',
            labelStyle: const TextStyle(color: lightPurple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightPurple),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lightPurple),
            ),
            prefixIcon: const Icon(Icons.pets, color: primaryPurple),
          ),
          validator: (value) => value == null ? 'Veuillez sélectionner un animal' : null,
        );
      },
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: TextEditingController(
                text: _selectedDate == null ? '' : DateFormat('dd/MM/yyyy').format(_selectedDate!)
            ),
            decoration: InputDecoration(
              labelText: 'Date',
              labelStyle: const TextStyle(color: lightPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryPurple, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: lightPurple),
              ),
              prefixIcon: const Icon(Icons.calendar_today, color: primaryPurple),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: primaryPurple,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            validator: (value) => value!.isEmpty ? 'Veuillez choisir une date' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: TextEditingController(
                text: _selectedTime == null ? '' : _selectedTime!.format(context)
            ),
            decoration: InputDecoration(
              labelText: 'Heure',
              labelStyle: const TextStyle(color: lightPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryPurple, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: lightPurple),
              ),
              prefixIcon: const Icon(Icons.access_time, color: accentOrange),
            ),
            readOnly: true,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: primaryPurple,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) setState(() => _selectedTime = time);
            },
            validator: (value) => value!.isEmpty ? 'Veuillez choisir une heure' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Motif de la visite',
        labelStyle: const TextStyle(color: lightPurple),
        hintText: 'Décrivez la raison de la consultation...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPurple),
        ),
        prefixIcon: const Icon(Icons.edit_note, color: primaryPurple),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Veuillez spécifier un motif' : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: Text(
        widget.appointment == null ? 'Confirmer le RDV' : 'Mettre à jour le RDV',
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}