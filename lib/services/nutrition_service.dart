import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // yyyy-MM-dd formatında bugünün anahtarını üret
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, double>> getTodayTotals() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'calories': 0,
        'protein': 0,
        'carb': 0,
        'fat': 0,
      };
    }

    final dateKey = _todayKey();

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('nutrition')
        .doc(dateKey)
        .collection('items')
        .get();

    double totalCal = 0;
    double totalProtein = 0;
    double totalCarb = 0;
    double totalFat = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      totalCal += (data['calories'] ?? 0).toDouble();
      totalProtein += (data['protein'] ?? 0).toDouble();
      totalCarb += (data['carb'] ?? 0).toDouble();
      totalFat += (data['fat'] ?? 0).toDouble();
    }

    return {
      'calories': totalCal,
      'protein': totalProtein,
      'carb': totalCarb,
      'fat': totalFat,
    };
  }
}
