import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/models/nutrition_log.dart';
import 'package:pet_owner_app/models/activity_log.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthTrackingScreen extends StatefulWidget {
  final Pet pet;

  const HealthTrackingScreen({super.key, required this.pet});

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> {
  late Future<Map<String, List>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, List>> _loadData() async {
    final nutritionLogs = await DatabaseHelper.instance.getNutritionLogsForPet(widget.pet.id!);
    final activityLogs = await DatabaseHelper.instance.getActivityLogsForPet(widget.pet.id!);
    return {
      'nutrition': nutritionLogs,
      'activity': activityLogs,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi de ${widget.pet.name}'),
      ),
      body: FutureBuilder<Map<String, List>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune donnée disponible.'));
          }

          final nutritionLogs = snapshot.data!['nutrition'] as List<NutritionLog>;
          final activityLogs = snapshot.data!['activity'] as List<ActivityLog>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(nutritionLogs, activityLogs),
                const SizedBox(height: 24),
                const Text('Répartition des activités', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildActivityPieChart(activityLogs),
                const SizedBox(height: 24),
                const Text('Journaux de nutrition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildNutritionLogList(nutritionLogs),
                const SizedBox(height: 24),
                const Text('Journaux d\'activité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildActivityLogList(activityLogs),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<NutritionLog> nutritionLogs, List<ActivityLog> activityLogs) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.pet.analysis?.join('\n') ?? 'Analyse en cours...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Calories In', nutritionLogs.fold(0.0, (sum, log) => sum + log.quantity).toStringAsFixed(0), Colors.green),
                _buildStatColumn('Calories Out', activityLogs.fold(0.0, (sum, log) => sum + log.durationInMinutes).toStringAsFixed(0), Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
      ],
    );
  }

  Widget _buildActivityPieChart(List<ActivityLog> activityLogs) {
    if (activityLogs.isEmpty) return const Center(child: Text('Aucune activité enregistrée.'));

    final activityData = <String, double>{};
    for (var log in activityLogs) {
      activityData.update(log.activityType, (value) => value + log.durationInMinutes, ifAbsent: () => log.durationInMinutes.toDouble());
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: activityData.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value,
              title: entry.key,
              color: _getActivityColor(entry.key),
              radius: 60,
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getActivityColor(String activity) {
    switch (activity) {
      case 'Promenade': return Colors.blue;
      case 'Jeu': return Colors.green;
      case 'Course': return Colors.orange;
      case 'Entraînement': return Colors.purple;
      case 'Sieste': return Colors.grey;
      default: return Colors.black;
    }
  }

  Widget _buildNutritionLogList(List<NutritionLog> logs) {
    if (logs.isEmpty) return const Text('Aucun log de nutrition.');
    return Column(children: logs.map((log) => ListTile(title: Text('${log.foodType}: ${log.quantity} ${log.unit}'))).toList());
  }

  Widget _buildActivityLogList(List<ActivityLog> logs) {
    if (logs.isEmpty) return const Text('Aucun log d\'activité.');
    return Column(children: logs.map((log) => ListTile(title: Text('${log.activityType}: ${log.durationInMinutes} min'))).toList());
  }
}
