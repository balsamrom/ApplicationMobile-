import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/services/health_analyzer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;
    final Color unselectedColor = Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau Administrateur',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _StatisticsView(),
          _HealthAnalysisView(),
          _PendingVetsView(),
          _UserManagementView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        showUnselectedLabels: true,
        elevation: 2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety_outlined),
            activeIcon: Icon(Icons.health_and_safety),
            label: 'Analyse Santé',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg_outlined),
            activeIcon: Icon(Icons.how_to_reg),
            label: 'Validation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            activeIcon: Icon(Icons.manage_accounts),
            label: 'Gestion',
          ),
        ],
      ),
    );
  }
}

// Section des statistiques
class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Vous pouvez ajouter une logique de rafraîchissement si nécessaire
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text('Répartition des utilisateurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _UserDistributionChart(),
          SizedBox(height: 24),
          Text('Nouveaux utilisateurs (7 derniers jours)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _NewUsersChart(),
          SizedBox(height: 24),
          Text('Nouveaux animaux (7 derniers jours)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _NewPetsChart(),
        ],
      ),
    );
  }
}

class _UserDistributionChart extends StatelessWidget {
  const _UserDistributionChart();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune donnée utilisateur.'));
        }

        final data = snapshot.data!;
        final total = data.values.reduce((a, b) => a + b);

        return SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: data.entries.map((entry) {
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${entry.key}\n$percentage%',
                  color: _getColor(entry.key),
                  radius: 80,
                  titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getUserData() async {
    final owners = await DatabaseHelper.instance.countOwners();
    final approvedVets = await DatabaseHelper.instance.countApprovedVets();
    final pendingVets = await DatabaseHelper.instance.countPendingVets();
    return {
      'Propriétaires': owners,
      'Vétérinaires Approuvés': approvedVets,
      'Vétérinaires en Attente': pendingVets,
    };
  }

  Color _getColor(String key) {
    switch (key) {
      case 'Propriétaires':
        return Colors.blue;
      case 'Vétérinaires Approuvés':
        return Colors.green;
      case 'Vétérinaires en Attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _NewUsersChart extends StatelessWidget {
  const _NewUsersChart();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: DatabaseHelper.instance.getDailyNewUsers(7),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune nouvelle inscription d\'utilisateur.'));
        }

        final data = snapshot.data!;

        return SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.entries.map((entry) {
                    final date = DateTime.parse(entry.key);
                    return FlSpot(date.day.toDouble(), entry.value.toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NewPetsChart extends StatelessWidget {
  const _NewPetsChart();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: DatabaseHelper.instance.getDailyNewPets(7),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune nouvelle inscription d\'animal.'));
        }

        final data = snapshot.data!;

        return SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.entries.map((entry) {
                    final date = DateTime.parse(entry.key);
                    return FlSpot(date.day.toDouble(), entry.value.toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HealthAnalysisView extends StatelessWidget {
  const _HealthAnalysisView();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        DatabaseHelper.instance.getAllPets(),
        DatabaseHelper.instance.getAllNutritionLogs(),
        DatabaseHelper.instance.getAllActivityLogs(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final pets = snapshot.data![0] as List<Pet>;
        final nutritionLogs = snapshot.data![1];
        final activityLogs = snapshot.data![2];

        if (pets.isEmpty) {
          return const Center(child: Text('Aucun animal à analyser.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            final petNutritionLogs = nutritionLogs.where((log) => log.petId == pet.id).toList();
            final petActivityLogs = activityLogs.where((log) => log.petId == pet.id).toList();

            final analysis = HealthAnalyzer.analyzePetRoutine(pet, petNutritionLogs, petActivityLogs);
            final isHealthy = analysis.isEmpty;
            final insufficientData = !isHealthy && analysis.first.startsWith('Enregistrez');
            final hasAnomalies = !isHealthy && !insufficientData;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: hasAnomalies ? Colors.red : Colors.transparent, width: 2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  backgroundImage: pet.photo != null ? FileImage(File(pet.photo!)) : null,
                  child: pet.photo == null ? const Icon(Icons.pets) : null,
                ),
                title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  isHealthy ? 'Routine saine' : analysis.first,
                  style: TextStyle(color: isHealthy ? Colors.green : (insufficientData ? Colors.grey : Colors.red), fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}


// Section de validation des vétérinaires
class _PendingVetsView extends StatefulWidget {
  const _PendingVetsView();

  @override
  State<_PendingVetsView> createState() => _PendingVetsViewState();
}

class _PendingVetsViewState extends State<_PendingVetsView> {
  late Future<List<Owner>> _pendingVetsFuture;

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  void _loadVets() {
    setState(() {
      _pendingVetsFuture = DatabaseHelper.instance.getPendingVets();
    });
  }

  Future<void> _updateVetStatus(Owner vet, bool approve) async {
    vet.isVetApproved = approve ? 1 : 2; // 1: approuvé, 2: refusé
    await DatabaseHelper.instance.updateOwner(vet);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Vétérinaire ${approve ? "approuvé" : "refusé"}.'),
          backgroundColor: approve ? Colors.green : Colors.red),
    );
    _loadVets();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Owner>>(
      future: _pendingVetsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('Aucun vétérinaire en attente.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final vet = snapshot.data![index];
            return _UserCard(user: vet, onUpdate: _loadVets, isVetValidation: true);
          },
        );
      },
    );
  }
}

// Section de gestion des utilisateurs
class _UserManagementView extends StatefulWidget {
  const _UserManagementView();

  @override
  State<_UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<_UserManagementView> {
  late Future<List<Owner>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = DatabaseHelper.instance.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Owner>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('Aucun utilisateur à gérer.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return _UserCard(user: user, onUpdate: _loadUsers);
          },
        );
      },
    );
  }
}

// Widget de carte utilisateur réutilisable
class _UserCard extends StatelessWidget {
  final Owner user;
  final VoidCallback onUpdate; // Pour rafraîchir la liste après une action
  final bool isVetValidation;

  const _UserCard({
    required this.user,
    required this.onUpdate,
    this.isVetValidation = false,
  });

  // Logique pour mettre à jour le statut du vétérinaire
  Future<void> _updateVetStatus(BuildContext context, bool approve) async {
    user.isVetApproved = approve ? 1 : 2;
    await DatabaseHelper.instance.updateOwner(user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Vétérinaire ${approve ? "approuvé" : "refusé"}.'),
          backgroundColor: approve ? Colors.green : Colors.red),
    );
    onUpdate();
  }

  // Logique pour supprimer un utilisateur
  Future<void> _deleteUser(BuildContext context) async {
    await DatabaseHelper.instance.deleteOwner(user.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Utilisateur ${user.name} supprimé.'),
          backgroundColor: Colors.red),
    );
    onUpdate();
  }

  void _showDiploma(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Diplôme de ${user.name}'),
        content: (user.diplomaPath != null && File(user.diplomaPath!).existsSync())
            ? Image.file(File(user.diplomaPath!))
            : const Text('Fichier non trouvé ou chemin invalide.'),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le compte de ${user.name} ? Cette action est irréversible.'),
        actions: [
          TextButton(child: const Text('Annuler'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Supprimer'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteUser(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String role = user.isAdmin
        ? 'Administrateur'
        : user.isVet
            ? (user.isVetApproved == 1
                ? 'Vétérinaire (Approuvé)'
                : (user.isVetApproved == 2
                    ? 'Vétérinaire (Refusé)'
                    : 'Vétérinaire (En attente)'))
            : 'Propriétaire';

    final Color roleColor = user.isAdmin
        ? Colors.purple
        : user.isVet
            ? (user.isVetApproved == 1 ? Colors.green : (user.isVetApproved == 2 ? Colors.red : Colors.orange))
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: user.photoPath != null && File(user.photoPath!).existsSync()
                      ? FileImage(File(user.photoPath!))
                      : null,
                  child: user.photoPath == null || !File(user.photoPath!).existsSync()
                      ? Icon(Icons.person, size: 25, color: Colors.grey.shade400)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(role, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: roleColor,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        labelPadding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                // Affiche les actions en fonction du contexte
                if (!isVetValidation)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                    onPressed: () => _confirmDeleteUser(context),
                    tooltip: 'Supprimer l\'utilisateur',
                  ),
              ],
            ),
            const Divider(height: 24),
            // Informations de contact
            if (user.email != null)
              _InfoTile(icon: Icons.email_outlined, text: user.email!),
            if (user.phone != null)
              _InfoTile(icon: Icons.phone_outlined, text: user.phone!),
            if(user.isVet && user.diplomaPath != null) ...[
               const SizedBox(height: 8),
               Center(
                 child: ElevatedButton.icon(
                    onPressed: () => _showDiploma(context),
                    icon: const Icon(Icons.file_present_outlined, size: 20),
                    label: const Text('Voir le diplôme'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ), 
               ),
            ],
            // Actions pour la validation du vétérinaire
            if (isVetValidation)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateVetStatus(context, true),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateVetStatus(context, false),
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text('Refuser'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}

// Widget pour une ligne d'information avec icône
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
