import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';
import '../../models/cabinet.dart';
import '../../models/veterinary_appointment.dart';
import './veterinary_map_view.dart';
import './veterinary_detail_screen.dart';

class SimpleVetScreen extends StatefulWidget {
  final Owner owner;
  const SimpleVetScreen({Key? key, required this.owner}) : super(key: key);

  @override
  SimpleVetScreenState createState() => SimpleVetScreenState();
}

class SimpleVetScreenState extends State<SimpleVetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Owner>> _vetsFuture;
  late Future<List<VeterinaryAppointment>> _appointmentsFuture;
  List<Cabinet> _cabinets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVets();
    _loadAppointments();
    _loadCabinets();
  }

  void _loadVets() {
    setState(() {
      _vetsFuture = DatabaseHelper.instance.getOwners().then(
            (owners) => owners.where((o) => o.isVet && o.isVetApproved == 1).toList(),
      );
    });
  }

  void _loadAppointments() {
    setState(() {
      _appointmentsFuture = _getUserAppointments(widget.owner.id!);
    });
  }

  void _loadCabinets() async {
    final cabinets = await DatabaseHelper.instance.getAllCabinets();
    setState(() {
      _cabinets = cabinets;
    });
  }

  Future<List<VeterinaryAppointment>> _getUserAppointments(int ownerId) async {
    final userPets = await DatabaseHelper.instance.getPetsByOwner(ownerId);
    if (userPets.isEmpty) return [];
    final petIds = userPets.map((p) => p.id!).toSet();
    final allAppointments = await DatabaseHelper.instance.getAllAppointments();
    final filtered = allAppointments.where((a) => petIds.contains(a.petId)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF2D3748)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Services Vétérinaires',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Color(0xFF2D3748),
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'TROUVER UN VÉTO'),
                  Tab(text: 'MES RDV')
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildVetList(), _buildAppointmentList()],
      ),
    );
  }

  Widget _buildVetList() {
    return FutureBuilder<List<Owner>>(
      future: _vetsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun vétérinaire trouvé'));
        }

        final vets = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vets.length,
          itemBuilder: (context, i) {
            final vet = vets[i];
            final cabinet = _cabinets.firstWhere(
                  (c) => c.veterinaryId == vet.id,
              orElse: () => Cabinet(veterinaryId: vet.id!, address: 'Adresse non fournie'),
            );
            return _buildVetCard(vet, cabinet);
          },
        );
      },
    );
  }

  Widget _buildVetCard(Owner vet, Cabinet cabinet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 35,
          backgroundImage: (vet.photoPath != null && vet.photoPath!.isNotEmpty)
              ? FileImage(File(vet.photoPath!))
              : null,
          backgroundColor: const Color(0xFFF3E5F5),
          child: (vet.photoPath == null || vet.photoPath!.isEmpty)
              ? const Icon(Icons.person, color: Color(0xFF7C4DFF))
              : null,
        ),
        title: Text(
          'Dr. ${vet.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              cabinet.address,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF7C4DFF)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VeterinaryDetailScreen(vet: vet, cabinet: cabinet, owner: widget.owner),
            ),
          ).then((_) => _loadAppointments());
        },
      ),
    );
  }

  Widget _buildAppointmentList() {
    return FutureBuilder<List<VeterinaryAppointment>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun rendez-vous.'));
        }

        final now = DateTime.now();
        final upcoming = snapshot.data!.where((a) => a.dateTime.isAfter(now)).toList();
        final past = snapshot.data!.where((a) => a.dateTime.isBefore(now)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (upcoming.isNotEmpty) _buildSection('Rendez-vous à venir', upcoming),
            if (past.isNotEmpty) _buildSection('Historique', past),
          ],
        );
      },
    );
  }

  Widget _buildSection(String title, List<VeterinaryAppointment> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C4DFF)),
        ),
        const SizedBox(height: 12),
        ...apps.map(_buildAppointmentCard),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAppointmentCard(VeterinaryAppointment app) {
    final isPast = app.dateTime.isBefore(DateTime.now());
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey[300] : const Color(0xFF7C4DFF),
          child: Icon(isPast ? Icons.history : Icons.event_available, color: Colors.white),
        ),
        title: Text(app.petName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Dr. ${app.veterinaryName}\n${DateFormat('dd/MM/yyyy à HH:mm').format(app.dateTime)}',
        ),
      ),
    );
  }
}
