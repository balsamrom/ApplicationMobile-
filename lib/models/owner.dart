/// Modèle représentant un utilisateur (propriétaire ou vétérinaire).
class Owner {
  int? id;
  String username;
  String password;
  String name;
  String? photoPath;
  String? email;
  String? phone;
  bool isVet;
  int isVetApproved; // 0: en attente, 1: approuvé, 2: refusé
  bool isAdmin;
  String? diplomaPath;

  Owner({
    this.id,
    required this.username,
    required this.password,
    required this.name,
    this.photoPath,
    this.email,
    this.phone,
    this.isVet = false,
    this.isVetApproved = 0, // Statut de validation par défaut
    this.isAdmin = false,
    this.diplomaPath,
  });

  // Conversion de l'objet en Map pour la base de données.
  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password': password,
    'name': name,
    'photoPath': photoPath,
    'email': email,
    'phone': phone,
    'isVet': isVet ? 1 : 0,
    'isVetApproved': isVetApproved,
    'isAdmin': isAdmin ? 1 : 0,
    'diplomaPath': diplomaPath,
  };

  // Création d'un objet à partir d'une Map venant de la base de données.
  factory Owner.fromMap(Map<String, dynamic> m) => Owner(
    id: m['id'] as int?,
    username: m['username'] as String,
    password: m['password'] as String,
    name: m['name'] as String,
    photoPath: m['photoPath'] as String?,
    email: m['email'] as String?,
    phone: m['phone'] as String?,
    isVet: (m['isVet'] ?? 0) == 1,
    isVetApproved: m['isVetApproved'] as int? ?? 0,
    isAdmin: (m['isAdmin'] ?? 0) == 1,
    diplomaPath: m['diplomaPath'] as String?,
  );

  Owner copyWith({
    int? id,
    String? username,
    String? password,
    String? name,
    String? photoPath,
    String? email,
    String? phone,
    bool? isVet,
    int? isVetApproved,
    bool? isAdmin,
    String? diplomaPath,
  }) {
    return Owner(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVet: isVet ?? this.isVet,
      isVetApproved: isVetApproved ?? this.isVetApproved,
      isAdmin: isAdmin ?? this.isAdmin,
      diplomaPath: diplomaPath ?? this.diplomaPath,
    );
  }
}
