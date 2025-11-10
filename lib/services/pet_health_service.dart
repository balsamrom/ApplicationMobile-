import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/services/health_analyzer.dart';

class PetHealthService {
  static Future<List<Pet>> getPetsWithAnalysis(int ownerId) async {
    final db = DatabaseHelper.instance;

    final pets = await db.getPetsByOwner(ownerId);
    if (pets.isEmpty) return [];

    final nutritionLogs = await db.getAllNutritionLogs();
    final activityLogs = await db.getAllActivityLogs();

    final analyzedPets = <Pet>[];

    for (final pet in pets) {
      final petNutrition = nutritionLogs.where((log) => log.petId == pet.id).toList();
      final petActivity = activityLogs.where((log) => log.petId == pet.id).toList();

      // Correction: On s'assure que la variable est bien une List<String>
      final List<String> analysis = HealthAnalyzer.analyzePetRoutine(pet, petNutrition, petActivity);

      analyzedPets.add(pet.copyWith(analysis: analysis));
    }

    return analyzedPets;
  }
}
