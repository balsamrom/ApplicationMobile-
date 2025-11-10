import 'package:pet_owner_app/models/alert.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/models/pet.dart';

class AlertDetails {
  final Alert alert;
  final Owner owner;
  final Pet pet;

  AlertDetails({required this.alert, required this.owner, required this.pet});
}
