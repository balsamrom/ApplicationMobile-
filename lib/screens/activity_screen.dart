import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/models/activity_log.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/screens/settings_screen.dart';
import 'package:pet_owner_app/services/weather_service.dart';

class ActivityScreen extends StatefulWidget {
  final Pet pet;
  final Owner owner;

  const ActivityScreen({Key? key, required this.pet, required this.owner}) : super(key: key);

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<List<ActivityLog>> _activityLogsFuture;
  final WeatherService _weatherService = WeatherService();
  Future<Map<String, dynamic>>? _weatherFuture;

  final List<String> _activityTypes = [
    'Promenade',
    'Jeu',
    'Course',
    'Entraînement',
    'Sieste',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _loadActivityLogs();
    _weatherFuture = _weatherService.getWeather();
  }

  void _loadActivityLogs() {
    setState(() {
      _activityLogsFuture = DatabaseHelper.instance.getActivityLogsForPet(widget.pet.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activité pour ${widget.pet.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen(owner: widget.owner)),
            ),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeatherWidget(),
          Expanded(
            child: FutureBuilder<List<ActivityLog>>(
              future: _activityLogsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun log d\'activité trouvé.'));
                }

                final logs = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: const Icon(Icons.directions_run, color: Colors.green),
                        title: Text(
                          '${log.activityType} - ${log.durationInMinutes} minutes',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(DateFormat.yMMMd().add_jm().format(log.logDate as DateTime)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () => _showActivityLogDialog(log: log),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteActivityLog(log.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActivityLogDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un log d\'activité',
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Erreur météo: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final weatherData = snapshot.data!;
        final weatherDescription = weatherData['weather'][0]['description'];
        final temp = weatherData['main']['temp'];
        final recommendation = _getWeatherRecommendation(weatherDescription);

        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Météo actuelle: $weatherDescription, ${temp}°C'),
                      Text(recommendation, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getWeatherRecommendation(String description) {
    if (description.contains('pluie') || description.contains('neige')) {
      return 'Préférez les jeux d\'intérieur.';
    } else if (description.contains('soleil') || description.contains('clair')) {
      return 'Temps idéal pour une promenade !';
    } else {
      return 'Le temps est correct pour une sortie.';
    }
  }

  Future<void> _showActivityLogDialog({ActivityLog? log}) async {
    final _formKey = GlobalKey<FormState>();
    String? _selectedActivityType = log?.activityType;
    final _durationController = TextEditingController(text: log?.durationInMinutes.toString());
    final _notesController = TextEditingController(text: log?.notes);
    DateTime _selectedDate = (log?.logDate is DateTime ? log?.logDate : DateTime.now()) as DateTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(log == null ? 'Ajouter un log' : 'Modifier le log'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedActivityType,
                        decoration: const InputDecoration(labelText: 'Type d\'activité'),
                        items: _activityTypes
                            .map((activity) => DropdownMenuItem(value: activity, child: Text(activity)))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedActivityType = value;
                          });
                        },
                        validator: (value) => value == null ? 'Sélectionnez un type d\'activité' : null,
                      ),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(labelText: 'Durée (en minutes)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Entrez une durée';
                          if (int.tryParse(value) == null) return 'Entrez un nombre valide';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newLog = ActivityLog(
                        id: log?.id,
                        petId: widget.pet.id!,
                        activityType: _selectedActivityType!,
                        durationInMinutes: int.parse(_durationController.text),
                        notes: _notesController.text,
                        logDate: _selectedDate,
                      );

                      if (log == null) {
                        DatabaseHelper.instance.insertActivityLog(newLog).then((_) {
                          _loadActivityLogs();
                          Navigator.of(context).pop();
                        });
                      } else {
                        DatabaseHelper.instance.updateActivityLog(newLog).then((_) {
                          _loadActivityLogs();
                          Navigator.of(context).pop();
                        });
                      }
                    }
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteActivityLog(int id) async {
    await DatabaseHelper.instance.deleteActivityLog(id);
    _loadActivityLogs();
  }
}
