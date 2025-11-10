class Vaccine {
  final int? id;
  final int petId;
  final String name;
  final DateTime date;
  final DateTime? nextBooster;

  Vaccine({
    this.id,
    required this.petId,
    required this.name,
    required this.date,
    this.nextBooster,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'petId': petId,
    'name': name,
    'date': date.toIso8601String(),
    'nextBooster': nextBooster?.toIso8601String(),
  };

  factory Vaccine.fromMap(Map<String, dynamic> m) => Vaccine(
    id: m['id'] as int?,
    petId: m['petId'] as int,
    name: m['name'] as String,
    date: DateTime.parse(m['date'] as String),
    nextBooster: m['nextBooster'] != null ? DateTime.parse(m['nextBooster'] as String) : null,
  );
}
