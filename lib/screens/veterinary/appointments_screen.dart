import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../../db/database_helper.dart';
import '../../models/veterinary_appointment.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  AppointmentsScreenState createState() => AppointmentsScreenState();
}

class AppointmentsScreenState extends State<AppointmentsScreen> {
  Future<List<VeterinaryAppointment>>? _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    setState(() {
      _appointmentsFuture = DatabaseHelper.instance.getAllAppointments();
    });
  }

  Future<void> _cancelAppointment(VeterinaryAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler le rendez-vous pour ${appointment.petName} avec Dr. ${appointment.veterinaryName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.cancelAppointment(appointment.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendez-vous annulé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAppointments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'annulation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // La fonction qui prépare et appelle l'API du calendrier
  void _addAppointmentToCalendar(VeterinaryAppointment appointment) {
    final Event event = Event(
      title: 'RDV Vétérinaire pour ${appointment.petName}',
      description: 'Motif: ${appointment.reason}',
      location: 'Chez Dr. ${appointment.veterinaryName}',
      startDate: appointment.dateTime,
      endDate: appointment.dateTime.add(const Duration(hours: 1)), // On estime la durée à 1h
    );

    // Ligne qui consomme l'API externe pour ouvrir le calendrier
    Add2Calendar.addEvent2Cal(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<VeterinaryAppointment>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue lors du chargement.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucun rendez-vous', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Vos rendez-vous planifiés apparaîtront ici.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final appointments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(appointments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(VeterinaryAppointment appointment) {
    final canCancel = appointment.status == 'scheduled' && 
                     appointment.dateTime.isAfter(DateTime.now());
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(appointment.status).withOpacity(0.1),
          child: Icon(_getStatusIcon(appointment.status), color: _getStatusColor(appointment.status)),
        ),
        title: Text(
          'RDV pour ${appointment.petName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avec Dr. ${appointment.veterinaryName}'),
            Text('Le ${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year} à ${TimeOfDay.fromDateTime(appointment.dateTime).format(context)}'),
            if (appointment.status == 'cancelled')
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Annulé',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canCancel)
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: 'Annuler le rendez-vous',
                onPressed: () => _cancelAppointment(appointment),
              ),
            if (appointment.status == 'scheduled')
              IconButton(
                icon: const Icon(Icons.add_alert_outlined, color: Colors.teal),
                tooltip: 'Ajouter au calendrier',
                onPressed: () => _addAppointmentToCalendar(appointment),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'scheduled':
      default: return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'scheduled':
      default: return Icons.calendar_month;
    }
  }
}
