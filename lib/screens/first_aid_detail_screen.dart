import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/alert.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/services/translation_service.dart';
import '../models/first_aid_item.dart';
import '../db/database_helper.dart';

class FirstAidDetailScreen extends StatefulWidget {
  final FirstAidItem item;
  final Owner owner;

  const FirstAidDetailScreen(
      {super.key, required this.item, required this.owner});

  @override
  State<FirstAidDetailScreen> createState() => _FirstAidDetailScreenState();
}

class _FirstAidDetailScreenState extends State<FirstAidDetailScreen> {
  bool _isEmergencyMode = false;
  List<Pet> _pets = [];
  Pet? _selectedPet;
  final Map<int, bool> _completedSteps = {};

  // Translation state
  bool _isTranslated = false;
  bool _isTranslating = false;
  late Map<String, String> _translations;
  late List<String> _translatedMaterials;
  late List<String> _translatedSteps;

  @override
  void initState() {
    super.initState();
    _loadPets();
    _initializeTranslations();
  }

  void _initializeTranslations() {
    _translations = {
      'title': widget.item.title,
      'description': widget.item.description,
      'time_to_act': "Agir en: ${widget.item.timeToAction}",
      'materials_needed': "Matériel nécessaire:",
      'steps_to_follow': "Étapes à suivre:",
      'activate_emergency_mode': "Activer le mode urgence",
      'deactivate_emergency_mode': "Désactiver le mode urgence",
      'trigger_alert': "Déclencher l'Alerte",
      'get_directions': "Itinéraire",
      'select_pet': "Sélectionner l\'animal concerné",
      'emergency_mode_active': "MODE URGENCE ACTIVÉ",
      'alert_sent': "Alerte envoyée ! Mode urgence activé.",
      'select_pet_warning': "Veuillez sélectionner un animal.",
    };
    _translatedMaterials = List.from(widget.item.materials);
    _translatedSteps = List.from(widget.item.steps);
  }

  Future<void> _loadPets() async {
    final pets = await DatabaseHelper.instance.getPetsByOwner(widget.owner.id!);
    setState(() {
      _pets = pets;
      if (pets.isNotEmpty) {
        _selectedPet = pets.first;
      }
    });
  }

  Future<void> _toggleTranslation() async {
    if (_isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    final isSwitchingToArabic = !_isTranslated;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isSwitchingToArabic ? "Traduction en cours..." : "Retour au français..."),
      duration: const Duration(seconds: 2),
    ));

    if (isSwitchingToArabic) {
      final newTranslations = <String, String>{};
      final Map<String, String> toTranslate = {
        'title': widget.item.title,
        'description': widget.item.description,
        'time_to_act': "Agir en: ${widget.item.timeToAction}",
        'materials_needed': "Matériel nécessaire:",
        'steps_to_follow': "Étapes à suivre:",
        'activate_emergency_mode': "Activer le mode urgence",
        'deactivate_emergency_mode': "Désactiver le mode urgence",
        'trigger_alert': "Déclencher l'Alerte",
        'get_directions': "Itinéraire",
        'select_pet': "Sélectionner l\'animal concerné",
        'emergency_mode_active': "MODE URGENCE ACTIVÉ",
        'alert_sent': "Alerte envoyée ! Mode urgence activé.",
        'select_pet_warning': "Veuillez sélectionner un animal.",
      };

      for (var entry in toTranslate.entries) {
        newTranslations[entry.key] = await TranslationService.translate(entry.value);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final List<String> translatedMaterials = [];
      for (final item in widget.item.materials) {
        translatedMaterials.add(await TranslationService.translate(item));
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final List<String> translatedSteps = [];
      for (final item in widget.item.steps) {
        translatedSteps.add(await TranslationService.translate(item));
        await Future.delayed(const Duration(milliseconds: 200));
      }

      setState(() {
        _translations = newTranslations;
        _translatedMaterials = translatedMaterials;
        _translatedSteps = translatedSteps;
        _isTranslated = true;
      });

    } else {
      setState(() {
        _initializeTranslations();
        _isTranslated = false;
      });
    }

    setState(() {
      _isTranslating = false;
    });
  }

  Future<void> _triggerAlert() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translations['select_pet_warning']!)),
      );
      return;
    }

    // Active le mode urgence automatiquement
    setState(() {
      _isEmergencyMode = true;
    });

    final alert = Alert(
      ownerId: widget.owner.id!,
      petId: _selectedPet!.id!,
      emergencyTitle: widget.item.title,
      timestamp: DateTime.now(),
    );

    await DatabaseHelper.instance.insertAlert(alert);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translations['alert_sent']!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_translations['title']!),
        backgroundColor: _isEmergencyMode
            ? Colors.red
            : const Color(0xFF009688),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isTranslating ? null : _toggleTranslation,
            icon: const Icon(Icons.translate),
            tooltip: _isTranslated ? 'Afficher en Français' : 'Traduire en Arabe',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEmergencyMode)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      _translations['emergency_mode_active']!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translations['title']!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: widget.item.priorityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16),
                        const SizedBox(width: 4),
                        Text(_translations['time_to_act']!,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_translations['description']!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_pets.isNotEmpty)
              _buildPetSelector(),
            const SizedBox(height: 24),
            Text(_translations['materials_needed']!,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final material in _translatedMaterials)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Text("• $material"),
              ),
            const SizedBox(height: 24),
            Text(_translations['steps_to_follow']!,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_isEmergencyMode)
              ..._buildEmergencySteps()
            else
              ..._buildStandardSteps(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isEmergencyMode = !_isEmergencyMode;
            if (!_isEmergencyMode) {
              _completedSteps.clear();
            }
          });
        },
        label: Text(_isEmergencyMode
            ? _translations['deactivate_emergency_mode']!
            : _translations['activate_emergency_mode']!),
        icon: Icon(_isEmergencyMode ? Icons.close : Icons.warning),
        backgroundColor: _isEmergencyMode ? Colors.grey[700] : Colors.red,
        foregroundColor: Colors.white,
      ),
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton.icon(
                  onPressed: _triggerAlert,
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: Text(_translations['trigger_alert']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions),
                  label: Text(_translations['get_directions']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPetSelector() {
    return DropdownButtonFormField<Pet>(
      value: _selectedPet,
      decoration: InputDecoration(
        labelText: _translations['select_pet']!,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.pets, color: Color(0xFF009688)),
      ),
      items: _pets.map((pet) {
        return DropdownMenuItem<Pet>(
          value: pet,
          child: Text(pet.name),
        );
      }).toList(),
      onChanged: (Pet? newValue) {
        setState(() {
          _selectedPet = newValue;
        });
      },
    );
  }

  List<Widget> _buildStandardSteps() {
    return _translatedSteps.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final step = entry.value;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
            child: Text('$index'),
          ),
          title: Text(step),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEmergencySteps() {
    return _translatedSteps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      final isCompleted = _completedSteps[index] ?? false;

      return Card(
        color: isCompleted ? Colors.green[50] : Colors.red[50],
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCompleted ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
            child: isCompleted
                ? const Icon(Icons.check, size: 20)
                : Text('${index + 1}'),
          ),
          title: Text(
            step,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey[600] : Colors.black,
            ),
          ),
          trailing: Checkbox(
            value: isCompleted,
            onChanged: (bool? value) {
              setState(() {
                _completedSteps[index] = value ?? false;
              });
            },
            activeColor: Colors.green,
          ),
        ),
      );
    }).toList();
  }
}