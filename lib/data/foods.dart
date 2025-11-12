// lib/data/foods.dart
// 100 g bazlı basit yerel besin veri seti

class FoodItem {
  final String name; // Görünen ad
  final List<String> altNames; // Aramada eşleşsin diye alternatif adlar
  final int calories; // kcal / 100 g
  final int protein; // g / 100 g
  final int carb; // g / 100 g
  final int fat; // g / 100 g

  const FoodItem({
    required this.name,
    required this.altNames,
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}

// Not: Değerler referans amaçlı yaklaşık değerlerdir.
const List<FoodItem> foods = [
  // Protein odaklı
  FoodItem(
    name: 'Yumurta',
    altNames: ['egg', 'yumurta'],
    calories: 155,
    protein: 13,
    carb: 1,
    fat: 11,
  ),
  FoodItem(
    name: 'Tavuk Göğsü',
    altNames: ['chicken breast', 'tavuk', 'tavuk gogsu', 'chicken'],
    calories: 165,
    protein: 31,
    carb: 0,
    fat: 4,
  ),
  FoodItem(
    name: 'Hindi Göğsü',
    altNames: ['turkey', 'hindi', 'hindi gogsu'],
    calories: 135,
    protein: 29,
    carb: 0,
    fat: 1,
  ),
  FoodItem(
    name: 'Somon',
    altNames: ['salmon', 'balık', 'balik', 'somon baliği'],
    calories: 208,
    protein: 20,
    carb: 0,
    fat: 13,
  ),
  FoodItem(
    name: 'Yağsız Süzme Yoğurt',
    altNames: ['greek yogurt', 'suzme yogurt', 'yogurt'],
    calories: 59,
    protein: 10,
    carb: 3,
    fat: 0,
  ),

  // Karbonhidrat odaklı
  FoodItem(
    name: 'Pişmiş Pirinç (Beyaz)',
    altNames: ['rice', 'pilav', 'pirinc', 'white rice'],
    calories: 130,
    protein: 2,
    carb: 28,
    fat: 0,
  ),
  FoodItem(
    name: 'Yulaf',
    altNames: ['oat', 'oatmeal', 'yulaf ezmesi'],
    calories: 389,
    protein: 17,
    carb: 66,
    fat: 7,
  ),
  FoodItem(
    name: 'Tam Buğday Ekmek',
    altNames: ['whole wheat bread', 'ekmek', 'tam bugday'],
    calories: 247,
    protein: 13,
    carb: 41,
    fat: 4,
  ),
  FoodItem(
    name: 'Makarna (pişmiş)',
    altNames: ['pasta', 'makarna'],
    calories: 131,
    protein: 5,
    carb: 25,
    fat: 1,
  ),

  // Yağ & karışık
  FoodItem(
    name: 'Zeytinyağı',
    altNames: ['olive oil', 'zeytinyagi'],
    calories: 884,
    protein: 0,
    carb: 0,
    fat: 100,
  ),
  FoodItem(
    name: 'Avokado',
    altNames: ['avocado', 'avokado'],
    calories: 160,
    protein: 2,
    carb: 9,
    fat: 15,
  ),
  FoodItem(
    name: 'Badem (çiğ)',
    altNames: ['almond', 'badem'],
    calories: 579,
    protein: 21,
    carb: 22,
    fat: 50,
  ),

  // Basit meyve/sebze
  FoodItem(
    name: 'Elma',
    altNames: ['apple', 'elma'],
    calories: 52,
    protein: 0,
    carb: 14,
    fat: 0,
  ),
  FoodItem(
    name: 'Muz',
    altNames: ['banana', 'muz'],
    calories: 89,
    protein: 1,
    carb: 23,
    fat: 0,
  ),
  FoodItem(
    name: 'Brokoli',
    altNames: ['broccoli', 'brokoli'],
    calories: 34,
    protein: 3,
    carb: 7,
    fat: 0,
  ),
];
