class Pet {
  int? id;
  int ownerId;
  String name;
  String species;
  String? breed;
  String? gender; // Mâle ou Femelle
  int? age;
  double? weight;
  String? photo;
  List<String>? analysis;

  Pet({
    this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.age,
    this.weight,
    this.photo,
    this.analysis,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'species': species,
    'breed': breed,
    'gender': gender,
    'age': age,
    'weight': weight,
    'photo': photo,
  };

  factory Pet.fromMap(Map<String, dynamic> m) => Pet(
    id: m['id'] as int?,
    ownerId: m['ownerId'] as int,
    name: m['name'] as String,
    species: m['species'] as String,
    breed: m['breed'] as String?,
    gender: m['gender'] as String?,
    age: m['age'] as int?,
    weight: m['weight'] == null ? null : (m['weight'] as num).toDouble(),
    photo: m['photo'] as String?,
  );

  Pet copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? species,
    String? breed,
    String? gender,
    int? age,
    double? weight,
    String? photo,
    List<String>? analysis,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      photo: photo ?? this.photo,
      analysis: analysis ?? this.analysis,
    );
  }
}
