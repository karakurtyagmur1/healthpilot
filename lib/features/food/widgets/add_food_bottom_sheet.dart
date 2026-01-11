import 'package:flutter/material.dart';

import 'package:healthpilot/services/firestore_service.dart';
import 'package:healthpilot/data/foods.dart'; // FoodItem + foods listesi burada

class AddFoodBottomSheet extends StatefulWidget {
  final String userId;
  final String mealType;
  final String dateKey; // ✅ seçili gün

  const AddFoodBottomSheet({
    super.key,
    required this.userId,
    required this.mealType,
    required this.dateKey,
  });

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final _fs = FirestoreService();

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _gramsCtrl = TextEditingController(text: '100');

  FoodItem? _selected;
  List<FoodItem> _filtered = foods;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filtered = foods;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? foods
          : foods
              .where((f) => f.name.toLowerCase().contains(q))
              .toList(growable: false);
    });
  }

  double _parseGrams() {
    final raw = _gramsCtrl.text.trim().replaceAll(',', '.');
    final g = double.tryParse(raw);
    if (g == null || g <= 0) return 0;
    return g;
  }

  Map<String, double> _calcScaled(FoodItem item, double grams) {
    final base = item.baseGrams <= 0 ? 1.0 : item.baseGrams;
    final factor = grams / base;

    double round2(double v) => (v * 100).roundToDouble() / 100;

    return {
      'kcal': round2(item.kcal * factor),
      'protein': round2(item.protein * factor),
      'carb': round2(item.carb * factor),
      'fat': round2(item.fat * factor),
    };
  }

  Future<void> _addSelected() async {
    final item = _selected;
    if (item == null) {
      setState(() => _error = 'Lütfen bir besin seçin.');
      return;
    }

    final grams = _parseGrams();
    if (grams <= 0) {
      setState(() => _error = 'Gram değerini doğru girin (örn: 120).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final m = _calcScaled(item, grams);

      await _fs.addFoodEntry(
        userId: widget.userId,
        mealType: widget.mealType,
        name: item.name,
        grams: grams,
        kcal: m['kcal']!,
        protein: m['protein']!,
        carb: m['carb']!,
        fat: m['fat']!,
        dateKey: widget.dateKey, // ✅ seçili gün
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Kayıt hatası: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;

    final selected = _selected;
    final grams = _parseGrams();

    final preview =
        (selected != null && grams > 0) ? _calcScaled(selected, grams) : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: viewInsets + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Besin Ekle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.dateKey,
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Besin ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // List
            SizedBox(
              height: 260,
              child: Material(
                color: Colors.transparent,
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = _filtered[i];
                    final isSel = _selected?.name == item.name;

                    return ListTile(
                      dense: true,
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${item.baseGrams.toStringAsFixed(0)} g baz • '
                        '${item.kcal.toStringAsFixed(0)} kcal',
                      ),
                      trailing: isSel
                          ? Icon(Icons.check_circle, color: cs.primary)
                          : const Icon(Icons.circle_outlined),
                      onTap: () => setState(() => _selected = item),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Grams + Preview
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gramsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Gram',
                      suffixText: 'g',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: preview == null
                        ? const Text(
                            'Makro önizleme',
                            style: TextStyle(color: Colors.black54),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${preview['kcal']!.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'P: ${preview['protein']!.toStringAsFixed(1)}  '
                                'K: ${preview['carb']!.toStringAsFixed(1)}  '
                                'Y: ${preview['fat']!.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _addSelected,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Ekle',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
