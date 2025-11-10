import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'screens/login_screen.dart';
import 'screens/owner_profile_screen.dart';
import 'models/owner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ Ne pas supprimer la DB au démarrage (gardez vos données)
  // Si vous avez besoin de reset en dev :
  // final dbPath = join(await getDatabasesPath(), 'pets.db');
  // await deleteDatabase(dbPath);

  // Initialise la base
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

      // 👉 Ouvre la page d’authentification en premier
      home: const LoginScreen(),

      // (Optionnel) routes nommées pour après le login
      onGenerateRoute: (settings) {
        if (settings.name == '/owner') {
          final owner = settings.arguments as Owner;
          return MaterialPageRoute(
            builder: (_) => OwnerProfileScreen(owner: owner),
          );
        }
        return null;
      },
    );
  }
}
