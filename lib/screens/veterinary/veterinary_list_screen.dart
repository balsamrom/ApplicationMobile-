import 'dart:io';
import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';
import '../../models/veterinary.dart';
import './veterinary_detail_screen.dart'; // MODIFIÉ: On importe le bon écran

class VeterinaryListScreen extends StatefulWidget {
  final Owner owner; // Le client qui consulte la liste

  const VeterinaryListScreen({Key? key, required this.owner}) : super(key: key);

  @override
  _VeterinaryListScreenState createState() => _VeterinaryListScreenState();
}

class _VeterinaryListScreenState extends State<VeterinaryListScreen> {
  late Future<List<Veterinary>> _vetsFuture;

  @override
  void initState() {
    super.initState();
    _vetsFuture = DatabaseHelper.instance.getVeterinarians();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un vétérinaire'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Veterinary>>(
        future: _vetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun vétérinaire trouvé.'));
          }

          final vets = snapshot.data!;
          return ListView.builder(
            itemCount: vets.length,
            itemBuilder: (context, index) {
              return _buildVetCard(vets[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildVetCard(Veterinary vet) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // CORRIGÉ: Navigue vers l'écran de DÉTAILS du vétérinaire
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VeterinaryDetailScreen(
                vet: vet,       // Passe l'objet Veterinary complet
                owner: widget.owner, // Passe l'objet Owner du client
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: vet.owner.photoPath != null && vet.owner.photoPath!.isNotEmpty
                  ? FileImage(File(vet.owner.photoPath!))
                  : null,
              child: (vet.owner.photoPath == null || vet.owner.photoPath!.isEmpty) ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. ${vet.owner.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text(vet.specialty ?? 'Spécialité non définie', style: const TextStyle(color: Colors.grey)),
                 const SizedBox(height: 8),
                Text(vet.address ?? 'Adresse non fournie', style: const TextStyle(fontSize: 14)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
