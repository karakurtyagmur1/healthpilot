import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Bugünün anahtarı: 2025-11-20 gibi
  String _todayKey() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// PROFİL KAYDETME (profil ekranında kullanılıyor)
  Future<void> saveUserProfile(String userId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('main')
        .set(data, SetOptions(merge: true));
  }

  /// BUGÜN İÇİN BESİN EKLE
  Future<void> addFoodEntry({
    required String userId,
    required String mealType, // breakfast, lunch, dinner, snack
    required String name,
    required double grams,
    required double kcal,
    required double protein,
    required double carb,
    required double fat,
  }) async {
    final today = _todayKey();

    await _db.collection('users').doc(userId).collection('food_entries').add({
      'date': today,
      'mealType': mealType,
      'name': name,
      'grams': grams,
      'kcal': kcal,
      'protein': protein,
      'carb': carb,
      'fat': fat,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// BUGÜN TÜM ÖĞÜNLERDEKİ BESİNLER (üstteki toplam makrolar için)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllFoods(String userId) {
    final today = _todayKey();
    return _db
        .collection('users')
        .doc(userId)
        .collection('food_entries')
        .where('date', isEqualTo: today)
        .snapshots();
  }

  /// BUGÜN SEÇİLEN ÖĞÜNDEKİ BESİNLER (kahvaltı / öğle vs. listesi için)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamFoodsByMeal(
    String userId,
    String mealType,
  ) {
    final today = _todayKey();
    return _db
        .collection('users')
        .doc(userId)
        .collection('food_entries')
        .where('date', isEqualTo: today)
        .where('mealType', isEqualTo: mealType)
        .snapshots();
  }

  /// TEK BESİN SİLME (çöp ikonuna basınca)
  Future<void> deleteFood({
    required String userId,
    required String docId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('food_entries')
        .doc(docId)
        .delete();
  }
}
