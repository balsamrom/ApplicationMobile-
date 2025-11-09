import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/owner.dart';
import '../models/pet.dart';
import '../models/document.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

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
      version: 7, // ✅ VERSION 7
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 3: Ajout colonnes vétérinaires
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE owners ADD COLUMN isVet INTEGER DEFAULT 0;');
          await db.execute('ALTER TABLE owners ADD COLUMN diplomaPath TEXT;');
        }

        // Version 4: Création tables shop
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE products(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              price REAL NOT NULL,
              category TEXT NOT NULL,
              photoPath TEXT,
              stock INTEGER DEFAULT 0,
              species TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE cart_items(
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

          await db.execute('''
            CREATE TABLE orders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              owner_id INTEGER NOT NULL,
              order_date TEXT NOT NULL,
              total_amount REAL NOT NULL,
              status TEXT DEFAULT 'En cours',
              delivery_address TEXT,
              FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE order_items(
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

          await _insertSampleProducts(db);
        }

        // Version 5: Ajout promotions et galerie
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE products ADD COLUMN isOnSale INTEGER DEFAULT 0;');
          await db.execute('ALTER TABLE products ADD COLUMN salePrice REAL;');
          await db.execute('ALTER TABLE products ADD COLUMN salePercentage INTEGER;');
          await db.execute('ALTER TABLE products ADD COLUMN additionalPhotos TEXT;');
        }

        // Version 6: Ajout infos commande détaillées
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE orders ADD COLUMN phone_number TEXT;');
          await db.execute('ALTER TABLE orders ADD COLUMN delivery_method TEXT;');
          await db.execute('ALTER TABLE orders ADD COLUMN payment_method TEXT;');
          await db.execute('ALTER TABLE orders ADD COLUMN notes TEXT;');
        }

        // ✅ Version 7: Table Favoris
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE favorites(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              owner_id INTEGER NOT NULL,
              product_id INTEGER NOT NULL,
              added_date TEXT NOT NULL,
              FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
              FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
              UNIQUE(owner_id, product_id)
            );
          ''');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // Table Owners
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

    // Table Pets
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

    // Table Documents
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

    // Table Products (avec promotions et galerie)
    await db.execute('''
      CREATE TABLE products(
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

    // Table Cart Items
    await db.execute('''
      CREATE TABLE cart_items(
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

    // Table Orders (avec infos complètes)
    await db.execute('''
      CREATE TABLE orders(
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
        FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE
      );
    ''');

    // Table Order Items
    await db.execute('''
      CREATE TABLE order_items(
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

    // ✅ Table Favorites
    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        added_date TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        UNIQUE(owner_id, product_id)
      );
    ''');

    // Insérer produits d'exemple
    await _insertSampleProducts(db);
  }

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

  // ==================== OWNER CRUD ====================
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

  // ==================== PET CRUD ====================
  Future<int> insertPet(Pet pet) async {
    final db = await instance.database;
    return await db.insert('pets', pet.toMap());
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

  // ==================== DOCUMENTS ====================
  Future<int> insertDocument(DocumentItem doc) async {
    final db = await instance.database;
    return await db.insert('documents', doc.toMap());
  }

  Future<List<DocumentItem>> getDocumentsForOwner(int ownerId) async {
    final db = await instance.database;
    final res = await db.query('documents', where: 'ownerId = ?', whereArgs: [ownerId]);
    return res.map((m) => DocumentItem.fromMap(m)).toList();
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

  // ==================== ORDERS CRUD ====================
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
    final res = await db.query('orders', where: 'owner_id = ?', whereArgs: [ownerId], orderBy: 'order_date DESC');
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

  // ==================== FAVORITES CRUD ====================
  Future<int> addToFavorites(int ownerId, int productId) async {
    final db = await instance.database;
    try {
      return await db.insert('favorites', {
        'owner_id': ownerId,
        'product_id': productId,
        'added_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return 0; // Déjà dans les favoris
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

  Future<int> getFavoritesCount(int ownerId) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM favorites WHERE owner_id = ?',
      [ownerId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ==================== CLOSE ====================
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}