class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final String? species;
  final String? photoPath;

  // NOUVEAUX CHAMPS PROMO
  final bool isOnSale;
  final double? salePrice;
  final int? salePercentage;

  // NOUVEAU CHAMP GALERIE
  final String? additionalPhotos;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.stock = 0,
    this.species,
    this.photoPath,
    this.isOnSale = false,
    this.salePrice,
    this.salePercentage,
    this.additionalPhotos,
  });

  // Prix final affiché
  double get finalPrice => isOnSale && salePrice != null ? salePrice! : price;

  // Liste des photos
  List<String> get allPhotos {
    List<String> photos = [];
    if (photoPath != null && photoPath!.isNotEmpty) {
      photos.add(photoPath!);
    }
    if (additionalPhotos != null && additionalPhotos!.isNotEmpty) {
      photos.addAll(additionalPhotos!.split(','));
    }
    return photos;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'species': species,
      'photoPath': photoPath,
      'isOnSale': isOnSale ? 1 : 0,
      'salePrice': salePrice,
      'salePercentage': salePercentage,
      'additionalPhotos': additionalPhotos,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
      stock: map['stock'] as int? ?? 0,
      species: map['species'] as String?,
      photoPath: map['photoPath'] as String?,
      isOnSale: (map['isOnSale'] as int? ?? 0) == 1,
      salePrice: map['salePrice'] != null ? (map['salePrice'] as num).toDouble() : null,
      salePercentage: map['salePercentage'] as int?,
      additionalPhotos: map['additionalPhotos'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    String? species,
    String? photoPath,
    bool? isOnSale,
    double? salePrice,
    int? salePercentage,
    String? additionalPhotos,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      species: species ?? this.species,
      photoPath: photoPath ?? this.photoPath,
      isOnSale: isOnSale ?? this.isOnSale,
      salePrice: salePrice ?? this.salePrice,
      salePercentage: salePercentage ?? this.salePercentage,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
    );
  }
}