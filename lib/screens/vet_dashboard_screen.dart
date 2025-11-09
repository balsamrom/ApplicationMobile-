import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_owner_app/screens/veterinary/vet_profile_editor_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../db/database_helper.dart';
import '../models/owner.dart';
import '../models/pet.dart';
import '../models/veterinary.dart';
import '../models/veterinary_appointment.dart';
import '../screens/login_screen.dart';
import './veterinary/patient_list_screen.dart';
import './veterinary/book_search_screen.dart';
import './veterinary/appointment_detail_screen.dart';

class VetDashboardScreen extends StatefulWidget {
  final int vetId;
  const VetDashboardScreen({Key? key, required this.vetId}) : super(key: key);

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  late Future<Veterinary?> _vetFuture;

  @override
  void initState() {
    super.initState();
    _vetFuture = _loadVeterinary();
  }

  Future<void> _reloadVeterinary() async {
    setState(() {
      _vetFuture = _loadVeterinary();
    });
  }

  Future<Veterinary?> _loadVeterinary() async {
    final vets = await DatabaseHelper.instance.getVeterinarians();
    return vets.firstWhereOrNull((v) => v.owner.id == widget.vetId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Veterinary?>(
      future: _vetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(
              child: Text('Impossible de charger le profil du vétérinaire. Erreur: ${snapshot.error}'),
            ),
          );
        }
        return VetDashboardUI(vet: snapshot.data!, onProfileUpdate: _reloadVeterinary);
      },
    );
  }
}

class VetDashboardUI extends StatefulWidget {
  final Veterinary vet;
  final VoidCallback onProfileUpdate;
  const VetDashboardUI({Key? key, required this.vet, required this.onProfileUpdate}) : super(key: key);

  @override
  State<VetDashboardUI> createState() => _VetDashboardUIState();
}

class _VetDashboardUIState extends State<VetDashboardUI> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  // Couleurs harmonisées avec Services Vétérinaires
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  void _navigateToEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VetProfileEditorScreen(vet: widget.vet)),
    );
    if (result == true) {
      widget.onProfileUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${widget.vet.owner.name}'),
        backgroundColor: primaryPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier le profil',
            onPressed: _navigateToEditor,
          ),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
              onPressed: _logout
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Agenda'),
            Tab(icon: Icon(Icons.people), text: 'Mes Patients'),
            Tab(icon: Icon(Icons.book), text: 'Bibliothèque'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          AgendaView(vet: widget.vet),
          PatientListScreen(vetId: widget.vet.owner.id!),
          const BookSearchScreen(),
        ],
      ),
    );
  }
}

class AgendaView extends StatefulWidget {
  final Veterinary vet;
  const AgendaView({Key? key, required this.vet}) : super(key: key);

  @override
  _AgendaViewState createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  List<VeterinaryAppointment> _allAppointments = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Couleurs harmonisées
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final appointments = await DatabaseHelper.instance.getAppointmentsForVeterinary(widget.vet.owner.id!);
    if (mounted) {
      setState(() {
        _allAppointments = appointments;
      });
    }
  }

  List<VeterinaryAppointment> _getEventsForDay(DateTime day) {
    return _allAppointments.where((event) => isSameDay(event.dateTime, day)).toList();
  }

  void _showAppointmentDetails(VeterinaryAppointment appointment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
    if (result == true) {
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayEvents = _getEventsForDay(_selectedDay!);

    return Column(
      children: [
        TableCalendar<VeterinaryAppointment>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
                color: primaryPurple,
                shape: BoxShape.circle
            ),
            selectedDecoration: BoxDecoration(
                color: lightPurple,
                shape: BoxShape.circle
            ),
            markerDecoration: BoxDecoration(
                color: accentOrange,
                shape: BoxShape.circle
            ),
          ),
          headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true
          ),
        ),
        const Divider(thickness: 1, height: 1),
        if (selectedDayEvents.isNotEmpty)
          _buildSelectedDayList(selectedDayEvents),

        Expanded(child: _buildAppointmentLists()),
      ],
    );
  }

  Widget _buildSelectedDayList(List<VeterinaryAppointment> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Rendez-vous du ${DateFormat('dd MMMM yyyy').format(_selectedDay!)}',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryPurple
            ),
          ),
        ),
        ...events.map((app) => _buildAppointmentCard(app))
      ],
    );
  }

  Widget _buildAppointmentLists() {
    if (_allAppointments.isEmpty) {
      return const Center(child: Text('Aucun rendez-vous programmé.'));
    }

    final now = DateTime.now();
    final upcoming = _allAppointments
        .where((a) => a.dateTime.isAfter(now))
        .toList()..sort((a,b) => a.dateTime.compareTo(b.dateTime));

    final past = _allAppointments
        .where((a) => a.dateTime.isBefore(now))
        .toList()..sort((a,b) => b.dateTime.compareTo(a.dateTime));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildSectionHeader('Tous les rendez-vous à venir'),
        if (upcoming.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Aucun rendez-vous à venir.')))
        else
          ...upcoming.map((app) => _buildAppointmentCard(app)),

        const SizedBox(height: 20),
        _buildSectionHeader('Historique complet'),
        if (past.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Aucun historique.')))
        else
          ...past.map((app) => _buildAppointmentCard(app)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryPurple
          )
      ),
    );
  }

  Widget _buildAppointmentCard(VeterinaryAppointment appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: _buildStatusIcon(appointment.status),
        title: Text(
            'RDV pour ${appointment.petName}',
            style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Text(
            '${DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)}\n'
                'Motif: ${appointment.reason}'
        ),
        onTap: () => _showAppointmentDetails(appointment),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.pending_actions;
        color = accentOrange;
    }
    return CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color)
    );
  }
}