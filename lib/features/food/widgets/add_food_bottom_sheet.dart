import 'package:flutter/material.dart';
import 'package:healthpilot/services/firestore_service.dart';
import 'package:healthpilot/data/foods.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final String userId;
  final String mealType; // breakfast | lunch | dinner | snack
  const AddFoodBottomSheet(
      {super.key, required this.userId, required this.mealType});

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _gramsCtrl = TextEditingController(text: '100');

  List<FoodItem> _results = foods; // başlangıçta tüm liste
  FoodItem? _selected;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = foods);
      return;
    }
    setState(() {
      _results = foods.where((f) {
        final n = f.name.toLowerCase();
        final alts = f.altNames.map((e) => e.toLowerCase());
        return n.contains(q) || alts.any((a) => a.contains(q));
      }).toList();
    });
  }

  Future<void> _addSelected() async {
    if (_selected == null) return;
    final grams = int.tryParse(_gramsCtrl.text) ?? 100;
    final factor = grams / 100.0;

    await FirestoreService().addFoodItem(
      userId: widget.userId,
      mealType: widget.mealType,
      name: _selected!.name,
      grams: grams,
      calories: (_selected!.calories * factor).round(),
      protein: (_selected!.protein * factor).round(),
      carb: (_selected!.carb * factor).round(),
      fat: (_selected!.fat * factor).round(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Besin Ekle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Besin ara (örn: tavuk, yumurta...)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  final selected = item == _selected;
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        '100 g: ${item.calories} kcal • P:${item.protein}g K:${item.carb}g Y:${item.fat}g'),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => setState(() => _selected = item),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Gram:'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _gramsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '100',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSelected,
                  child: const Text('Ekle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
