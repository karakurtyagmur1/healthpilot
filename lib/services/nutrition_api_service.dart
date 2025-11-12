class NutritionApiService {
  /// Şimdilik gerçek API çağrısı yapmıyoruz.
  /// Girilen isme göre örnek makro değerleri döndürüyoruz.
  /// İleride burayı gerçek HTTP isteği ile değiştirebilirsin.
  Future<Map<String, double>> fetchNutritionFor(String name) async {
    final lower = name.toLowerCase();

    // Basit örnekler
    if (lower.contains('yumurta')) {
      return {'calories': 78, 'protein': 6.0, 'carb': 0.6, 'fat': 5.3};
    } else if (lower.contains('tavuk')) {
      // 100g tavuk göğsü
      return {'calories': 110, 'protein': 23.0, 'carb': 0.0, 'fat': 1.5};
    } else if (lower.contains('yulaf')) {
      return {'calories': 150, 'protein': 5.0, 'carb': 27.0, 'fat': 3.0};
    }

    // bulamazsa boş döner
    return {'calories': 0, 'protein': 0, 'carb': 0, 'fat': 0};
  }
}
