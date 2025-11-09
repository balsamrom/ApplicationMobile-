import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'db/database_helper.dart';

void main() async {
  // On s'assure que les widgets sont initialisés avant toute chose.
  WidgetsFlutterBinding.ensureInitialized();
  
  // CORRIGÉ : On initialise simplement la base de données, sans jamais la supprimer.
  await DatabaseHelper.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Owner Manager',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LoginScreen(),
    );
  }
}
