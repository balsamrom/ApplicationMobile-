import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';

import '../models/alert.dart';
import '../models/cabinet.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/owner.dart';
import '../models/pet.dart';
import '../models/document.dart';
import '../models/nutrition_log.dart';
import '../models/activity_log.dart';
import '../models/product.dart';
import '../models/vaccine.dart';
import '../models/veterinary_appointment.dart';
import '../models/blog.dart';
import '../models/blog_reaction.dart';

class DatabaseHelper{
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  static const String _dbName = 'pets.db';
  static const int _dbVersion = 16; // ✅ Version augmentée (added blog tables)

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

    await db.execute('''
      CREATE TABLE veterinary_appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veterinaryId INTEGER NOT NULL,
        petId INTEGER NOT NULL,
        dateTime TEXT NOT NULL,
        reason TEXT,
        status TEXT NOT NULL DEFAULT 'scheduled',
        notes TEXT,
        treatments TEXT,
        veterinaryName TEXT,
        petName TEXT,
        createdAt TEXT,
        FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cabinets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veterinaryId INTEGER NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vaccinations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        vaccineName TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      );
    ''');

    // ✅ Création de la table ALERTS
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId INTEGER NOT NULL,
        petId INTEGER,
        emergencyTitle TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE SET NULL
      );
    ''');
    // ==================== 🛒 SHOP & E-COMMERCE TABLES ====================

// Products
    await db.execute('''
  CREATE TABLE IF NOT EXISTS products(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    price REAL NOT NULL,
    category TEXT NOT NULL,
    photoPath TEXT,
    stock INTEGER DEFAULT 0,
    species TEXT,
    isOnSale INTEGER DEFAULT 0,
    salePrice REAL,
    salePercentage INTEGER,
    additionalPhotos TEXT
  );
''');

// Cart items
    await db.execute('''
  CREATE TABLE IF NOT EXISTS cart_items(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    product_price REAL NOT NULL,
    product_photo TEXT,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  );
''');

// Orders
    await db.execute('''
  CREATE TABLE IF NOT EXISTS orders(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    total_amount REAL NOT NULL,
    status TEXT DEFAULT 'En cours',
    delivery_address TEXT,
    phone_number TEXT,
    delivery_method TEXT,
    payment_method TEXT,
    notes TEXT,
    delivery_fee REAL DEFAULT 0,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE
  );
''');

// Order items
    await db.execute('''
  CREATE TABLE IF NOT EXISTS order_items(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    price REAL NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  );
''');

// Favorites
    await db.execute('''
  CREATE TABLE IF NOT EXISTS favorites(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    added_date TEXT NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE(owner_id, product_id)
  );
''');
    // ==================== 🛒 SHOP & E-COMMERCE TABLES ====================

// Products
    await db.execute('''
  CREATE TABLE IF NOT EXISTS products(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    price REAL NOT NULL,
    category TEXT NOT NULL,
    photoPath TEXT,
    stock INTEGER DEFAULT 0,
    species TEXT,
    isOnSale INTEGER DEFAULT 0,
    salePrice REAL,
    salePercentage INTEGER,
    additionalPhotos TEXT
  );
''');

// Cart items
    await db.execute('''
  CREATE TABLE IF NOT EXISTS cart_items(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    product_price REAL NOT NULL,
    product_photo TEXT,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  );
''');

// Orders
    await db.execute('''
  CREATE TABLE IF NOT EXISTS orders(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    total_amount REAL NOT NULL,
    status TEXT DEFAULT 'En cours',
    delivery_address TEXT,
    phone_number TEXT,
    delivery_method TEXT,
    payment_method TEXT,
    notes TEXT,
    delivery_fee REAL DEFAULT 0,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE
  );
''');

// Order items
    await db.execute('''
  CREATE TABLE IF NOT EXISTS order_items(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    price REAL NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  );
''');

// Favorites
    await db.execute('''
  CREATE TABLE IF NOT EXISTS favorites(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    added_date TEXT NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE(owner_id, product_id)
  );
