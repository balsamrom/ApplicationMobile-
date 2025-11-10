import 'package:pet_owner_app/models/pet.dart';
import 'package:pet_owner_app/models/nutrition_log.dart';
import 'package:pet_owner_app/models/activity_log.dart';

class HealthAnalyzer {
  // Estimations des calories par gramme ou par minute
  static const Map<String, double> _caloriesPerGram = {
    'Croquettes': 3.5,
    'Pâtée': 1.5,
    'Nourriture humide': 1.0,
    'Friandises': 4.0,
    'Restes de table': 2.5,
    'Autre': 2.0, // Moyenne
  };

  static const Map<String, double> _caloriesBurnedPerMinute = {
    'Promenade': 5.0,
    'Jeu': 8.0,
    'Course': 12.0,
    'Entraînement': 10.0,
    'Sieste': 1.0,
    'Autre': 6.0, // Moyenne
  };

  // Calcule le total des calories ingérées pour une liste de logs
  static double calculateCaloriesIn(List<NutritionLog> logs) {
    return logs.fold(0.0, (total, log) {
      final calories = _caloriesPerGram[log.foodType] ?? 2.0;
      return total + (log.quantity * calories);
    });
  }

  // Calcule le total des calories dépensées pour une liste de logs
  static double calculateCaloriesOut(List<ActivityLog> logs, double petWeight) {
    return logs.fold(0.0, (total, log) {
      final calories = _caloriesBurnedPerMinute[log.activityType] ?? 6.0;
      // Le poids est un facteur multiplicateur (simplifié)
      return total + (log.durationInMinutes * calories * (petWeight / 10));
    });
  }

  // Analyse la routine d'un animal et retourne une liste de messages d'anomalie
  static List<String> analyzePetRoutine(Pet pet, List<NutritionLog> nutritionLogs, List<ActivityLog> activityLogs) {
    int surplusDays = 0;
    int deficitDays = 0;
    int daysWithData = 0;

    // Analyse des 3 derniers jours
    for (int i = 0; i < 3; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dailyNutrition = nutritionLogs.where((log) => log.logDate.day == date.day).toList();
      final dailyActivity = activityLogs.where((log) => (log.logDate as DateTime).day == date.day).toList();

      if (dailyNutrition.isNotEmpty || dailyActivity.isNotEmpty) {
        daysWithData++;
        final caloriesIn = calculateCaloriesIn(dailyNutrition);
        final caloriesOut = calculateCaloriesOut(dailyActivity, pet.weight ?? 10.0);
        final balance = caloriesIn - caloriesOut;

        // On ne considère qu'un déséquilibre significatif (plus de 30%)
        if (caloriesIn > 0 && balance > (caloriesIn * 0.3)) {
          surplusDays++;
        } else if (caloriesIn > 0 && balance < -(caloriesIn * 0.3)) {
          deficitDays++;
        }
      }
    }

    if (daysWithData < 2) {
      return ['Enregistrez des repas et activités sur au moins 2 jours pour obtenir une analyse.'];
    }
    if (surplusDays >= 2) {
      return ['Tendance au surplus calorique.'];
    }
    if (deficitDays >= 2) {
      return ['Tendance au déficit calorique.'];
    }

    return []; // Retourne une liste vide si la routine est saine
  }
}
