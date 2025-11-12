// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  /// Kullanıcı profilini kaydet / güncelle
  /// Doc: users/{uid}/profile
  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu yok.');
    }
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('profile')
        .set(data, SetOptions(merge: true));
  }

  /// Günlük öğün kaydı ekle
  /// Doc: users/{uid}/foods/{autoId}
  Future<void> addFoodItem({
    required String userId,
    required String mealType, // breakfast | lunch | dinner | snack
    required String name,
    required int grams,
    required int calories,
    required int protein,
    required int carb,
    required int fat,
  }) async {
    final now = DateTime.now();
    final ymd = DateTime(now.year, now.month, now.day); // güne göre ayrım için
    await _db.collection('users').doc(userId).collection('foods').add({
      'mealType': mealType,
      'name': name,
      'grams': grams,
      'calories': calories,
      'protein': protein,
      'carb': carb,
      'fat': fat,
      'createdAt': FieldValue.serverTimestamp(),
      'dayKey': Timestamp.fromDate(ymd), // aynı gün filtrelemek için
    });
  }

  /// Günlük öğün kaydı sil
  Future<void> deleteFoodItem({
    required String userId,
    required String docId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(docId)
        .delete();
  }

  /// Bugünün TÜM kayıtlarını stream eder (öğün kartlarında ekranda filtreleniyor)
  /// Stream<QuerySnapshot> döner ki ListView ile sorunsuz kullanılabilsin.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamFoodsAll(String userId) {
    final now = DateTime.now();
    final ymd = DateTime(now.year, now.month, now.day);
    return _db
        .collection('users')
        .doc(userId)
        .collection('foods')
        .where('dayKey', isEqualTo: Timestamp.fromDate(ymd))
        .snapshots();
  }

  /// Bugünün toplamlarını hesaplar (kalori/protein/karb/yağ)
  Stream<Map<String, num>> streamTodaySummary(String userId) {
    final now = DateTime.now();
    final ymd = DateTime(now.year, now.month, now.day);
    return _db
        .collection('users')
        .doc(userId)
        .collection('foods')
        .where('dayKey', isEqualTo: Timestamp.fromDate(ymd))
        .snapshots()
        .map((qs) {
      int calories = 0;
      int protein = 0;
      int carb = 0;
      int fat = 0;
      for (final d in qs.docs) {
        final m = d.data();
        calories += (m['calories'] ?? 0) as int;
        protein += (m['protein'] ?? 0) as int;
        carb += (m['carb'] ?? 0) as int;
        fat += (m['fat'] ?? 0) as int;
      }
      return {
        'calories': calories,
        'protein': protein,
        'carb': carb,
        'fat': fat,
      };
    });
  }
}