''');

// 🧩 Insère les produits de démonstration
    await _insertSampleProducts(db);

    // ==================== 📝 BLOG TABLES ====================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS blogs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veterinaryId INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        imagePath TEXT,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        veterinaryName TEXT,
        veterinaryPhoto TEXT,
        FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS blog_reactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        blogId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        reactionType TEXT NOT NULL DEFAULT 'like',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (blogId) REFERENCES blogs(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES owners(id) ON DELETE CASCADE,
        UNIQUE(blogId, userId)
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
      if (oldVersion < 9) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS veterinary_appointments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veterinaryId INTEGER NOT NULL,
            petId INTEGER NOT NULL,
            dateTime TEXT NOT NULL,
            reason TEXT,
            status TEXT NOT NULL DEFAULT 'scheduled',
            notes TEXT,
            treatments TEXT,
            veterinaryName TEXT,
            petName TEXT,
            createdAt TEXT,
            FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE,
            FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
          );
        ''');
      }
      if (oldVersion < 10) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS cabinets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veterinaryId INTEGER NOT NULL,
            address TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE
          );
        ''');
      }
      if (oldVersion < 11) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS vaccinations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            petId INTEGER NOT NULL,
            vaccineName TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT,
            FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
          );
        ''');
      }
      // ✅ Ajout table ALERTS dans la mise à jour
      if (oldVersion < 12) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ownerId INTEGER NOT NULL,
            petId INTEGER,
            emergencyTitle TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (ownerId) REFERENCES owners(id) ON DELETE CASCADE,
            FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE SET NULL
          );
        ''');
      }
      // ✅ Ajout tables BLOG dans la mise à jour
      if (oldVersion < 16) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS blogs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veterinaryId INTEGER NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            imagePath TEXT,
            category TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT,
            veterinaryName TEXT,
            veterinaryPhoto TEXT,
            FOREIGN KEY (veterinaryId) REFERENCES owners(id) ON DELETE CASCADE
          );
        ''');
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS blog_reactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            blogId INTEGER NOT NULL,
            userId INTEGER NOT NULL,
            reactionType TEXT NOT NULL DEFAULT 'like',
            createdAt TEXT NOT NULL,
            FOREIGN KEY (blogId) REFERENCES blogs(id) ON DELETE CASCADE,
            FOREIGN KEY (userId) REFERENCES owners(id) ON DELETE CASCADE,
            UNIQUE(blogId, userId)
          );
        ''');
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

    Future<List<Owner>> getVets() async {
    final db = await instance.database;
    final res = await db.query('owners', where: 'isVet = 1 AND isVetApproved = 1', orderBy: 'id DESC');
    return res.map((map) => Owner.fromMap(map)).toList();
  }

  Future<List<Owner>> getVeterinarians() async {
    final db = await instance.database;
    final res = await db.query('owners', where: 'isVet = 1', orderBy: 'id DESC');
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
  Future<void> saveCabinet(Cabinet cabinet) async {
    final db = await instance.database;
    final existing = await db.query('cabinets',
        where: 'veterinaryId = ?', whereArgs: [cabinet.veterinaryId]);

    if (existing.isNotEmpty) {
      await db.update('cabinets', cabinet.toMap(),
          where: 'veterinaryId = ?', whereArgs: [cabinet.veterinaryId]);
    } else {
      await db.insert('cabinets', cabinet.toMap());
    }
  }

  Future<Cabinet?> getCabinetForVet(int vetId) async {
    final db = await instance.database;
    final res =
    await db.query('cabinets', where: 'veterinaryId = ?', whereArgs: [vetId]);
    if (res.isNotEmpty) return Cabinet.fromMap(res.first);
    return null;
  }

  Future<void> deleteCabinet(int vetId) async {
    final db = await instance.database;
    await db.delete('cabinets', where: 'veterinaryId = ?', whereArgs: [vetId]);
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
  Future<void> bookAppointment(VeterinaryAppointment app) async =>
      (await database).insert('veterinary_appointments', app.toMap());

  Future<void> updateAppointment(VeterinaryAppointment app) async =>
      (await database).update('veterinary_appointments', app.toMap(),
          where: 'id = ?', whereArgs: [app.id]);

  Future<void> cancelAppointment(int id) async => (await database).update(
      'veterinary_appointments', {'status': 'cancelled'},
      where: 'id = ?', whereArgs: [id]);

  Future<List<VeterinaryAppointment>> getAppointmentsForVeterinary(
      int vetId) async {
    final maps = await (await database).query('veterinary_appointments',
        where: 'veterinaryId = ?', whereArgs: [vetId], orderBy: 'dateTime DESC');
    return maps.map((m) => VeterinaryAppointment.fromMap(m)).toList();
  }

  Future<List<VeterinaryAppointment>> getAllAppointments() async {
    final db = await instance.database;
    final maps = await db.query('veterinary_appointments', orderBy: 'dateTime DESC');
    return maps.map((m) => VeterinaryAppointment.fromMap(m)).toList();
  }
// ==================== PRODUCTS CRUD ====================
  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final res = await db.query('products');
    return res.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await instance.database;
    final res = await db.query('products', where: 'category = ?', whereArgs: [category]);
    return res.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getProductsBySpecies(String? species) async {
    final db = await instance.database;
    final res = await db.query('products', where: 'species = ? OR species IS NULL', whereArgs: [species]);
    return res.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final res = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Product.fromMap(res.first);
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CART CRUD ====================
  Future<int> addToCart(CartItem item) async {
    final db = await instance.database;
    final existing = await db.query(
      'cart_items',
      where: 'owner_id = ? AND product_id = ?',
      whereArgs: [item.ownerId, item.productId],
    );

    if (existing.isNotEmpty) {
      final existingItem = CartItem.fromMap(existing.first);
      existingItem.quantity += item.quantity;
      return await db.update('cart_items', existingItem.toMap(), where: 'id = ?', whereArgs: [existingItem.id]);
    } else {
      return await db.insert('cart_items', item.toMap());
    }
  }
// ==================== 🛍️ PRODUCTS CRUD ====================


  Future<List<CartItem>> getCartItems(int ownerId) async {
    final db = await instance.database;
    final res = await db.query('cart_items', where: 'owner_id = ?', whereArgs: [ownerId]);
    return res.map((m) => CartItem.fromMap(m)).toList();
  }

  Future<int> updateCartItem(CartItem item) async {
    final db = await instance.database;
    return await db.update('cart_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteCartItem(int id) async {
    final db = await instance.database;
    return await db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearCart(int ownerId) async {
    final db = await instance.database;
    return await db.delete('cart_items', where: 'owner_id = ?', whereArgs: [ownerId]);
  }

// ==================== 📦 ORDERS CRUD ====================
  Future<int> createOrder(Order order, List<OrderItem> items) async {
    final db = await instance.database;
    final orderId = await db.insert('orders', order.toMap());

    for (var item in items) {
      item.orderId = orderId;
      await db.insert('order_items', item.toMap());
    }

    return orderId;
  }

  Future<List<Order>> getOrdersByOwner(int ownerId) async {
    final db = await instance.database;
    final res = await db.query(
      'orders',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'order_date DESC',
    );
    return res.map((m) => Order.fromMap(m)).toList();
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await instance.database;
    final res = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    return res.map((m) => OrderItem.fromMap(m)).toList();
  }

  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await instance.database;
    return await db.update('orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
  }

  Future<int> deleteOrder(int id) async {
    final db = await instance.database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

// ==================== ❤️ FAVORITES CRUD ====================
  Future<int> addToFavorites(int ownerId, int productId) async {
    final db = await instance.database;
    try {
      return await db.insert('favorites', {
        'owner_id': ownerId,
        'product_id': productId,
        'added_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return 0; // déjà présent
    }
  }

  Future<int> removeFromFavorites(int ownerId, int productId) async {
    final db = await instance.database;
    return await db.delete(
      'favorites',
      where: 'owner_id = ? AND product_id = ?',
      whereArgs: [ownerId, productId],
    );
  }

  Future<bool> isFavorite(int ownerId, int productId) async {
    final db = await instance.database;
    final res = await db.query(
      'favorites',
      where: 'owner_id = ? AND product_id = ?',
      whereArgs: [ownerId, productId],
    );
    return res.isNotEmpty;
  }

  Future<List<Product>> getFavoriteProducts(int ownerId) async {
    final db = await instance.database;
    final res = await db.rawQuery('''
    SELECT p.* FROM products p
    INNER JOIN favorites f ON p.id = f.product_id
    WHERE f.owner_id = ?
    ORDER BY f.added_date DESC
  ''', [ownerId]);
    return res.map((m) => Product.fromMap(m)).toList();
  }

// ==================== 🧩 INSÉRER DES PRODUITS DÉMO ====================
  Future _insertSampleProducts(Database db) async {
    final products = [
      {
        'name': 'Croquettes Premium Chien',
        'description': 'Aliment complet pour chien adulte 15kg',
        'price': 45.99,
        'category': 'Aliments',
        'stock': 50,
        'species': 'Chien',
        'isOnSale': 1,
        'salePrice': 35.99,
        'salePercentage': 22
      },
      {
        'name': 'Pâtée Chat Saumon',
        'description': 'Boîte 400g au saumon frais',
        'price': 3.50,
        'category': 'Aliments',
        'stock': 120,
        'species': 'Chat',
        'isOnSale': 0
      },
      {
        'name': 'Laisse Réglable',
        'description': 'Laisse nylon 2m tous chiens',
        'price': 12.99,
        'category': 'Accessoires',
        'stock': 30,
        'species': 'Chien',
        'isOnSale': 0
      },
      {
        'name': 'Arbre à Chat',
        'description': 'Arbre à chat 3 niveaux avec griffoir',
        'price': 89.99,
        'category': 'Accessoires',
        'stock': 15,
        'species': 'Chat',
        'isOnSale': 1,
        'salePrice': 69.99,
        'salePercentage': 22
      },
      {
        'name': 'Shampoing Antiparasitaire',
        'description': 'Shampoing 250ml pour chiens et chats',
        'price': 8.50,
        'category': 'Soins',
        'stock': 40,
        'species': null,
        'isOnSale': 0
      },
      {
        'name': 'Balle Interactive',
        'description': 'Balle lumineuse et sonore',
        'price': 6.99,
        'category': 'Jouets',
        'stock': 4,
        'species': 'Chien',
        'isOnSale': 1,
        'salePrice': 4.99,
        'salePercentage': 29
      },
      {
        'name': 'Souris Mécanique',
        'description': 'Jouet souris remontable pour chat',
        'price': 4.50,
        'category': 'Jouets',
        'stock': 80,
        'species': 'Chat',
        'isOnSale': 0
      },
      {
        'name': 'Graines Oiseaux Mix',
        'description': 'Mélange de graines 1kg',
        'price': 5.99,
        'category': 'Aliments',
        'stock': 45,
        'species': 'Oiseau',
        'isOnSale': 0
      },
    ];

    for (var p in products) {
      await db.insert('products', p);
    }
  }



  Future<int> getFavoritesCount(int ownerId) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM favorites WHERE owner_id = ?',
      [ownerId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }
  // ---------------- VACCINES ----------------
  Future<void> addVaccine(Vaccine vaccine) async =>
      (await database).insert('vaccinations', vaccine.toMap());

  Future<List<Vaccine>> getVaccinesForPet(int petId) async {
    final maps = await (await database).query('vaccinations',
        where: 'petId = ?', whereArgs: [petId], orderBy: 'date DESC');
    return maps.map((m) => Vaccine.fromMap(m)).toList();
  }

    Future<Pet?> getPetById(int id) async {
    final db = await instance.database;
    final res = await db.query('pets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) {
      return Pet.fromMap(res.first);
    }
    return null;
  }

  Future<Owner?> getOwnerById(int id) async {
    final db = await instance.database;
    final res = await db.query('owners', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) {
      return Owner.fromMap(res.first);
    }
    return null;
  }
  // --------------------- OWNERS ---------------------
  Future<List<Owner>> getOwners() async {
    final db = await instance.database;
    final res = await db.query('owners', orderBy: 'id DESC');
    return res.map((map) => Owner.fromMap(map)).toList();
  }

  // --------------------- CABINETS ---------------------
  Future<List<Cabinet>> getAllCabinets() async {
    final db = await instance.database;
    final res = await db.query('cabinets', orderBy: 'id DESC');
    return res.map((map) => Cabinet.fromMap(map)).toList();
  }
  Future<int> insertAlert(Alert alert) async {
    final db = await instance.database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<Alert>> getAlerts() async {
    final db = await instance.database;
    final res = await db.query('alerts', orderBy: 'timestamp DESC');
    return res.map((m) => Alert.fromMap(m)).toList();
  }

  // ==================== 📝 BLOG CRUD ====================
  Future<int> insertBlog(Blog blog) async {
    final db = await instance.database;
    return await db.insert('blogs', blog.toMap());
  }

  Future<List<Blog>> getAllBlogs() async {
    final db = await instance.database;
    final res = await db.query('blogs', orderBy: 'createdAt DESC');
    return res.map((m) => Blog.fromMap(m)).toList();
  }

  Future<List<Blog>> getBlogsByVeterinary(int veterinaryId) async {
    final db = await instance.database;
    final res = await db.query(
      'blogs',
      where: 'veterinaryId = ?',
      whereArgs: [veterinaryId],
      orderBy: 'createdAt DESC',
    );
    return res.map((m) => Blog.fromMap(m)).toList();
  }

  Future<Blog?> getBlogById(int id) async {
    final db = await instance.database;
    final res = await db.query('blogs', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) return Blog.fromMap(res.first);
    return null;
  }

  Future<int> updateBlog(Blog blog) async {
    final db = await instance.database;
    final map = blog.toMap();
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('blogs', map, where: 'id = ?', whereArgs: [blog.id]);
  }

  Future<int> deleteBlog(int id) async {
    final db = await instance.database;
    return await db.delete('blogs', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ❤️ BLOG REACTIONS CRUD ====================
  Future<int> addBlogReaction(BlogReaction reaction) async {
    final db = await instance.database;
    try {
      return await db.insert('blog_reactions', reaction.toMap());
    } catch (e) {
      // If already exists, update it
      return await db.update(
        'blog_reactions',
        reaction.toMap(),
        where: 'blogId = ? AND userId = ?',
        whereArgs: [reaction.blogId, reaction.userId],
      );
    }
  }

  Future<int> removeBlogReaction(int blogId, int userId) async {
    final db = await instance.database;
    return await db.delete(
      'blog_reactions',
      where: 'blogId = ? AND userId = ?',
      whereArgs: [blogId, userId],
    );
  }

  Future<bool> hasUserReacted(int blogId, int userId) async {
    final db = await instance.database;
    final res = await db.query(
      'blog_reactions',
      where: 'blogId = ? AND userId = ?',
      whereArgs: [blogId, userId],
    );
    return res.isNotEmpty;
  }

  Future<String?> getUserReactionType(int blogId, int userId) async {
    final db = await instance.database;
    final res = await db.query(
      'blog_reactions',
      where: 'blogId = ? AND userId = ?',
      whereArgs: [blogId, userId],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return res.first['reactionType'] as String?;
    }
    return null;
  }

  Future<int> getBlogReactionCount(int blogId) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM blog_reactions WHERE blogId = ?',
      [blogId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<BlogReaction>> getBlogReactions(int blogId) async {
    final db = await instance.database;
    final res = await db.query(
      'blog_reactions',
      where: 'blogId = ?',
      whereArgs: [blogId],
      orderBy: 'createdAt DESC',
    );
    return res.map((m) => BlogReaction.fromMap(m)).toList();
  }

}
