enum Gender {
  male('Erkek'),
  female('Kadın');

  const Gender(this.label);
  final String label;
}

/// Günlük aktivite seviyesi ve TDEE çarpanı.
enum ActivityLevel {
  sedentary(1.2, 'Hareketsiz', 'Masa başı iş, az ya da hiç egzersiz'),
  light(1.375, 'Az hareketli', 'Haftada 1-3 gün hafif egzersiz'),
  moderate(1.55, 'Orta hareketli', 'Haftada 3-5 gün orta egzersiz'),
  active(1.725, 'Çok hareketli', 'Haftada 6-7 gün yoğun egzersiz'),
  veryActive(1.9, 'Aşırı hareketli', 'Fiziksel iş + günlük yoğun antrenman');

  const ActivityLevel(this.factor, this.label, this.description);
  final double factor;
  final String label;
  final String description;
}

class UserProfile {
  final double heightCm;
  final double weightKg;
  final int age;
  final Gender gender;
  final ActivityLevel activity;

  const UserProfile({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.gender,
    required this.activity,
  });

  Map<String, dynamic> toJson() => {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'age': age,
        'gender': gender.name,
        'activity': activity.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        age: (json['age'] as num).toInt(),
        gender: Gender.values.byName(json['gender'] as String),
        activity: ActivityLevel.values.byName(json['activity'] as String),
      );
}
