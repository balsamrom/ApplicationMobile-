class Product {
  int? id;
  String name;
  String description;
  double price;
  String category; // 'Aliments', 'Accessoires', 'Soins', 'Jouets'
  String? photoPath;
  int stock;
  String? species; // Pour quel animal? 'Chien', 'Chat', 'Oiseau', etc. (null = tous)

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.photoPath,
    this.stock = 0,
    this.species,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'photoPath': photoPath,
    'stock': stock,
    'species': species,
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] as int?,
    name: m['name'] as String,
    description: m['description'] as String,
    price: (m['price'] as num).toDouble(),   // ✅ important
    category: m['category'] as String,
    photoPath: m['photoPath'] as String?,
    stock: (m['stock'] as num?)?.toInt() ?? 0, // ✅ robuste
    species: m['species'] as String?,
  );

}