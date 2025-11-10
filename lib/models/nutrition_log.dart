/// Modèle de données pour un enregistrement nutritionnel.
class NutritionLog {
  int? id;
  int petId;
  String foodType;
  double quantity;
  String unit;
  DateTime logDate;

  NutritionLog({
    this.id,
    required this.petId,
    required this.foodType,
    required this.quantity,
    required this.unit,
    required this.logDate,
  });

  /// Conversion de l'objet en Map pour la base de données.
  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'foodType': foodType,
        'quantity': quantity,
        'unit': unit,
        'logDate': logDate.toIso8601String(), // Stockage de la date en format ISO 8601
      };

  /// Création d'un objet à partir d'une Map venant de la base de données.
  factory NutritionLog.fromMap(Map<String, dynamic> map) {
    var dateValue = map['logDate'];
    DateTime date;

    if (dateValue is String) {
      date = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      date = DateTime.now();
    }

    return NutritionLog(
      id: map['id'] as int?,
      petId: map['petId'] as int,
      foodType: map['foodType'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      logDate: date,
    );
  }
}
