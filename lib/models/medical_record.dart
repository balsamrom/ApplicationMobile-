class MedicalRecord {
  final int? id;
  final int petId;
  final DateTime date;
  final String type; // 'vaccination', 'consultation', 'surgery', 'treatment'
  final String description;
  final String veterinarian;
  final String? prescription;
  final DateTime? nextVisit;

  MedicalRecord({
    this.id,
    required this.petId,
    required this.date,
    required this.type,
    required this.description,
    required this.veterinarian,
    this.prescription,
    this.nextVisit,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'petId': petId,
    'date': date.toIso8601String(),
    'type': type,
    'description': description,
    'veterinarian': veterinarian,
    'prescription': prescription,
    'nextVisit': nextVisit?.toIso8601String(),
  };

  factory MedicalRecord.fromMap(Map<String, dynamic> m) => MedicalRecord(
    id: m['id'] as int?,
    petId: m['petId'] as int,
    date: DateTime.parse(m['date'] as String),
    type: m['type'] as String,
    description: m['description'] as String,
    veterinarian: m['veterinarian'] as String,
    prescription: m['prescription'] as String?,
    nextVisit: m['nextVisit'] != null ? DateTime.parse(m['nextVisit'] as String) : null,
  );
}