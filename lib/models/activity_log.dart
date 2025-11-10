/// Modèle de données pour un enregistrement d'activité physique.
class ActivityLog {
  int? id;
  int petId;
  String activityType;
  int durationInMinutes;
  String? notes;
  dynamic logDate; // Peut être une String ou une DateTime

  ActivityLog({
    this.id,
    required this.petId,
    required this.activityType,
    required this.durationInMinutes,
    this.notes,
    required this.logDate,
  });

  // Conversion de l'objet en Map pour l'insertion dans la base de données.
  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'activityType': activityType,
        'durationInMinutes': durationInMinutes,
        'notes': notes,
        'logDate': (logDate is DateTime) ? (logDate as DateTime).toIso8601String() : logDate,
      };

  // Création d'un objet à partir d'une Map venant de la base de données.
  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    var dateValue = map['logDate'];
    DateTime date;

    if (dateValue is String) {
      date = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      date = DateTime.now();
    }

    return ActivityLog(
      id: map['id'] as int?,
      petId: map['petId'] as int,
      activityType: map['activityType'] as String,
      durationInMinutes: (map['durationInMinutes'] as num).toInt(),
      notes: map['notes'] as String?,
      logDate: date,
    );
  }
}
