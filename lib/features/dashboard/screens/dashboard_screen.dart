// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:healthpilot/services/firestore_service.dart';
import 'package:healthpilot/features/food/widgets/add_food_bottom_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Güvenlik: Kullanıcı yoksa Login'e döndür.
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = user.uid;
    final fs = FirestoreService();

    // Basit hedefler (profilden almadığımız senaryoda placeholder)
    const targets = _Targets(
      calories: 2000,
      protein: 120,
      carb: 240,
      fat: 60,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthPilot'),
        actions: [
          IconButton(
            tooltip: 'Asistan',
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            icon: const Icon(Icons.smart_toy_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---- Gün Özeti (Toplamlar + İlerleme Çubukları) ----
            StreamBuilder<Map<String, num>>(
              stream: fs.streamTodaySummary(userId),
              builder: (context, snap) {
                final totals = snap.data ??
                    const {'calories': 0, 'protein': 0, 'carb': 0, 'fat': 0};
                return _SummaryCard(
                  calories: (totals['calories'] ?? 0).toInt(),
                  protein: (totals['protein'] ?? 0).toInt(),
                  carb: (totals['carb'] ?? 0).toInt(),
                  fat: (totals['fat'] ?? 0).toInt(),
                  targets: targets,
                );
              },
            ),
            const SizedBox(height: 16),

            // ---- Öğün Kartları ----
            _MealSection(
              title: 'Kahvaltı',
              mealType: 'breakfast',
              userId: userId,
              service: fs,
            ),
            const SizedBox(height: 12),
            _MealSection(
              title: 'Öğle Yemeği',
              mealType: 'lunch',
              userId: userId,
              service: fs,
            ),
            const SizedBox(height: 12),
            _MealSection(
              title: 'Akşam Yemeği',
              mealType: 'dinner',
              userId: userId,
              service: fs,
            ),
            const SizedBox(height: 12),
            _MealSection(
              title: 'Ara Öğün',
              mealType: 'snack',
              userId: userId,
              service: fs,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Özet Kartı --------------------------- */

class _Targets {
  final int calories;
  final int protein;
  final int carb;
  final int fat;
  const _Targets({
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}

class _SummaryCard extends StatelessWidget {
  final int calories;
  final int protein;
  final int carb;
  final int fat;
  final _Targets targets;

  const _SummaryCard({
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gün Özeti', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _progressRow(
              label: 'Kalori',
              value: calories,
              target: targets.calories,
              color: Colors.orange,
            ),
            const SizedBox(height: 10),
            _progressRow(
              label: 'Protein',
              value: protein,
              target: targets.protein,
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            _progressRow(
              label: 'Karbonhidrat',
              value: carb,
              target: targets.carb,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            _progressRow(
              label: 'Yağ',
              value: fat,
              target: targets.fat,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressRow({
    required String label,
    required int value,
    required int target,
    required Color color,
  }) {
    final ratio = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value / $target'),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio.toDouble(),
          minHeight: 8,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

/* --------------------------- Öğün Bölümü --------------------------- */

class _MealSection extends StatelessWidget {
  final String title;
  final String mealType; // breakfast | lunch | dinner | snack
  final String userId;
  final FirestoreService service;

  const _MealSection({
    required this.title,
    required this.mealType,
    required this.userId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Başlık ve Ekle
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => AddFoodBottomSheet(
                        userId: userId,
                        mealType: mealType, // <— önemlidir
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 8),

            // Liste: Tüm gün kayıtlarını al, ekranda mealType’a göre filtrele
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.streamFoodsAll(userId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Liste hatası: ${snap.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allDocs = snap.data?.docs ?? [];
                final docs = allDocs.where((d) {
                  final data = d.data();
                  final mt =
                      (data['mealType'] ?? '').toString().toLowerCase().trim();
                  return mt == mealType.toLowerCase();
                }).toList();

                // createdAt'e göre (yeni → eski) istemci tarafı sıralama
                docs.sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  final da = (ta is Timestamp)
                      ? ta.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);
                  final db = (tb is Timestamp)
                      ? tb.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);
                  return db.compareTo(da);
                });

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Henüz öğe girmediniz',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final m = d.data();
                    final name = (m['name'] ?? '') as String;
                    final grams = (m['grams'] ?? 0) as int;
                    final kcal = (m['calories'] ?? 0) as int;
                    final p = (m['protein'] ?? 0) as int;
                    final c = (m['carb'] ?? 0) as int;
                    final f = (m['fat'] ?? 0) as int;

                    return Dismissible(
                      key: ValueKey(d.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        color: Colors.red.withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                      onDismissed: (_) async {
                        await service.deleteFoodItem(
                            userId: userId, docId: d.id);
                      },
                      child: ListTile(
                        title: Text('$name • ${grams}g'),
                        subtitle: Text('$kcal kcal • P:$p K:$c Y:$f'),
                        trailing: IconButton(
                          tooltip: 'Sil',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await service.deleteFoodItem(
                                userId: userId, docId: d.id);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
