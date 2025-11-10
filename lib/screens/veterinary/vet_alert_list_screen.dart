// TODO Implement this library.import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/models/alert_details.dart';
import 'package:pet_owner_app/screens/vet_alert_detail_screen.dart';

class VetAlertListScreen extends StatefulWidget {
  const VetAlertListScreen({super.key});

  @override
  State<VetAlertListScreen> createState() => _VetAlertListScreenState();
}

class _VetAlertListScreenState extends State<VetAlertListScreen> {
  late Future<List<AlertDetails>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _loadAlertDetails();
  }

  Future<List<AlertDetails>> _loadAlertDetails() async {
    final dbHelper = DatabaseHelper.instance;
    final alerts = await dbHelper.getAlerts();
    final List<AlertDetails> alertDetailsList = [];

    for (final alert in alerts) {
      final owner = await dbHelper.getOwnerById(alert.ownerId);
      final pet = await dbHelper.getPetById(alert.petId);

      if (owner != null && pet != null) {
        alertDetailsList.add(AlertDetails(alert: alert, owner: owner, pet: pet));
      }
    }
    return alertDetailsList;
  }

  String _formatEta(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return "< 1 min";
    }
    return "${difference.inMinutes} min";
  }

  bool _isImminent(DateTime timestamp) {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alertes d'Urgence"),
        backgroundColor: Colors.orange[800],
      ),
      body: FutureBuilder<List<AlertDetails>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Aucune alerte pour le moment.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final alertDetailsList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: alertDetailsList.length,
            itemBuilder: (context, index) {
              final details = alertDetailsList[index];
              final isImminent = _isImminent(details.alert.timestamp);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isImminent ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VetAlertDetailScreen(details: details),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "${details.pet.name} - ${details.alert.emergencyTitle}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isImminent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "ARRIVÉE IMMINENTE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Propriétaire: ${details.owner.name}"),
                        const SizedBox(height: 4),
                        Text("Alerte reçue il y a : ${_formatEta(details.alert.timestamp)}"),
                        const Divider(height: 24),
                        const Text(
                          "Premiers secours appliqués (Info à venir):",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text("  • Détails non disponibles"),
                         const Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
