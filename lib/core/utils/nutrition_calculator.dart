class NutritionCalculator {
  // Mifflin-St Jeor
  static double calculateBmr({
    required double weight,
    required int height,
    required int age,
    required String gender, // 'male' | 'female'
  }) {
    if (gender == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  static Map<String, double> calculateDailyTargets({
    required double weight,
    required int height,
    required int age,
    required String gender,
    required String goalType, // lose, maintain, gain
  }) {
    final bmr = calculateBmr(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );

    // şimdilik sabit aktivite
    double tdee = bmr * 1.35;

    if (goalType == 'lose') {
      tdee -= 400;
    } else if (goalType == 'gain') {
      tdee += 300;
    }

    // makrolar
    final proteinGr = weight * 1.6; // kg x 1.6
    final fatKcal = tdee * 0.25;
    final fatGr = fatKcal / 9;
    final proteinKcal = proteinGr * 4;
    final remainingKcal = tdee - proteinKcal - fatKcal;
    final carbGr = remainingKcal / 4;

    return {
      'dailyCalories': tdee,
      'proteinGr': proteinGr,
      'fatGr': fatGr,
      'carbGr': carbGr,
    };
  }
}
