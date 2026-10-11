import 'package:flutter_test/flutter_test.dart';
import 'package:kalori_takip/models/food_entry.dart';
import 'package:kalori_takip/models/user_profile.dart';
import 'package:kalori_takip/services/nutrition_calculator.dart';

void main() {
  test('Mifflin-St Jeor erkek, orta aktivite', () {
    const p = UserProfile(
      heightCm: 180,
      weightKg: 80,
      age: 30,
      gender: Gender.male,
      activity: ActivityLevel.moderate,
    );
    final t = NutritionCalculator.calculate(p);
    // 10*80 + 6.25*180 - 5*30 + 5 = 1780
    expect(t.bmr, closeTo(1780, 0.01));
    expect(t.calories, closeTo(1780 * 1.55, 0.01));
    expect(t.protein, closeTo(128, 0.01));
    // Makrolar toplam kaloriye eşit olmalı
    final sum = t.protein * 4 + t.carbs * 4 + t.fat * 9;
    expect(sum, closeTo(t.calories, 0.01));
  });

  test('Mifflin-St Jeor kadın', () {
    const p = UserProfile(
      heightCm: 165,
      weightKg: 60,
      age: 25,
      gender: Gender.female,
      activity: ActivityLevel.sedentary,
    );
    final t = NutritionCalculator.calculate(p);
    // 600 + 1031.25 - 125 - 161 = 1345.25
    expect(t.bmr, closeTo(1345.25, 0.01));
    expect(t.calories, closeTo(1345.25 * 1.2, 0.01));
  });

  test('Kalori dengesi: fazla pozitif, açık negatif', () {
    final day = DateTime(2026, 1, 1);
    const totals = Totals(calories: 2500);
    expect(
      DailySummary(day: day, totals: totals, target: 2000, hasEntries: true)
          .balance,
      500,
    );
    expect(
      DailySummary(day: day, totals: totals, target: 3000, hasEntries: true)
          .balance,
      -500,
    );
  });

  test('JSON gidiş-dönüş', () {
    const p = UserProfile(
      heightCm: 170.5,
      weightKg: 70,
      age: 40,
      gender: Gender.female,
      activity: ActivityLevel.active,
    );
    final back = UserProfile.fromJson(p.toJson());
    expect(back.heightCm, 170.5);
    expect(back.activity, ActivityLevel.active);
    expect(back.gender, Gender.female);
  });
}
