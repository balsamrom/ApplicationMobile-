
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/veterinary_appointment.dart';
import '../../db/database_helper.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final VeterinaryAppointment appointment;

  const AppointmentDetailScreen({Key? key, required this.appointment}) : super(key: key);

  @override
  _AppointmentDetailScreenState createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _treatmentsController;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.appointment.notes);
    _treatmentsController = TextEditingController(text: widget.appointment.treatments);
    _status = widget.appointment.status;
  }

  Future<void> _updateAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final updatedAppointment = VeterinaryAppointment(
        id: widget.appointment.id,
        veterinaryId: widget.appointment.veterinaryId,
        veterinaryName: widget.appointment.veterinaryName,
        petId: widget.appointment.petId,
        petName: widget.appointment.petName,
        dateTime: widget.appointment.dateTime,
        reason: widget.appointment.reason,
        createdAt: widget.appointment.createdAt,
        status: _status,
        notes: _notesController.text,
        treatments: _treatmentsController.text,
      );

      await DatabaseHelper.instance.updateAppointment(updatedAppointment);

      setState(() => _isLoading = false);

      Navigator.of(context).pop(true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rendez-vous mis à jour avec succès.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du rendez-vous'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _updateAppointment,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    SizedBox(height: 20),
                    _buildEditFields(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${widget.appointment.petName}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.appointment.dateTime)}'),
            SizedBox(height: 8),
            Text('Motif: ${widget.appointment.reason}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEditFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(labelText: 'Statut du rendez-vous'),
          items: ['scheduled', 'completed', 'cancelled'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _status = newValue!;
            });
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(labelText: 'Notes cliniques', border: OutlineInputBorder()),
          maxLines: 5,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _treatmentsController,
          decoration: InputDecoration(labelText: 'Traitements prescrits', border: OutlineInputBorder()),
          maxLines: 5,
        ),
      ],
    );
  }
}
