import './owner.dart';
import 'cabinet.dart';

class Veterinary {
  final Owner owner; 
  final Cabinet? cabinet;

  final String? specialty;
  final double? rating;
  final String? coverPhotoPath;

  String? get address => cabinet?.address;
  double? get latitude => cabinet?.latitude;
  double? get longitude => cabinet?.longitude;

  bool get hasLocation => latitude != null && longitude != null;

  Veterinary({
    required this.owner,
    this.specialty,
    this.rating,
    this.coverPhotoPath,
    this.cabinet,
  });

  factory Veterinary.fromMap(Map<String, dynamic> map, {Cabinet? cabinet}) {
    return Veterinary(
      owner: Owner.fromMap(map),
      specialty: map['specialty'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      coverPhotoPath: map['coverPhotoPath'] as String?,
      cabinet: cabinet,
    );
  }

  Veterinary copyWith({
    Owner? owner,
    Cabinet? cabinet,
    String? specialty,
    double? rating,
    String? coverPhotoPath,
  }) {
    return Veterinary(
      owner: owner ?? this.owner,
      cabinet: cabinet ?? this.cabinet,
      specialty: specialty ?? this.specialty,
      rating: rating ?? this.rating,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
    );
  }
}
