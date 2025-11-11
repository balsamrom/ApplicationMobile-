import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../models/owner.dart';
import '../../models/pet.dart';
import '../../models/veterinary_appointment.dart';
import '../../db/database_helper.dart';
import 'book_appointment_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Owner patient;
  final int vetId;

  const PatientDetailScreen({
    Key? key,
    required this.patient,
    required this.vetId,
  }) : super(key: key);

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Future<List<dynamic>> _dataFuture;

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        DatabaseHelper.instance.getPetsByOwner(widget.patient.id!),
        DatabaseHelper.instance.getAppointmentsForVeterinary(widget.vetId),
        DatabaseHelper.instance.getOwnerById(widget.vetId), // Fetch vet details
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de ${widget.patient.name}'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientContactCard(),
            const SizedBox(height: 24),
            const Text(
              'Animaux et Dossiers Médicaux',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
            const SizedBox(height: 10),
            _buildPetsAndHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientContactCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Informations du Client',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20, thickness: 1),
          ListTile(
            leading: const Icon(Icons.person, color: primaryPurple),
            title: Text(widget.patient.name),
          ),
          if (widget.patient.phone != null)
            ListTile(
              leading: const Icon(Icons.phone, color: accentOrange),
              title: Text(widget.patient.phone!),
            ),
          if (widget.patient.email != null)
            ListTile(
              leading: const Icon(Icons.email, color: lightPurple),
              title: Text(widget.patient.email!),
            ),
        ]),
      ),
    );
  }

  Widget _buildPetsAndHistoryList() {
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryPurple),
          );
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return Center(child: Text('Erreur de chargement des données: ${snapshot.error}'));
        }

        final pets = snapshot.data![0] as List<Pet>;
        final allVetAppointments =
            snapshot.data![1] as List<VeterinaryAppointment>;
        final vet = snapshot.data![2] as Owner?;

        if (vet == null) {
          return const Center(child: Text('Vétérinaire non trouvé.'));
        }

        if (pets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Ce patient n\'a pas encore enregistré d\'animaux.'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            final petHistory =
                allVetAppointments.where((a) => a.petId == pet.id).toList();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: lightPurpleBackground,
                  child: const Icon(Icons.pets, color: primaryPurple),
                ),
                title: Text(
                  pet.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryPurple,
                  ),
                ),
                subtitle:
                    Text('${pet.species} - ${pet.breed ?? 'Race inconnue'}'),
                children: [
                  if (petHistory.isEmpty)
                    const ListTile(
                      title: Text(
                        'Aucun historique de consultation pour cet animal.',
                      ),
                    )
                  else
                    ...petHistory.map((appointment) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: Colors.white,
                        elevation: 1,
                        child: ListTile(
                          title: Text(
                            'Date: ${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                          ),
                          subtitle: Text(
                            'Motif: ${appointment.reason}\nNotes: ${appointment.notes ?? 'Aucune'}',
                          ),
                          trailing:
                              const Icon(Icons.edit_note, color: accentOrange),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookAppointmentScreen(
                                  vet: vet,
                                  owner: widget.patient,
                                  appointment: appointment,
                                ),
                              ),
                            ).then((_) => _loadData());
                          },
                        ),
                      );
                    }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
