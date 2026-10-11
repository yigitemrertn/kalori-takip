import 'dart:math';

import '../models/user_profile.dart';

class NutritionTargets {
  final double bmr;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionTargets({
    required this.bmr,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

/// Kilo koruma hedeflerini hesaplar.
///
/// - BMR: Mifflin-St Jeor formülü
/// - Kalori (TDEE): BMR x aktivite çarpanı
/// - Protein: 1.6 g / kg vücut ağırlığı
/// - Yağ: kalorinin %25'i
/// - Karbonhidrat: kalan kalori
class NutritionCalculator {
  static const proteinPerKg = 1.6;
  static const fatRatio = 0.25;

  static NutritionTargets calculate(UserProfile p) {
    final genderOffset = p.gender == Gender.male ? 5 : -161;
    final bmr =
        10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + genderOffset;
    final tdee = bmr * p.activity.factor;

    final protein = p.weightKg * proteinPerKg;
    final fat = tdee * fatRatio / 9;
    final carbs = max(0.0, (tdee - protein * 4 - fat * 9) / 4);

    return NutritionTargets(
      bmr: bmr,
      calories: tdee,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Makrolardan kalori tahmini (4/4/9 kuralı).
  static double caloriesFromMacros(double protein, double carbs, double fat) =>
      protein * 4 + carbs * 4 + fat * 9;
}
