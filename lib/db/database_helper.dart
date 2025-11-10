import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';

import '../models/owner.dart';
import '../models/pet.dart';
import '../models/document.dart';
import '../models/nutrition_log.dart';
import '../models/activity_log.dart';

class DatabaseHelper {
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  static const String _dbName = 'pets.db';
  static const int _dbVersion = 9;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE owners(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        photoPath TEXT,
        isVet INTEGER DEFAULT 0,
        isVetApproved INTEGER DEFAULT 0,
        isAdmin INTEGER DEFAULT 0,
        diplomaPath TEXT,
        createdAt TEXT
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
        createdAt TEXT,
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

    await _createNutritionTable(db);
    await _createActivityTable(db);
    await _seedAdmin(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 3) {
        await txn.execute('ALTER TABLE owners ADD COLUMN isVet INTEGER DEFAULT 0;');
        await txn.execute('ALTER TABLE owners ADD COLUMN diplomaPath TEXT;');
      }
      if (oldVersion < 4) {
        await txn.execute('ALTER TABLE owners ADD COLUMN isVetApproved INTEGER DEFAULT 0;');
      }
      if (oldVersion < 5) {
        await txn.execute('ALTER TABLE owners ADD COLUMN isAdmin INTEGER DEFAULT 0;');
      }
      if (oldVersion < 6) {
        await _createNutritionTable(txn);
      }
      if (oldVersion < 7) {
        await _createActivityTable(txn);
      }
      if (oldVersion < 8) {
        await txn.execute('ALTER TABLE owners ADD COLUMN createdAt TEXT;');
        await txn.execute('ALTER TABLE pets ADD COLUMN createdAt TEXT;');
      }

      await _seedAdmin(txn);
    });
  }

  static Future<void> _createNutritionTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        foodType TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        logDate TEXT NOT NULL,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');
  }

  static Future<void> _createActivityTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        activityType TEXT NOT NULL,
        durationInMinutes INTEGER NOT NULL,
        notes TEXT,
        logDate TEXT NOT NULL,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');
  }

  static Future<void> _seedAdmin(DatabaseExecutor db) async {
    final r = await db.rawQuery(
      'SELECT COUNT(*) c FROM owners WHERE username = ? OR email = ?',
      ['admin', 'admin@petcare.com'],
    );
    final count = Sqflite.firstIntValue(r) ?? 0;

    if (count == 0) {
      final String salt = BCrypt.gensalt();
      final String hashed = BCrypt.hashpw('admin123', salt);
      await db.insert('owners', {
        'username': 'admin',
        'name': 'Administrateur',
        'email': 'admin@petcare.com',
        'password': hashed,
        'isAdmin': 1,
        'isVet': 0,
        'isVetApproved': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> ensureAdmin() async {
    final db = await instance.database;
    await _seedAdmin(db);
  }

  Future<List<Owner>> getAllUsers() async {
    final db = await instance.database;
    final res = await db.query(
      'owners',
      where: 'isAdmin = 0',
      orderBy: 'id DESC',
    );
    return res.map((map) => Owner.fromMap(map)).toList();
  }

  Future<int> deleteOwner(int id) async {
    final db = await instance.database;
    return await db.delete('owners', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertOwner(Owner owner) async {
    final db = await instance.database;
    final map = owner.toMap();
    map['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('owners', map, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Owner?> getOwnerByEmailAndPassword(String email, String password) async {
    final db = await instance.database;
    final res = await db.query('owners',
        where: 'email = ?', whereArgs: [email], limit: 1);
    if (res.isNotEmpty) {
      final m = res.first;
      final storedHash = m['password'] as String;
      if (BCrypt.checkpw(password, storedHash)) {
        return Owner.fromMap(m);
      }
    }
    return null;
  }

  Future<Owner?> getOwnerByEmail(String email) async {
    final db = await instance.database;
    final res = await db.query('owners',
        where: 'email = ?', whereArgs: [email], limit: 1);
    if (res.isNotEmpty) return Owner.fromMap(res.first);
    return null;
  }

  Future<int> updateOwnerPassword(String email, String newPassword) async {
    final db = await instance.database;
    final salt = BCrypt.gensalt();
    final hashed = BCrypt.hashpw(newPassword, salt);
    return await db.update('owners', {'password': hashed},
        where: 'email = ?', whereArgs: [email]);
  }

  Future<List<Owner>> getPendingVets() async {
    final db = await instance.database;
    final res = await db.query('owners',
        where: 'isVet = 1 AND isVetApproved = 0', orderBy: 'id DESC');
    return res.map((map) => Owner.fromMap(map)).toList();
  }

  Future<int> updateOwner(Owner owner) async {
    final db = await instance.database;
    return await db.update('owners', owner.toMap(),
        where: 'id = ?', whereArgs: [owner.id]);
  }

  Future<int> insertPet(Pet pet) async {
    final db = await instance.database;
    final map = pet.toMap();
    map['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('pets', map,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Pet>> getPetsByOwner(int ownerId) async {
    final db = await instance.database;
    final res = await db.query('pets',
        where: 'ownerId = ?', whereArgs: [ownerId], orderBy: 'id DESC');
    return res.map((m) => Pet.fromMap(m)).toList();
  }

  Future<List<Pet>> getAllPets() async {
    final db = await instance.database;
    final res = await db.query('pets', orderBy: 'id DESC');
    return res.map((m) => Pet.fromMap(m)).toList();
  }

  Future<int> updatePet(Pet pet) async {
    final db = await instance.database;
    return await db.update('pets', pet.toMap(),
        where: 'id = ?', whereArgs: [pet.id]);
  }

  Future<int> deletePet(int id) async {
    final db = await instance.database;
    return await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDocument(DocumentItem doc) async {
    final db = await instance.database;
    return await db.insert('documents', doc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<DocumentItem>> getDocumentsForOwner(int ownerId) async {
    final db = await instance.database;
    final res = await db.query('documents',
        where: 'ownerId = ?', whereArgs: [ownerId], orderBy: 'id DESC');
    return res.map((m) => DocumentItem.fromMap(m)).toList();
  }

  Future<int> insertNutritionLog(NutritionLog log) async {
    final db = await instance.database;
    final data = log.toMap()..['logDate'] = log.logDate.toIso8601String();
    return await db.insert('nutrition_logs', data);
  }

  Future<List<NutritionLog>> getNutritionLogsForPet(int petId) async {
    final db = await instance.database;
    final res = await db.query(
      'nutrition_logs',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'logDate DESC',
    );
    return res.map((m) => NutritionLog.fromMap(m)).toList();
  }

  Future<List<NutritionLog>> getAllNutritionLogs() async {
    final db = await instance.database;
    final res = await db.query('nutrition_logs', orderBy: 'logDate DESC');
    return res.map((m) => NutritionLog.fromMap(m)).toList();
  }

  Future<int> updateNutritionLog(NutritionLog log) async {
    final db = await instance.database;
    final data = log.toMap()..['logDate'] = log.logDate.toIso8601String();
    return await db.update('nutrition_logs', data,
        where: 'id = ?', whereArgs: [log.id]);
  }

  Future<int> deleteNutritionLog(int id) async {
    final db = await instance.database;
    return await db.delete('nutrition_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await instance.database;
    final data = log.toMap()
      ..['logDate'] = (log.logDate is DateTime)
          ? (log.logDate as DateTime).toIso8601String()
          : log.logDate.toString();
    return await db.insert('activity_logs', data);
  }

  Future<List<ActivityLog>> getActivityLogsForPet(int petId) async {
    final db = await instance.database;
    final res = await db.query(
      'activity_logs',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'logDate DESC',
    );
    return res.map((m) {
      final map = Map<String, Object?>.from(m);
      final raw = map['logDate'] as String;
      return ActivityLog.fromMap({
        ...map,
        'logDate': DateTime.tryParse(raw) ?? DateTime.now(),
      });
    }).toList();
  }

  Future<List<ActivityLog>> getAllActivityLogs() async {
    final db = await instance.database;
    final res = await db.query('activity_logs', orderBy: 'logDate DESC');
    return res.map((m) {
      final map = Map<String, Object?>.from(m);
      final raw = map['logDate'] as String;
      return ActivityLog.fromMap({
        ...map,
        'logDate': DateTime.tryParse(raw) ?? DateTime.now(),
      });
    }).toList();
  }

  Future<int> updateActivityLog(ActivityLog log) async {
    final db = await instance.database;
    final data = log.toMap()..['logDate'] = log.logDate.toIso8601String();
    return await db
        .update('activity_logs', data, where: 'id = ?', whereArgs: [log.id]);
  }

  Future<int> deleteActivityLog(int id) async {
    final db = await instance.database;
    return await db.delete('activity_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countTotalUsers() async {
    final db = await instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) FROM owners WHERE isAdmin = 0');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> countTotalPets() async {
    final db = await instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) FROM pets');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> countPendingVets() async {
    final db = await instance.database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) FROM owners WHERE isVet = 1 AND isVetApproved = 0');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> countApprovedVets() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM owners WHERE isVet = 1 AND isVetApproved = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countOwners() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM owners WHERE isVet = 0 AND isAdmin = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getDailyNewUsers(int days) async {
    final db = await instance.database;
    final date = DateTime.now().subtract(Duration(days: days));
    final result = await db.rawQuery(
      "SELECT strftime('%Y-%m-%d', createdAt) as date, COUNT(*) as count FROM owners WHERE createdAt >= ? GROUP BY date",
      [date.toIso8601String()],
    );
    return {for (var e in result) e['date'] as String: e['count'] as int};
  }

  Future<Map<String, int>> getDailyNewPets(int days) async {
    final db = await instance.database;
    final date = DateTime.now().subtract(Duration(days: days));
    final result = await db.rawQuery(
      "SELECT strftime('%Y-%m-%d', createdAt) as date, COUNT(*) as count FROM pets WHERE createdAt >= ? GROUP BY date",
      [date.toIso8601String()],
    );
    return {for (var e in result) e['date'] as String: e['count'] as int};
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
