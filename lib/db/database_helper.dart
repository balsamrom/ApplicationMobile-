import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/owner.dart';
import '../models/pet.dart';
import '../models/document.dart';
import '../models/veterinary.dart';
import '../models/cabinet.dart'; 
import '../models/veterinary_appointment.dart';
import '../models/vaccine.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _version = 5;

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
      version: _version,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await _onUpgrade(db, 0, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await db.execute('''CREATE TABLE owners(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE, password TEXT NOT NULL, name TEXT NOT NULL, email TEXT, phone TEXT, photoPath TEXT);''');
      await db.execute('''CREATE TABLE pets(id INTEGER PRIMARY KEY AUTOINCREMENT, ownerId INTEGER NOT NULL, name TEXT NOT NULL, species TEXT NOT NULL, breed TEXT, gender TEXT, age INTEGER, weight REAL, photo TEXT, FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE);''');
      await db.execute('''CREATE TABLE documents(id INTEGER PRIMARY KEY AUTOINCREMENT, ownerId INTEGER NOT NULL, petId INTEGER, title TEXT NOT NULL, filePath TEXT NOT NULL, FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE, FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE SET NULL);''');
    }

    if (oldVersion < 4) {
        await db.execute('ALTER TABLE owners ADD COLUMN isVet INTEGER DEFAULT 0;');
        await db.execute('ALTER TABLE owners ADD COLUMN isAdmin INTEGER DEFAULT 0;');
        await db.execute('ALTER TABLE owners ADD COLUMN specialty TEXT;');
        await db.execute('''CREATE TABLE veterinary_appointments(id INTEGER PRIMARY KEY AUTOINCREMENT, veterinaryId INTEGER NOT NULL, veterinaryName TEXT NOT NULL, petId INTEGER NOT NULL, petName TEXT NOT NULL, dateTime TEXT NOT NULL, reason TEXT NOT NULL, status TEXT NOT NULL, notes TEXT, treatments TEXT, createdAt TEXT NOT NULL, FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE, FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE);''');
        await db.execute('''CREATE TABLE vaccinations(id INTEGER PRIMARY KEY AUTOINCREMENT, petId INTEGER NOT NULL, name TEXT NOT NULL, date TEXT NOT NULL, nextBooster TEXT, FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE);''');
        await db.insert('owners', {'username': 'admin', 'password': 'admin', 'name': 'Admin', 'isAdmin': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE cabinets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          veterinaryId INTEGER NOT NULL UNIQUE,
          address TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE
        );
      ''');
    }
  }

  Future<int> insertOwner(Owner owner) async {
    final db = await instance.database;
    return await db.insert('owners', owner.toMap());
  }

  Future<Owner?> getOwnerByUsernameAndPassword(String username, String password) async {
    final db = await instance.database;
    final res = await db.query('owners', where: 'username = ? AND password = ?', whereArgs: [username, password]);
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

  Future<int> deleteOwner(int id) async {
    final db = await instance.database;
    return await db.delete('owners', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertPet(Pet pet) async => (await instance.database).insert('pets', pet.toMap());
  Future<List<Pet>> getPetsByOwner(int ownerId) async {
    final res = await (await instance.database).query('pets', where: 'ownerId = ?', whereArgs: [ownerId]);
    return res.map((m) => Pet.fromMap(m)).toList();
  }
  Future<Pet?> getPetById(int id) async {
    final maps = await (await database).query('pets', where: 'id = ?', whereArgs: [id]);
    if(maps.isNotEmpty) return Pet.fromMap(maps.first);
    return null;
  }
  Future<int> updatePet(Pet pet) async => (await instance.database).update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);
  Future<int> deletePet(int id) async => (await instance.database).delete('pets', where: 'id = ?', whereArgs: [id]);
  
  Future<int> insertDocument(DocumentItem doc) async => (await instance.database).insert('documents', doc.toMap());
  Future<List<DocumentItem>> getDocumentsForOwner(int ownerId) async {
    final res = await (await instance.database).query('documents', where: 'ownerId = ?', whereArgs: [ownerId]);
    return res.map((m) => DocumentItem.fromMap(m)).toList();
  }

  Future<List<Veterinary>> getVeterinarians() async {
    final db = await database;
    final vetOwnerMaps = await db.query('owners', where: 'isVet = 1');
    
    List<Veterinary> vets = [];
    for (var ownerMap in vetOwnerMaps) {
        final owner = Owner.fromMap(ownerMap);
        final cabinetMaps = await db.query('cabinets', where: 'veterinaryId = ?', whereArgs: [owner.id]);
        Cabinet? cabinet;
        if (cabinetMaps.isNotEmpty) {
            cabinet = Cabinet.fromMap(cabinetMaps.first);
        }
        vets.add(Veterinary(owner: owner, cabinet: cabinet));
    }
    return vets;
  }

  // CORRIGÉ: Ajout de la fonction qui manquait.
  Future<int> updateVeterinaryProfile(Map<String, dynamic> data, int vetId) async {
    final db = await instance.database;
    return await db.update('owners', data, where: 'id = ?', whereArgs: [vetId]);
  }
  
  Future<void> saveCabinet(Cabinet cabinet) async {
    final db = await instance.database;
    final existing = await db.query('cabinets', where: 'veterinaryId = ?', whereArgs: [cabinet.veterinaryId]);

    if (existing.isNotEmpty) {
      await db.update('cabinets', cabinet.toMap(), where: 'veterinaryId = ?', whereArgs: [cabinet.veterinaryId]);
    } else {
      await db.insert('cabinets', cabinet.toMap());
    }
  }

  Future<void> bookAppointment(VeterinaryAppointment app) async => (await database).insert('veterinary_appointments', app.toMap());
  Future<void> updateAppointment(VeterinaryAppointment app) async => (await database).update('veterinary_appointments', app.toMap(), where: 'id = ?', whereArgs: [app.id]);
  Future<void> cancelAppointment(int id) async => (await database).update('veterinary_appointments', {'status': 'cancelled'}, where: 'id = ?', whereArgs: [id]);
  Future<List<VeterinaryAppointment>> getAllAppointments() async {
    final maps = await (await database).query('veterinary_appointments', orderBy: 'dateTime DESC');
    return maps.map((m) => VeterinaryAppointment.fromMap(m)).toList();
  }
  Future<List<VeterinaryAppointment>> getAppointmentsForVeterinary(int vetId) async {
    final maps = await (await database).query('veterinary_appointments', where: 'veterinaryId = ?', whereArgs: [vetId], orderBy: 'dateTime DESC');
    return maps.map((m) => VeterinaryAppointment.fromMap(m)).toList();
  }

  Future<void> addVaccine(Vaccine vaccine) async => (await database).insert('vaccinations', vaccine.toMap());
  Future<List<Vaccine>> getVaccinesForPet(int petId) async {
    final maps = await (await database).query('vaccinations', where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC');
    return maps.map((m) => Vaccine.fromMap(m)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
