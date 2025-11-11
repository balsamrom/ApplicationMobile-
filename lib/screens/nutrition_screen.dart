import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/models/nutrition_log.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/screens/settings_screen.dart';

class NutritionScreen extends StatefulWidget {
  final Pet pet;
  final Owner owner;

  const NutritionScreen({Key? key, required this.pet, required this.owner}) : super(key: key);

  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late Future<List<NutritionLog>> _nutritionLogsFuture;

  final List<String> _foodTypes = [
    'Croquettes',
    'Pâtée',
    'Nourriture humide',
    'Friandises',
    'Restes de table',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _loadNutritionLogs();
  }

  void _loadNutritionLogs() {
    setState(() {
      _nutritionLogsFuture = DatabaseHelper.instance.getNutritionLogsForPet(widget.pet.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nutrition pour ${widget.pet.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(owner: widget.owner))),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: FutureBuilder<List<NutritionLog>>(
        future: _nutritionLogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun log de nutrition trouvé.'));
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
                  leading: const Icon(Icons.restaurant_menu, color: Colors.blueAccent),
                  title: Text(
                    '${log.foodType} - ${log.quantity} ${log.unit}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat.yMMMd().add_jm().format(log.logDate)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _showNutritionLogDialog(log: log),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteNutritionLog(log.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNutritionLogDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un log de nutrition',
      ),
    );
  }

  Future<void> _showNutritionLogDialog({NutritionLog? log}) async {
    final _formKey = GlobalKey<FormState>();
    String? _selectedFoodType = log?.foodType;
    final _quantityController = TextEditingController(text: log?.quantity.toString());
    final _unitController = TextEditingController(text: log?.unit);
    DateTime _selectedDate = log?.logDate ?? DateTime.now();

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
                        value: _selectedFoodType,
                        decoration: const InputDecoration(labelText: 'Type de nourriture'),
                        items: _foodTypes
                            .map((food) => DropdownMenuItem(value: food, child: Text(food)))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedFoodType = value;
                          });
                        },
                        validator: (value) => value == null ? 'Sélectionnez un type de nourriture' : null,
                      ),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Quantité'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Entrez une quantité';
                          if (double.tryParse(value) == null) return 'Entrez un nombre valide';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unité (ex: grammes)'),
                        validator: (value) => value!.isEmpty ? 'Entrez une unité' : null,
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
                      final newLog = NutritionLog(
                        id: log?.id,
                        petId: widget.pet.id!,
                        foodType: _selectedFoodType!,
                        quantity: double.parse(_quantityController.text),
                        unit: _unitController.text,
                        logDate: _selectedDate,
                      );

                      if (log == null) {
                        DatabaseHelper.instance.insertNutritionLog(newLog).then((_) {
                          _loadNutritionLogs();
                          Navigator.of(context).pop();
                        });
                      } else {
                        DatabaseHelper.instance.updateNutritionLog(newLog).then((_) {
                          _loadNutritionLogs();
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

  Future<void> _deleteNutritionLog(int id) async {
    await DatabaseHelper.instance.deleteNutritionLog(id);
    _loadNutritionLogs();
  }
}
