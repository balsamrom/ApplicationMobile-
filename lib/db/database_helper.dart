import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pet_owner_app/models/alert.dart';
import 'package:sqflite/sqflite.dart';
import '../models/owner.dart';
import '../models/pet.dart';
import '../models/document.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pets.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);

    return await openDatabase(
      path,
      version: 4, // Incremented version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE owners(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        photoPath TEXT,
        isVet INTEGER DEFAULT 0,
        diplomaPath TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId INTEGER NOT NULL,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT,
        gender TEXT,
        age INTEGER,
        weight REAL,
        photo TEXT,
        FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId INTEGER NOT NULL,
        petId INTEGER,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS alerts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId INTEGER NOT NULL,
        petId INTEGER NOT NULL,
        emergencyTitle TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS alerts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ownerId INTEGER NOT NULL,
          petId INTEGER NOT NULL,
          emergencyTitle TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE,
          FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
        );
      ''');
    }
  }

  // ---------------- Owner CRUD ----------------
  Future<int> insertOwner(Owner owner) async {
    final db = await instance.database;
    return await db.insert('owners', owner.toMap());
  }

  Future<Owner?> getOwnerByUsernameAndPassword(String username, String password) async {
    final db = await instance.database;
    final res = await db.query(
      'owners',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (res.isNotEmpty) return Owner.fromMap(res.first);
    return null;
  }

  Future<Owner?> getOwnerById(int id) async {
    final db = await instance.database;
    final res = await db.query('owners', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Owner.fromMap(res.first);
    return null;
  }

  Future<int> updateOwner(Owner owner) async {
    final db = await instance.database;
    return await db.update('owners', owner.toMap(), where: 'id = ?', whereArgs: [owner.id]);
  }

  // ---------------- Pet CRUD ----------------
  Future<int> insertPet(Pet pet) async {
    final db = await instance.database;
    return await db.insert('pets', pet.toMap());
  }

  Future<Pet?> getPetById(int id) async {
    final db = await instance.database;
    final res = await db.query('pets', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Pet.fromMap(res.first);
    return null;
  }

  Future<List<Pet>> getPetsByOwner(int ownerId) async {
    final db = await instance.database;
    final res = await db.query('pets', where: 'ownerId = ?', whereArgs: [ownerId]);
    return res.map((m) => Pet.fromMap(m)).toList();
  }

  Future<int> updatePet(Pet pet) async {
    final db = await instance.database;
    return await db.update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);
  }

  Future<int> deletePet(int id) async {
    final db = await instance.database;
    return await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Documents ----------------
  Future<int> insertDocument(DocumentItem doc) async {
    final db = await instance.database;
    return await db.insert('documents', doc.toMap());
  }

  Future<List<DocumentItem>> getDocumentsForOwner(int ownerId) async {
    final db = await instance.database;
    final res = await db.query('documents', where: 'ownerId = ?', whereArgs: [ownerId]);
    return res.map((m) => DocumentItem.fromMap(m)).toList();
  }

  // ---------------- Alerts ----------------
  Future<int> insertAlert(Alert alert) async {
    final db = await instance.database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<Alert>> getAlerts() async {
    final db = await instance.database;
    final res = await db.query('alerts', orderBy: 'timestamp DESC');
    return res.map((m) => Alert.fromMap(m)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
