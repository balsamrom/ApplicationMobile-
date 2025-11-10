import 'package:flutter/material.dart';
import 'package:pet_owner_app/models/alert_details.dart';
import 'dart:io';

class VetAlertDetailScreen extends StatefulWidget {
  final AlertDetails details;

  const VetAlertDetailScreen({super.key, required this.details});

  @override
  State<VetAlertDetailScreen> createState() => _VetAlertDetailScreenState();
}

class _VetAlertDetailScreenState extends State<VetAlertDetailScreen> {
  // Dummy data for checklist
  final Map<String, bool> _checklist = {
    "Salle d\'examen préparée": true,
    "Équipement de réanimation prêt": true,
    "Bloc opératoire en attente": false,
    "Équipe chirurgicale prévenue": true,
    "Poche de sang compatible disponible": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Urgence: ${widget.details.pet.name}"),
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFirstAidProgress(),
            const SizedBox(height: 16),
            _buildSectionCard(
                "Contact Propriétaire", _buildOwnerContact(), Icons.person),
            const SizedBox(height: 16),
            _buildSectionCard(
                "Symptômes Observés", _buildSymptoms(), Icons.visibility),
            const SizedBox(height: 16),
            _buildSectionCard("Protocole de Premiers Secours Appliqué",
                _buildFirstAidProtocol(), Icons.medical_services),
            const SizedBox(height: 16),
            _buildSectionCard(
                "Matériel Utilisé", _buildMaterialsUsed(), Icons.build),
            const SizedBox(height: 16),
            _buildSectionCard("Checklist de Préparation",
                _buildPreparationChecklist(), Icons.checklist),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildHeader() {
    final pet = widget.details.pet;
    final alert = widget.details.alert;
    final eta = DateTime.now().difference(alert.timestamp).inMinutes;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: pet.photo != null && pet.photo!.isNotEmpty
                  ? FileImage(File(pet.photo!)) as ImageProvider
                  : const AssetImage('assets/default_pet_avatar.png'), // Make sure to have a default avatar
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style:
                          const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("${pet.species}, ${pet.breed ?? 'Race inconnue'}, ${pet.age ?? 'N/A'} ans",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(alert.emergencyTitle.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Il y a $eta min",
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildFirstAidProgress() {
    // This is still dummy data
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Progression des Premiers Secours",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.75, // 3 sur 4 étapes complétées
          minHeight: 12,
          backgroundColor: Colors.grey[300],
          color: Colors.green,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerRight,
          child: Text("3 sur 4 étapes complétées"),
        )
      ],
    );
  }

  Widget _buildSectionCard(String title, Widget child, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(title, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerContact() {
    final owner = widget.details.owner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(owner.name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 4),
        Text(owner.email ?? 'Email non fourni'),
        Text(owner.phone ?? 'Téléphone non fourni'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone),
              label: const Text("Appeler"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.location_on),
              label: const Text("Localiser"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSymptoms() {
    // This remains dummy data for now
    final symptoms = [
      "Difficultés respiratoires sévères",
      "Gencives pâles, presque blanches",
      "Ne répond pas aux appels",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: symptoms.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(" ${entry.key + 1}. ${entry.value}"),
        );
      }).toList(),
    );
  }

  Widget _buildFirstAidProtocol() {
    // This remains dummy data for now
    return Column(
      children: [
        _buildProtocolStep(
            "Massage cardiaque initié", true, "10:31:05"),
        _buildProtocolStep(
            "Zone de sécurité établie", true, "10:30:15"),
        _buildProtocolStep("Vérification de la respiration", true, "10:30:40"),
        _buildProtocolStep("Appel aux urgences", false, "En cours..."),
      ],
    );
  }

  Widget _buildProtocolStep(String step, bool isDone, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.hourglass_empty, 
               color: isDone ? Colors.green : Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(step, style: TextStyle(fontSize: 15, color: isDone ? Colors.black : Colors.black87))),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMaterialsUsed() {
    // This remains dummy data for now
    final materials = ["Mains pour le massage", "Téléphone"];
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: materials
          .map((material) => Chip(label: Text(material)))
          .toList(),
    );
  }

  Widget _buildPreparationChecklist() {
    return Column(
      children: _checklist.entries.map((entry) {
        return CheckboxListTile(
          title: Text(entry.key),
          value: entry.value,
          onChanged: (bool? value) {
            setState(() {
              _checklist[entry.key] = value!;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.teal,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text("Dossier Médical"),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text("Déclencher Protocole"),
          ),
        ],
      ),
    );
  }
}
