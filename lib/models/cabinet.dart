class Cabinet {
  final int? id;
  final int veterinaryId;
  final String address;
  final double? latitude;
  final double? longitude;

  Cabinet({
    this.id,
    required this.veterinaryId,
    required this.address,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'veterinaryId': veterinaryId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Cabinet.fromMap(Map<String, dynamic> map) {
    return Cabinet(
      id: map['id'],
      veterinaryId: map['veterinaryId'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
