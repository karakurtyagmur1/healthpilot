import 'dart:math';
import 'package:healthpilot/features/profile/models/profile_enums.dart';

class MacroPlan {
  final double bmr; // kcal/day
  final double tdee; // kcal/day
  final double targetCalories; // kcal/day

  final double proteinG; // g/day
  final double carbG; // g/day
  final double fatG; // g/day

  /// targetCalories - tdee (negatif=açık, pozitif=fazla)
  final double dailyDeltaUsed;

  /// lose / maintain / gain
  final String mode;

  /// Hedeflenen haftalık kilo değişimi (kg/week) (negatif=verme)
  final double weeklyDeltaKg;

  const MacroPlan({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.dailyDeltaUsed,
    required this.mode,
    required this.weeklyDeltaKg,
  });

  Map<String, dynamic> toMap() => {
        'bmr': bmr,
        'tdee': tdee,
        'targetCalories': targetCalories,
        'proteinG': proteinG,
        'carbG': carbG,
        'fatG': fatG,
        'dailyDeltaUsed': dailyDeltaUsed,
        'weeklyDeltaKg': weeklyDeltaKg,
        'mode': mode,
      };
}

class MacroCalculator {
  // --- public API ---
  static MacroPlan buildPlan({
    required int age,
    required double heightCm,
    required double weightKg,
    required Gender gender,
    required ActivityLevel activity,
    required double targetWeightKg,
    required int targetWeeks,
  }) {
    final weeks = max(1, targetWeeks);
    final w = weightKg;
    final h = heightCm;
    final a = age;

    // 1) BMR (Mifflin–St Jeor)
    final bmr = (gender == Gender.female)
        ? (10 * w + 6.25 * h - 5 * a - 161)
        : (10 * w + 6.25 * h - 5 * a + 5);

    // 2) TDEE
    final tdee = bmr * _activityFactor(activity);

    // 3) Mode (goal direction)
    final rawDeltaKg = targetWeightKg - weightKg;
    final String mode = _detectMode(rawDeltaKg);

    // 4) Weekly delta (kg/week) + safety clamp
    //    Lose: max ~%1 BW/week, Gain: max ~%0.5 BW/week
    final weeklyDeltaKg = _safeWeeklyDelta(
      rawDeltaKg: rawDeltaKg,
      weeks: weeks,
      currentWeightKg: weightKg,
      mode: mode,
    );

    // 5) Desired daily kcal delta from weight change (approx)
    //    1 kg ~ 7700 kcal
    final desiredDailyDelta = (weeklyDeltaKg * 7700.0) / 7.0; // kcal/day

    // 6) Calories target with clamps
    double targetCalories = _applyCalorieClamps(
      tdee: tdee,
      desiredDailyDelta: desiredDailyDelta,
      gender: gender,
      mode: mode,
    );

    // 7) Macros
    final refKg = _referenceKg(
      mode: mode,
      currentKg: weightKg,
      targetKg: targetWeightKg,
    );

    final macros = _buildMacros(
      mode: mode,
      refKg: refKg,
      targetCalories: targetCalories,
    );

    // macros adjust might raise calories in rare case; keep consistency
    targetCalories = macros.adjustedCalories;

    // 8) Daily delta used must match FINAL calories
    final dailyDeltaUsed = targetCalories - tdee;

    return MacroPlan(
      bmr: _round1(bmr),
      tdee: _round1(tdee),
      targetCalories: _round1(targetCalories),
      proteinG: _round1(macros.proteinG),
      carbG: _round1(macros.carbG),
      fatG: _round1(macros.fatG),
      dailyDeltaUsed: _round1(dailyDeltaUsed),
      weeklyDeltaKg: _round2(weeklyDeltaKg),
      mode: mode,
    );
  }

  // --- internals ---

