import 'package:flutter/material.dart';
import '../models/owner.dart';

class VetDashboardScreen extends StatelessWidget {
  final Owner owner; // 🔹 doit correspondre à l'appel depuis LoginScreen

  const VetDashboardScreen({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tableau de bord vétérinaire - ${owner.username}')),
      body: const Center(
        child: Text(
          'Bienvenue ! Voici vos rendez-vous à venir.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
