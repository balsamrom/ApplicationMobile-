import 'dart:io';
import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';
import './veterinary_detail_screen.dart'; 

class VeterinaryListScreen extends StatefulWidget {
  final Owner owner; 

  const VeterinaryListScreen({Key? key, required this.owner}) : super(key: key);

  @override
  _VeterinaryListScreenState createState() => _VeterinaryListScreenState();
}

class _VeterinaryListScreenState extends State<VeterinaryListScreen> {
  late Future<List<Owner>> _vetsFuture; 

  @override
  void initState() {
    super.initState();
    _vetsFuture = DatabaseHelper.instance.getVets(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un vétérinaire'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: FutureBuilder<List<Owner>>( 
        future: _vetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement: \${snapshot.error}"));
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

  Widget _buildVetCard(Owner vet) { 
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VeterinaryDetailScreen(
                vet: vet,       
                owner: widget.owner, 
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: vet.photoPath != null && vet.photoPath!.isNotEmpty
                  ? FileImage(File(vet.photoPath!))
                  : null,
              child: (vet.photoPath == null || vet.photoPath!.isEmpty) ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. \${vet.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