  static double _activityFactor(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.high:
        return 1.725;
    }
  }

  static String _detectMode(double deltaKg) {
    if (deltaKg.abs() < 0.1) return 'maintain';
    return deltaKg < 0 ? 'lose' : 'gain';
  }

  static double _safeWeeklyDelta({
    required double rawDeltaKg,
    required int weeks,
    required double currentWeightKg,
    required String mode,
  }) {
    if (mode == 'maintain') return 0;

    final computed = rawDeltaKg / weeks; // kg/week
    if (mode == 'lose') {
      // negative
      final maxLoss = 0.01 * currentWeightKg; // 1% BW / week
      final minLoss = 0.25; // kg/week (çok düşük hedefleri de anlamlı yap)
      final loss = _clamp(computed.abs(), minLoss, maxLoss);
      return -loss;
    } else {
      // gain (positive)
      final maxGain = 0.005 * currentWeightKg; // 0.5% BW / week
      final minGain = 0.15; // kg/week
      final gain = _clamp(computed, minGain, maxGain);
      return gain;
    }
  }

  static double _applyCalorieClamps({
    required double tdee,
    required double desiredDailyDelta,
    required Gender gender,
    required String mode,
  }) {
    double target = tdee;

    if (mode == 'lose') {
      final desiredDeficit = desiredDailyDelta.abs(); // positive
      final maxDeficit = 0.25 * tdee; // %25 TDEE
      final deficit = _clamp(desiredDeficit, 300, maxDeficit);
      target = tdee - deficit;

      final minCalories = (gender == Gender.female) ? 1200.0 : 1500.0;
      target = max(target, minCalories);
    } else if (mode == 'gain') {
      final desiredSurplus = desiredDailyDelta; // positive
      final maxSurplus = 0.15 * tdee; // %15 TDEE
      final surplus = _clamp(desiredSurplus, 150, maxSurplus);
      target = tdee + surplus;
    } else {
      target = tdee;
    }

    return target;
  }

  static double _referenceKg({
    required String mode,
    required double currentKg,
    required double targetKg,
  }) {
    // Lose: hedef kiloya yakın referans daha mantıklı
    // Gain: mevcut kilo üzerinden (kilo artışı kademeli)
    if (mode == 'lose') return max(1, targetKg);
    if (mode == 'gain') return max(1, currentKg);
    // maintain: ortalama
    return max(1, (currentKg + targetKg) / 2.0);
  }

  static _MacroBuildResult _buildMacros({
    required String mode,
    required double refKg,
    required double targetCalories,
  }) {
    // Protein (g/kg)
    final proteinPerKg = (mode == 'lose') ? 2.0 : 1.7;
    double proteinG = proteinPerKg * refKg;

    // Fat (g/kg) + min fat
    final minFatG = 0.6 * refKg;
    double fatG = max(0.8 * refKg, minFatG);

    final proteinKcal = proteinG * 4.0;
    final fatKcal = fatG * 9.0;

    // Carb minimum (mode bazlı)
    final minCarbG = (mode == 'gain') ? 100.0 : 50.0;

    double carbKcal = targetCalories - (proteinKcal + fatKcal);

    // Eğer carb çok düşerse:
    if (carbKcal < minCarbG * 4.0) {
      // 1) carb'ı minimuma sabitle
      carbKcal = minCarbG * 4.0;

      // 2) yağı minimuma çek (hala yetmiyorsa)
      fatG = minFatG;
      final fatKcalMin = fatG * 9.0;

      final neededCalories = proteinKcal + fatKcalMin + carbKcal;
      if (neededCalories > targetCalories) {
        // Çok nadir ama tutarlı: hedef kalori düşük kaldıysa yükselt
        targetCalories = neededCalories;
      }
    }

    final carbG = carbKcal / 4.0;

    return _MacroBuildResult(
      proteinG: proteinG,
      fatG: fatG,
      carbG: carbG,
      adjustedCalories: targetCalories,
    );
  }

  static double _clamp(double v, double minV, double maxV) =>
      max(minV, min(maxV, v));

  static double _round1(double v) => (v * 10).roundToDouble() / 10.0;
  static double _round2(double v) => (v * 100).roundToDouble() / 100.0;
}

class _MacroBuildResult {
  final double proteinG;
  final double carbG;
  final double fatG;
  final double adjustedCalories;

  const _MacroBuildResult({
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.adjustedCalories,
  });
}
