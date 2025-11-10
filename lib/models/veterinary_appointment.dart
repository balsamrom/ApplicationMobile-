class VeterinaryAppointment {
  final int? id;
  final int veterinaryId;
  final String veterinaryName;
  final int petId;
  final String petName;
  final DateTime dateTime;
  final String reason;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? notes;
  final String? treatments;
  final DateTime createdAt;

  VeterinaryAppointment({
    this.id,
    required this.veterinaryId,
    required this.veterinaryName,
    required this.petId,
    required this.petName,
    required this.dateTime,
    required this.reason,
    required this.status,
    this.notes,
    this.treatments,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'veterinaryId': veterinaryId,
    'veterinaryName': veterinaryName,
    'petId': petId,
    'petName': petName,
    'dateTime': dateTime.toIso8601String(),
    'reason': reason,
    'status': status,
    'notes': notes,
    'treatments': treatments,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VeterinaryAppointment.fromMap(Map<String, dynamic> m) => VeterinaryAppointment(
    id: m['id'] as int?,
    veterinaryId: m['veterinaryId'] as int,
    veterinaryName: m['veterinaryName'] as String,
    petId: m['petId'] as int,
    petName: m['petName'] as String,
    dateTime: DateTime.parse(m['dateTime'] as String),
    reason: m['reason'] as String,
    status: m['status'] as String,
    notes: m['notes'] as String?,
    treatments: m['treatments'] as String?,
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}
