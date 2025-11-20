import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthpilot/features/chat/screens/chat_screen.dart';
import 'package:healthpilot/features/food/widgets/add_food_bottom_sheet.dart';
import 'package:healthpilot/services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _fs = FirestoreService();
  String? _userId;

  // Hedef makrolar – profil formundan okuyoruz
  double _targetKcal = 2000;
  double _targetProtein = 120;
  double _targetCarb = 200;
  double _targetFat = 60;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _userId = user.uid;
    });

    // Profil hedeflerini oku
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('main')
        .get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        _targetKcal = (data['kcalTarget'] ?? _targetKcal).toDouble();
        _targetProtein = (data['proteinTarget'] ?? _targetProtein).toDouble();
        _targetCarb = (data['carbTarget'] ?? _targetCarb).toDouble();
        _targetFat = (data['fatTarget'] ?? _targetFat).toDouble();
        _profileLoaded = true;
      });
    } else {
      setState(() {
        _profileLoaded = true;
      });
    }
  }

  void _openAddFood(String mealType) {
    if (_userId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFoodBottomSheet(
        userId: _userId!,
        mealType: mealType,
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required double consumed,
    required double target,
    required Color color,
  }) {
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 8,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMealCard(String title, String mealType) {
    if (_userId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('$title için veri yok (kullanıcı bulunamadı)'),
        ),
      );
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık + Ekle butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openAddFood(mealType),
                  icon: const Icon(Icons.add),
                  label: const Text('Besin ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Liste
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _fs.streamFoodsByMeal(_userId!, mealType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Henüz öğe eklenmedi.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final name = data['name'] ?? '';
                    final grams = (data['grams'] ?? 0).toDouble();
                    final kcal = (data['kcal'] ?? 0).toDouble();
                    final protein = (data['protein'] ?? 0).toDouble();
                    final carb = (data['carb'] ?? 0).toDouble();
                    final fat = (data['fat'] ?? 0).toDouble();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name),
                      subtitle: Text(
                        '${grams.toStringAsFixed(0)} g • '
                        '${kcal.toStringAsFixed(0)} kcal • '
                        'P:${protein.toStringAsFixed(1)} '
                        'K:${carb.toStringAsFixed(1)} '
                        'Y:${fat.toStringAsFixed(1)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          await _fs.deleteFood(
                            userId: _userId!,
                            docId: doc.id,
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı yoksa
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthPilot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ],
      ),
      body: !_profileLoaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // KARŞILAMA + GÜNLÜK ÖZET
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bugün beslenme durumu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toplam makrolar – tüm öğeleri dinliyor
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _fs.streamAllFoods(_userId!),
                    builder: (context, snapshot) {
                      double totalKcal = 0;
                      double totalProtein = 0;
                      double totalCarb = 0;
                      double totalFat = 0;

                      if (snapshot.hasData) {
                        for (final doc in snapshot.data!.docs) {
                          final d = doc.data();
                          totalKcal += (d['kcal'] ?? 0).toDouble();
                          totalProtein += (d['protein'] ?? 0).toDouble();
                          totalCarb += (d['carb'] ?? 0).toDouble();
                          totalFat += (d['fat'] ?? 0).toDouble();
                        }
                      }

                      return Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              _buildMacroRow(
                                label: 'Kalori (kcal)',
                                consumed: totalKcal,
                                target: _targetKcal,
                                color: Colors.orange,
                              ),
                              _buildMacroRow(
                                label: 'Protein (g)',
                                consumed: totalProtein,
                                target: _targetProtein,
                                color: Colors.green,
                              ),
                              _buildMacroRow(
                                label: 'Karbonhidrat (g)',
                                consumed: totalCarb,
                                target: _targetCarb,
                                color: Colors.blue,
                              ),
                              _buildMacroRow(
                                label: 'Yağ (g)',
                                consumed: totalFat,
                                target: _targetFat,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // ÖĞÜNLER
                  Expanded(
                    child: ListView(
                      children: [
                        _buildMealCard('Kahvaltı', 'breakfast'),
                        _buildMealCard('Öğle Yemeği', 'lunch'),
                        _buildMealCard('Akşam Yemeği', 'dinner'),
                        _buildMealCard('Ara Öğün', 'snack'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
