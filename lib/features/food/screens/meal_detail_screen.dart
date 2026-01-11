import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:healthpilot/services/firestore_service.dart';

class MealDetailScreen extends StatelessWidget {
  final String userId;
  final String mealType; // breakfast/lunch/dinner/snack
  final String dateKey; // yyyy-MM-dd

  const MealDetailScreen({
    super.key,
    required this.userId,
    required this.mealType,
    required this.dateKey,
  });

  String _mealTitle() {
    switch (mealType) {
      case 'breakfast':
        return 'Kahvaltı';
      case 'lunch':
        return 'Öğle Yemeği';
      case 'dinner':
        return 'Akşam Yemeği';
      case 'snack':
      default:
        return 'Atıştırmalık';
    }
  }

  IconData _mealIcon() {
    switch (mealType) {
      case 'breakfast':
        return Icons.coffee_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      case 'snack':
      default:
        return Icons.apple_outlined;
    }
  }

  Map<String, double> _sumDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    double kcal = 0, carb = 0, protein = 0, fat = 0;
    for (final d in docs) {
      final data = d.data();
      kcal += (data['kcal'] ?? 0).toDouble();
      carb += (data['carb'] ?? 0).toDouble();
      protein += (data['protein'] ?? 0).toDouble();
      fat += (data['fat'] ?? 0).toDouble();
    }
    return {'kcal': kcal, 'carb': carb, 'protein': protein, 'fat': fat};
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mealTitle()),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            onPressed: () {
              // Şimdilik boş. İstersen ileride "toplu düzenleme" açarız.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Düzenleme yakında.')),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.streamFoodsByMealAndDate(userId, mealType, dateKey: dateKey),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final sums = _sumDocs(docs);

          final kcal = sums['kcal']!;
          final carb = sums['carb']!;
          final protein = sums['protein']!;
          final fat = sums['fat']!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              // Üst görsel alan (senin örnekteki gibi)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Center(
                  child: Icon(
                    _mealIcon(),
                    size: 64,
                    color: cs.primary.withOpacity(0.85),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4’lü özet satırı (kcal / carb / protein / fat)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metric('Kalori', kcal, 'kcal'),
                    _metric('Karbonhidrat', carb, 'g'),
                    _metric('Protein', protein, 'g'),
                    _metric('Yağ', fat, 'g'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Liste
              Text(
                'Besinler',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),

              if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),

              if (docs.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        'Bu öğünde henüz besin yok.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

              ...docs.map((doc) {
                final d = doc.data();
                final name = (d['name'] ?? '').toString();
                final grams = (d['grams'] ?? 0).toDouble();
                final kcal = (d['kcal'] ?? 0).toDouble();
                final p = (d['protein'] ?? 0).toDouble();
                final c = (d['carb'] ?? 0).toDouble();
                final f = (d['fat'] ?? 0).toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${grams.toStringAsFixed(0)} g',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                _chip('P ${p.toStringAsFixed(1)}g', cs),
                                _chip('K ${c.toStringAsFixed(1)}g', cs),
                                _chip('Y ${f.toStringAsFixed(1)}g', cs),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${kcal.toStringAsFixed(0)} kcal',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          IconButton(
                            tooltip: 'Sil',
                            onPressed: () async {
                              await fs.deleteFoodEntry(
                                  userId: userId, docId: doc.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Silindi')),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(String label, double value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value.toStringAsFixed(unit == 'kcal' ? 0 : 1),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _chip(String text, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
    );
  }
}
