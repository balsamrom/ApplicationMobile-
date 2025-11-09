class Owner {
  int? id;
  String username;
  String password;
  String name;
  String? photoPath;
  String? email;
  String? phone;
  bool isVet;
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
    this.diplomaPath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password': password,
    'name': name,
    'photoPath': photoPath,
    'email': email,
    'phone': phone,
    'isVet': isVet ? 1 : 0,
    'diplomaPath': diplomaPath,
  };

  factory Owner.fromMap(Map<String, dynamic> m) => Owner(
    id: m['id'] as int?,
    username: m['username'] as String,
    password: m['password'] as String,
    name: m['name'] as String,
    photoPath: m['photoPath'] as String?,
    email: m['email'] as String?,
    phone: m['phone'] as String?,
    isVet: (m['isVet'] ?? 0) == 1,
    diplomaPath: m['diplomaPath'] as String?,
  );
}