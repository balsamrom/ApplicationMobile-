import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../db/database_helper.dart';
import '../models/owner.dart';
import '../models/cabinet.dart';
import '../models/veterinary_appointment.dart';
import '../screens/login_screen.dart';
import './veterinary/vet_profile_editor_screen.dart';
import './veterinary/patient_list_screen.dart';
import './veterinary/book_search_screen.dart';
import './veterinary/appointment_detail_screen.dart';
import './veterinary/vet_alert_list_screen.dart'; // ✅ import ajouté
import './veterinary/vet_blog_management_screen.dart';

class VetDashboardScreen extends StatefulWidget {
  final int vetId;
  const VetDashboardScreen({Key? key, required this.vetId}) : super(key: key);

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  late Future<Owner?> _vetFuture;
  Cabinet? _cabinet;

  @override
  void initState() {
    super.initState();
    _vetFuture = _loadVeterinarian();
  }

  Future<void> _reloadVeterinarian() async {
    setState(() {
      _vetFuture = _loadVeterinarian();
    });
  }

  Future<Owner?> _loadVeterinarian() async {
    final vet = await DatabaseHelper.instance.getOwnerById(widget.vetId);
    if (vet == null) return null;
    _cabinet = await DatabaseHelper.instance.getCabinetForVet(vet.id!);
    return vet;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Owner?>(
      future: _vetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(child: Text('Erreur : ${snapshot.error}')),
          );
        }

        final vet = snapshot.data;
        if (vet == null) {
          return const Scaffold(
            body: Center(child: Text('Vétérinaire introuvable.')),
          );
        }

        return VetDashboardUI(
          vet: vet,
          cabinet: _cabinet,
          onProfileUpdate: _reloadVeterinarian,
        );
      },
    );
  }
}

class VetDashboardUI extends StatefulWidget {
  final Owner vet;
  final Cabinet? cabinet;
  final VoidCallback onProfileUpdate;

  const VetDashboardUI({
    Key? key,
    required this.vet,
    required this.onProfileUpdate,
    this.cabinet,
  }) : super(key: key);

  @override
  State<VetDashboardUI> createState() => _VetDashboardUIState();
}

class _VetDashboardUIState extends State<VetDashboardUI>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _navigateToProfileEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VetProfileEditorScreen(vet: widget.vet, cabinet: widget.cabinet),
      ),
    );
    if (result == true) widget.onProfileUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${widget.vet.name}'),
        backgroundColor: primaryPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.article),
            tooltip: 'Gérer mes blogs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VetBlogManagementScreen(vet: widget.vet),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier profil',
            onPressed: _navigateToProfileEditor,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Agenda'),
            Tab(icon: Icon(Icons.people), text: 'Mes Patients'),
            Tab(icon: Icon(Icons.book), text: 'Bibliothèque'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AgendaView(vet: widget.vet),
          PatientListScreen(vetId: widget.vet.id!),
          const BookSearchScreen(),
        ],
      ),

      // ✅ ALERTE TOUJOURS VISIBLE (condition supprimée)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text(
          "Alertes d'urgence",
          style:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VetAlertListScreen()),
          );
        },
      ),
    );
  }
}

class AgendaView extends StatefulWidget {
  final Owner vet;
  const AgendaView({Key? key, required this.vet}) : super(key: key);

  @override
  _AgendaViewState createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  List<VeterinaryAppointment> _appointments = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
    final list = await DatabaseHelper.instance
        .getAppointmentsForVeterinary(widget.vet.id!);
    if (mounted) {
      setState(() => _appointments = list);
    }
  }

  List<VeterinaryAppointment> _eventsForDay(DateTime day) {
    return _appointments.where((e) => isSameDay(e.dateTime, day)).toList();
  }

  void _openAppointment(VeterinaryAppointment appointment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
    if (result == true) _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final events = _eventsForDay(_selectedDay!);

    return Column(
      children: [
        TableCalendar<VeterinaryAppointment>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            if (!isSameDay(_selectedDay, selected)) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            }
          },
          eventLoader: _eventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: const BoxDecoration(
                color: primaryPurple, shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(
                color: lightPurple, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(
                color: accentOrange, shape: BoxShape.circle),
          ),
          headerStyle:
          const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const Divider(thickness: 1, height: 1),
        if (events.isNotEmpty) _buildEventList(events),
        Expanded(child: _buildAllAppointments()),
      ],
    );
  }

  Widget _buildEventList(List<VeterinaryAppointment> events) {
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
              color: primaryPurple,
            ),
          ),
        ),
        ...events.map(_buildAppointmentCard),
      ],
    );
  }

  Widget _buildAllAppointments() {
    if (_appointments.isEmpty) {
      return const Center(child: Text('Aucun rendez-vous.'));
    }

    final now = DateTime.now();
    final upcoming =
    _appointments.where((a) => a.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final past =
    _appointments.where((a) => a.dateTime.isBefore(now)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildSection('Rendez-vous à venir'),
        if (upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(child: Text('Aucun rendez-vous à venir.')),
          )
        else
          ...upcoming.map(_buildAppointmentCard),
        const SizedBox(height: 16),
        _buildSection('Historique'),
        if (past.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(child: Text('Aucun historique.')),
          )
        else
          ...past.map(_buildAppointmentCard),
      ],
    );
  }

  Widget _buildSection(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryPurple,
      ),
    ),
  );

  Widget _buildAppointmentCard(VeterinaryAppointment appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: _buildStatusIcon(appointment.status),
        title: Text(
          'RDV pour ${appointment.petName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)}\nMotif : ${appointment.reason}',
        ),
        onTap: () => _openAppointment(appointment),
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
      child: Icon(icon, color: color),
    );
  }
}
