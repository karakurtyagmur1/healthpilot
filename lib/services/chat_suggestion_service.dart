class ChatSuggestionService {
  /// Kullanıcının yazdığı metne göre Flutter içinde cevap üretiyoruz.
  /// Şimdilik kural tabanlı. İleride burayı API ile değiştirebiliriz.
  String generateReply(String userMessage) {
    final msg = userMessage.toLowerCase();

    // kalça / bacak antrenmanı
    if (msg.contains('kalça') ||
        msg.contains('bacak') ||
        msg.contains('leg') ||
        msg.contains('glute')) {
      return '''
Kalça/bacak günü sonrası toparlanmak için şöyle beslenebilirsin:

• Antrenmandan sonra 25-35 g protein  
• Yanına 60-80 g kompleks karbonhidrat (pirinç, patates, yulaf)  
• Yağı çok artırma ki sindirimi yavaşlatmasın

İstersen sana 1 günlük örnek menü de yazayım.
''';
    }

    // protein eksik
    if (msg.contains('protein') &&
        (msg.contains('eksik') || msg.contains('kaldı'))) {
      return '''
Protein açığını hızlı tamamlamak için:

• 150 g tavuk göğsü ≈ 33 g protein  
• 1 kutu ton balığı ≈ 22-25 g protein  
• 3 haşlanmış yumurta ≈ 18 g protein  
• 200 g light yoğurt ≈ 12 g protein

"Kalorisi düşük olsun" dersen daha hafif öneri yapabilirim.
''';
    }

    // kalori hakkı
    if (msg.contains('kalori') && msg.contains('hakkım')) {
      return '''
Kalan kaloriyi kapatmak için ama çok yağlanmadan gitmek istiyorsan:

• 1 kase yoğurt + meyve ≈ 150-200 kcal  
• 1 tam buğday ekmek + 30 g peynir ≈ 150 kcal  
• 2 yumurta beyazı + 1 tam yumurta ≈ 120 kcal

"Protein de gelsin" dersen ona göre listelerim.
''';
    }

    // menü isteği
    if (msg.contains('menü') || msg.contains('örnek beslenme')) {
      return '''
Örnek 1 günlük beslenme (≈ 1800 kcal):

• Kahvaltı: 2 tam + 2 beyaz yumurta, 50 g yulaf, 1 meyve  
• Ara: 150 g yoğurt + 10 g kuruyemiş  
• Öğle: 150 g tavuk göğsü, 120 g esmer pirinç, bol salata  
• Ara: 1 galeta + 40 g lor  
• Akşam: 150 g balık veya yağsız et, sebze

"1500 kalori olsun" dersen porsiyonları küçültürüz.
''';
    }

    // varsayılan cevap
    return '''
Anladım 👍 Spor & beslenme için öneri verebilirim.
Bana şunları da yazabilirsin:
• "Bugün 1500 kcal yiyebilirim, nasıl böleyim?"
• "Antrenman sonrası ne yemeliyim?"
• "Proteinim 20 g eksik"
''';
  }
}
