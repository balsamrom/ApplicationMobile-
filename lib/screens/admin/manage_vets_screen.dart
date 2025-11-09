import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/veterinary.dart';
import 'add_edit_vet_screen.dart';

class ManageVetsScreen extends StatefulWidget {
  const ManageVetsScreen({Key? key}) : super(key: key);

  @override
  _ManageVetsScreenState createState() => _ManageVetsScreenState();
}

class _ManageVetsScreenState extends State<ManageVetsScreen> {
  late Future<List<Veterinary>> _vetsFuture;

  @override
  void initState() {
    super.initState();
    _refreshVets();
  }

  void _refreshVets() {
    setState(() {
      _vetsFuture = DatabaseHelper.instance.getVeterinarians();
    });
  }

  Future<void> _deleteVet(int vetId) async {
    await DatabaseHelper.instance.deleteOwner(vetId);
    _refreshVets();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vétérinaire supprimé avec succès.')),
      );
    }
  }

  void _navigateToAddEditVet({Veterinary? vet}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditVetScreen(vet: vet),
      ),
    );
    _refreshVets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Vétérinaires'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un vétérinaire',
            onPressed: () => _navigateToAddEditVet(),
          ),
        ],
      ),
      body: FutureBuilder<List<Veterinary>>(
        future: _vetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun vétérinaire trouvé.'));
          }

          final vets = snapshot.data!;
          return ListView.builder(
            itemCount: vets.length,
            itemBuilder: (context, index) {
              final vet = vets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: const Icon(Icons.medical_services_outlined)),
                  title: Text('Dr. ${vet.owner.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(vet.specialty ?? 'Spécialité non définie'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToAddEditVet(vet: vet),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(vet.owner.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int vetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce vétérinaire ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVet(vetId);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
