class FoodItem {
  final String name;
  final double baseGrams; // bu değer için hesaplanmış makrolar
  final double kcal;
  final double protein;
  final double carb;
  final double fat;

  const FoodItem({
    required this.name,
    required this.baseGrams,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}

const List<FoodItem> foods = [
  FoodItem(
    name: 'Tavuk göğsü (pişmiş)',
    baseGrams: 100,
    kcal: 165,
    protein: 31,
    carb: 0,
    fat: 3.6,
  ),
  FoodItem(
    name: 'Yumurta (büyük)',
    baseGrams: 50,
    kcal: 72,
    protein: 6.3,
    carb: 0.4,
    fat: 4.8,
  ),
  FoodItem(
    name: 'Yulaf ezmesi (kuru)',
    baseGrams: 40,
    kcal: 150,
    protein: 5,
    carb: 27,
    fat: 3,
  ),
  FoodItem(
    name: 'Elma',
    baseGrams: 100,
    kcal: 52,
    protein: 0.3,
    carb: 14,
    fat: 0.2,
  ),
  FoodItem(
    name: 'Zeytinyağı',
    baseGrams: 10,
    kcal: 90,
    protein: 0,
    carb: 0,
    fat: 10,
  ),
];
