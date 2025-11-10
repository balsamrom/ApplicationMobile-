class Alert {
  final int? id;
  final int ownerId;
  final int petId;
  final String emergencyTitle;
  final DateTime timestamp;

  Alert({
    this.id,
    required this.ownerId,
    required this.petId,
    required this.emergencyTitle,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'petId': petId,
      'emergencyTitle': emergencyTitle,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static Alert fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      ownerId: map['ownerId'],
      petId: map['petId'],
      emergencyTitle: map['emergencyTitle'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
