class Breed {
  final dynamic id; // ← CHANGÉ de 'int' à 'dynamic' (supporte int ET String)
  final String name;
  final String? description;
  final String? temperament;
  final String? origin;
  final String? lifeSpan;
  final String? weight;
  final String? imageUrl;
  final String? bredFor;
  final String? breedGroup;

  Breed({
    required this.id,
    required this.name,
    this.description,
    this.temperament,
    this.origin,
    this.lifeSpan,
    this.weight,
    this.imageUrl,
    this.bredFor,
    this.breedGroup,
  });

  // Factory pour Dog API
  factory Breed.fromDogJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'] as int, // Dog API utilise int
      name: json['name'] ?? 'Inconnu',
      description: json['description'],
      temperament: json['temperament'],
      origin: json['origin'],
      lifeSpan: json['life_span'],
      weight: json['weight']?['metric'],
      imageUrl: json['image']?['url'],
      bredFor: json['bred_for'],
      breedGroup: json['breed_group'],
    );
  }

  // Factory pour Cat API
  factory Breed.fromCatJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'] as String, // Cat API utilise String
      name: json['name'] ?? 'Inconnu',
      description: json['description'],
      temperament: json['temperament'],
      origin: json['origin'],
      lifeSpan: json['life_span'],
      weight: json['weight']?['metric'],
      imageUrl: json['image']?['url'],
      bredFor: null,
      breedGroup: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'temperament': temperament,
      'origin': origin,
      'life_span': lifeSpan,
      'weight': weight,
      'image_url': imageUrl,
      'bred_for': bredFor,
      'breed_group': breedGroup,
    };
  }
}