import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ----------------------------
  // Utils
  // ----------------------------
  String dateKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  DocumentReference<Map<String, dynamic>> _profileDoc(String userId) =>
      _db.collection('users').doc(userId).collection('profile').doc('main');

  CollectionReference<Map<String, dynamic>> _foodCol(String userId) =>
      _db.collection('users').doc(userId).collection('food_entries');

  // ----------------------------
  // PROFILE
  // ----------------------------
  Future<void> saveUserProfile(
    String userId,
    Map<String, dynamic> profileData, {
    Map<String, dynamic>? macroPlan,
  }) async {
    final payload = <String, dynamic>{
      ...profileData,
      if (macroPlan != null) 'macroPlan': macroPlan,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _profileDoc(userId).set(payload, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _profileDoc(userId).get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _profileDoc(userId).snapshots().map((snap) => snap.data());
  }

  Future<Map<String, dynamic>?> getMacroPlan(String userId) async {
    final data = await getUserProfile(userId);
    return data?['macroPlan'] as Map<String, dynamic>?;
  }

  Stream<Map<String, dynamic>?> streamMacroPlan(String userId) {
    return _profileDoc(userId)
        .snapshots()
        .map((snap) => (snap.data()?['macroPlan'] as Map<String, dynamic>?));
  }

  // ----------------------------
  // FOOD ENTRIES
  // ----------------------------
  Future<String> addFoodEntry({
    required String userId,
    required String dateKey,
    required String mealType,
    required String name,
    required double grams,
    required double kcal,
    required double protein,
    required double carb,
    required double fat,
  }) async {
    final doc = await _foodCol(userId).add({
      'date': dateKey,
      'mealType': mealType,
      'name': name.trim(),
      'grams': grams,
      'kcal': kcal,
      'protein': protein,
      'carb': carb,
      'fat': fat,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateFoodEntry({
    required String userId,
    required String docId,
    Map<String, dynamic>? patch,
  }) async {
    if (patch == null || patch.isEmpty) return;
    await _foodCol(userId).doc(docId).update({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFoodEntry({
    required String userId,
    required String docId,
  }) async {
    await _foodCol(userId).doc(docId).delete();
  }

  Future<List<Map<String, dynamic>>> fetchFoodsByDate({
    required String userId,
    required String dateKey,
  }) async {
    final snap = await _foodCol(userId).where('date', isEqualTo: dateKey).get();
    return snap.docs
        .map((d) => {
              ...d.data(),
              'id': d.id,
            })
        .toList(growable: false);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFoodsByDate(
    String userId, {
    required String dateKey,
  }) {
    return _foodCol(userId).where('date', isEqualTo: dateKey).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFoodsByMealAndDate(
    String userId,
    String mealType, {
    required String dateKey,
  }) {
    return _foodCol(userId)
        .where('date', isEqualTo: dateKey)
        .where('mealType', isEqualTo: mealType)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFoodsInDateRange(
    String userId, {
    required String startDateKey,
    required String endDateKey,
  }) {
    return _foodCol(userId)
        .where('date', isGreaterThanOrEqualTo: startDateKey)
        .where('date', isLessThanOrEqualTo: endDateKey)
        .snapshots();
  }

  // ----------------------------
  // BACKWARD COMPAT (ALIAS)
  // Dashboard/Chat eski çağrıları kırmasın
  // ----------------------------

  Future<void> deleteFood({
    required String userId,
    required String docId,
  }) =>
      deleteFoodEntry(userId: userId, docId: docId);

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllFoodsByDate(
    String userId, {
    required String dateKey,
  }) =>
      streamFoodsByDate(userId, dateKey: dateKey);

  Future<List<Map<String, dynamic>>> fetchAllFoodsByDate({
    required String userId,
    required String dateKey,
  }) =>
      fetchFoodsByDate(userId: userId, dateKey: dateKey);
}
