class FoodEntry {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime eatenAt;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.eatenAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'eatenAt': eatenAt.toIso8601String(),
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        eatenAt: DateTime.parse(json['eatenAt'] as String),
      );
}

/// Bir güne ait toplam besin değerleri.
class Totals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const Totals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  Totals operator +(FoodEntry e) => Totals(
        calories: calories + e.calories,
        protein: protein + e.protein,
        carbs: carbs + e.carbs,
        fat: fat + e.fat,
      );
}

/// Grafik için günlük özet.
class DailySummary {
  final DateTime day;
  final Totals totals;
  final double target;
  final bool hasEntries;

  const DailySummary({
    required this.day,
    required this.totals,
    required this.target,
    required this.hasEntries,
  });

  /// Pozitif = kalori fazlası, negatif = kalori açığı.
  double get balance => totals.calories - target;
}
