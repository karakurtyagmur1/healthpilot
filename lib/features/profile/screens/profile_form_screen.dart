import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/profile_enums.dart';
import 'package:healthpilot/services/firestore_service.dart';
import 'package:healthpilot/services/macro_calculator.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  final _targetWeightCtrl = TextEditingController();
  final _targetWeeksCtrl = TextEditingController(text: '8');

  Gender _gender = Gender.female;
  ActivityLevel _activity = ActivityLevel.moderate;

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _targetWeeksCtrl.dispose();
    super.dispose();
  }

  String _genderLabel(Gender g) => g == Gender.female ? 'Kadın' : 'Erkek';

  String _activityLabel(ActivityLevel a) {
    switch (a) {
      case ActivityLevel.sedentary:
        return 'Sedanter';
      case ActivityLevel.light:
        return 'Hafif';
      case ActivityLevel.moderate:
        return 'Orta';
      case ActivityLevel.high:
        return 'Yüksek';
    }
  }

  double _parseDouble(String v) =>
      double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;

  int _parseInt(String v) => int.tryParse(v.trim()) ?? 0;

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1) Form değerleri
      final name = _nameCtrl.text.trim();
      final age = _parseInt(_ageCtrl.text);
      final heightCm = _parseDouble(_heightCtrl.text);
      final weightKg = _parseDouble(_weightCtrl.text);
      final targetWeightKg = _parseDouble(_targetWeightCtrl.text);
      final targetWeeks = _parseInt(_targetWeeksCtrl.text);

      // 2) Plan hesapla
      final plan = MacroCalculator.buildPlan(
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        gender: _gender,
        activity: _activity,
        targetWeightKg: targetWeightKg,
        targetWeeks: targetWeeks,
      );

      // 3) Profil datası (temel alanlar)
      final profileData = <String, dynamic>{
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'gender': _gender.name,
        'activityLevel': _activity.name,
        'targetWeightKg': targetWeightKg,
        'targetWeeks': targetWeeks,

        // ✅ Geriye uyumluluk (eski dashboard/chat anahtarları kullananlar için)
        // Eski sistem bu alanları okuyorsa da bozulmasın:
        'kcalTarget': plan.targetCalories,
        'proteinTarget': plan.proteinG,
        'carbTarget': plan.carbG,
        'fatTarget': plan.fatG,
      };

      // 4) Firestore'a yaz (profil + macroPlan birlikte)
      final firestore = FirestoreService();
      await firestore.saveUserProfile(
        user.uid,
        profileData,
        macroPlan: plan.toMap(), // ✅ yeni standart: macroPlan içinde
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hedefler hesaplandı ve kaydedildi')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Kaydetme sırasında hata: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Hedef Planı')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ad Soyad girin' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Yaş'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 10 || n > 90)
                      return 'Yaşı kontrol edin';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _heightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Boy (cm)'),
                  validator: (v) {
                    final n =
                        double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    if (n == null || n < 120 || n > 230)
                      return 'Boyu kontrol edin';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                  validator: (v) {
                    final n =
                        double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    if (n == null || n < 30 || n > 250)
                      return 'Kiloyu kontrol edin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Cinsiyet',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Gender>(
                  value: _gender,
                  decoration: const InputDecoration(),
                  items: Gender.values
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(_genderLabel(g)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                ),
                const SizedBox(height: 16),
                const Text('Aktivite',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<ActivityLevel>(
                  value: _activity,
                  decoration: const InputDecoration(),
                  items: ActivityLevel.values
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(_activityLabel(a)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _activity = v ?? _activity),
                ),
                const SizedBox(height: 16),
                const Text('Hedef Plan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetWeightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Hedef kilo (kg)'),
                  validator: (v) {
                    final n =
                        double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    if (n == null || n < 30 || n > 250)
                      return 'Hedef kiloyu kontrol edin';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetWeeksCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Kaç haftada? (örn: 8)'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 4 || n > 52)
                      return '4–52 hafta arası girin';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Hedefleri Hesapla ve Kaydet'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
