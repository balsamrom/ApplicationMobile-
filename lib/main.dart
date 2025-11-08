import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/login_screen.dart';
import 'screens/shop_screen.dart';
import 'db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  final dbPath = join(await getDatabasesPath(), 'pet.db');
  await deleteDatabase(dbPath);

  // --- Initialiser la DB avant de lancer l'application ---
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
      // 🎯 Direct lel ShopScreen pour tester
      home: const ShopScreen(ownerId: 1),
      // Pour retourner au login normal, décommente la ligne ci-dessous:
      // home: const LoginScreen(),
    );
  }
}