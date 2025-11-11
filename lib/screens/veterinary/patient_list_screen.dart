import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';
import '../../models/pet.dart';
import '../../models/veterinary_appointment.dart';
import 'patient_detail_screen.dart';

class _PatientInfo {
  final Owner patient;
  final int petCount;
  final DateTime? lastVisit;

  _PatientInfo({
    required this.patient,
    required this.petCount,
    this.lastVisit,
  });
}

class PatientListScreen extends StatefulWidget {
  final int vetId; // ✅ On utilise l’ID du vétérinaire
  const PatientListScreen({Key? key, required this.vetId}) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  late Future<List<_PatientInfo>> _patientsInfoFuture;

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurpleBackground = Color(0xFFEDE7F6);

  @override
  void initState() {
    super.initState();
    _patientsInfoFuture = _loadPatientsInfo();
  }

  void _refreshPatientList() {
    setState(() => _patientsInfoFuture = _loadPatientsInfo());
  }

  Future<List<_PatientInfo>> _loadPatientsInfo() async {
    final allVetAppointments =
    await DatabaseHelper.instance.getAppointmentsForVeterinary(widget.vetId);

    if (allVetAppointments.isEmpty) return [];

    final petIds = allVetAppointments.map((a) => a.petId).toSet();
    final pets = (await Future.wait(
      petIds.map((id) => DatabaseHelper.instance.getPetById(id)),
    ))
        .whereType<Pet>()
        .toList();

    final ownerIds = pets.map((p) => p.ownerId).toSet();
    final owners = (await Future.wait(
      ownerIds.map((id) => DatabaseHelper.instance.getOwnerById(id)),
    ))
        .whereType<Owner>()
        .toList();

    final List<_PatientInfo> patientInfos = [];
    for (final owner in owners) {
      final ownerPets = await DatabaseHelper.instance.getPetsByOwner(owner.id!);
      final ownerAppointments = allVetAppointments
          .where((a) => ownerPets.any((p) => p.id == a.petId))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      patientInfos.add(_PatientInfo(
        patient: owner,
        petCount: ownerPets.length,
        lastVisit: ownerAppointments.isNotEmpty
            ? ownerAppointments.first.dateTime
            : null,
      ));
    }

    return patientInfos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Mes Patients'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: FutureBuilder<List<_PatientInfo>>(
        future: _patientsInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryPurple),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final patients = snapshot.data ?? [];
          if (patients.isEmpty) {
            return const Center(
              child: Text(
                'Aucun patient trouvé.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: patients.length,
            itemBuilder: (context, index) => _buildPatientCard(patients[index]),
          );
        },
      ),
    );
  }

  Widget _buildPatientCard(_PatientInfo info) {
    final lastVisitText = info.lastVisit != null
        ? DateFormat('dd/MM/yyyy').format(info.lastVisit!)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(
                patient: info.patient,
                vetId: widget.vetId,
              ),
            ),
          ).then((_) => _refreshPatientList());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: lightPurpleBackground,
                    child: const Icon(
                      Icons.person_outline,
                      color: primaryPurple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      info.patient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 18),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Animaux', '${info.petCount}'),
                  _buildStat('Dernière visite', lastVisitText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Color(0xFF555555),
          ),
        ),
      ],
    );
  }
}
