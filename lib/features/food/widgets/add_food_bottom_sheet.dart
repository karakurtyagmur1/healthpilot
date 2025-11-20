import 'package:flutter/material.dart';
import 'package:healthpilot/data/foods.dart';
import 'package:healthpilot/services/firestore_service.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final String mealType; // breakfast, lunch, dinner, snack
  final String userId;

  const AddFoodBottomSheet({
    super.key,
    required this.mealType,
    required this.userId,
  });

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final _searchCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  final _fs = FirestoreService();

  List<FoodItem> _results = foods;
  FoodItem? _selected;

  @override
  void initState() {
    super.initState();
    if (foods.isNotEmpty) {
      _selected = foods.first;
    }
  }

  void _onSearchChanged(String value) {
    final q = value.toLowerCase();
    setState(() {
      _results = foods
          .where((f) => f.name.toLowerCase().contains(q))
          .toList(growable: false);
      if (_results.isNotEmpty) {
        _selected = _results.first;
      } else {
        _selected = null;
      }
    });
  }

  Future<void> _addSelected() async {
    if (_selected == null) return;

    final gramsText = _gramsCtrl.text.replaceAll(',', '.');
    final grams = double.tryParse(gramsText) ?? 0;
    if (grams <= 0) return;

    final factor = grams / _selected!.baseGrams;

    final kcal = _selected!.kcal * factor;
    final protein = _selected!.protein * factor;
    final carb = _selected!.carb * factor;
    final fat = _selected!.fat * factor;

    await _fs.addFoodEntry(
      userId: widget.userId,
      mealType: widget.mealType,
      name: _selected!.name,
      grams: grams,
      kcal: kcal,
      protein: protein,
      carb: carb,
      fat: fat,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Besin ara',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gramsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Miktar (gram)',
                  suffixText: 'g',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              if (_results.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.baseGrams.toStringAsFixed(0)} g için: '
                        '${item.kcal.toStringAsFixed(0)} kcal • '
                        'P:${item.protein.toStringAsFixed(1)}g '
                        'K:${item.carb.toStringAsFixed(1)}g '
                        'Y:${item.fat.toStringAsFixed(1)}g',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                        setState(() {
                          _selected = item;
                          _searchCtrl.text = item.name;
                        });
                      },
                      selected: _selected == item,
                    );
                  },
                )
              else
                const Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addSelected,
                  child: const Text('Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
