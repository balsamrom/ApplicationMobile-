import 'package:flutter/material.dart';
import '../../db/database_helper.dart'; // Import corrigé
import '../../models/veterinary_appointment.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({Key? key}) : super(key: key);

  @override
  AppointmentListScreenState createState() => AppointmentListScreenState();
}

class AppointmentListScreenState extends State<AppointmentListScreen> {
  late Future<List<VeterinaryAppointment>> _appointments;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    setState(() {
      // Appel corrigé pour utiliser directement le DatabaseHelper
      _appointments = DatabaseHelper.instance.getAllAppointments();
    });
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    // Appel corrigé pour utiliser directement le DatabaseHelper
    await DatabaseHelper.instance.cancelAppointment(appointmentId);
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: FutureBuilder<List<VeterinaryAppointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun rendez-vous trouvé.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final appointment = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('Rendez-vous pour ${appointment.petName}'),
                    subtitle: Text('Avec Dr. ${appointment.veterinaryName} le ${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year} à ${appointment.dateTime.hour}:${appointment.dateTime.minute}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _cancelAppointment(appointment.id!),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
