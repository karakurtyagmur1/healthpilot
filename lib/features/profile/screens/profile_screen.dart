import '../models/profile_enums.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:healthpilot/services/firestore_service.dart';
import 'package:healthpilot/services/macro_calculator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fs = FirestoreService();

  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _targetWeeksCtrl = TextEditingController();

  ActivityLevel _activity = ActivityLevel.moderate;

  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _targetWeeksCtrl.dispose();
    super.dispose();
  }

  ActivityLevel _parseActivity(String? s) {
    switch (s) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'light':
        return ActivityLevel.light;
      case 'high':
        return ActivityLevel.high;
      case 'moderate':
      default:
        return ActivityLevel.moderate;
    }
  }

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

  Gender _parseGender(String? s) => (s == 'male') ? Gender.male : Gender.female;

  double _num(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  String _modeLabel(String mode) {
    if (mode == 'lose') return 'Kilo verme';
    if (mode == 'gain') return 'Kilo alma';
    return 'Kilo koruma';
  }

  Widget _pill(BuildContext context, String text, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(BuildContext context,
      {required String label, required String value}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
    );
  }

  Future<void> _recalculateAndSave(
      String userId, Map<String, dynamic> p) async {
    final age = (p['age'] ?? 0) is int ? (p['age'] as int) : 0;
    final height = _num(p['height']);
    final gender = _parseGender(p['gender']?.toString());

    final weight =
        double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ??
            _num(p['weight']);
    final targetWeight =
        double.tryParse(_targetWeightCtrl.text.trim().replaceAll(',', '.')) ??
            _num(p['targetWeight']);
    final targetWeeks =
        int.tryParse(_targetWeeksCtrl.text.trim()) ?? (p['targetWeeks'] ?? 8);

    final plan = MacroCalculator.buildPlan(
      age: age,
      heightCm: height,
      weightKg: weight,
      gender: gender,
      activity: _activity,
      targetWeightKg: targetWeight,
      targetWeeks: targetWeeks,
    );

    setState(() => _saving = true);
    try {
      await _fs.saveUserProfile(userId, {
        'weight': weight,
        'targetWeight': targetWeight,
        'targetWeeks': targetWeeks,
        'activity': _activity.name,
        ...plan.toMap(),
        'updatedAt': DateTime.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan güncellendi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Oturum bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _fs.streamUserProfile(user.uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          if (p == null) {
            return const Center(child: Text('Profil bulunamadı'));
          }

          // İlk kez alanları doldur (kullanıcı yazmaya başlayınca tekrar overwrite etmesin)
          if (_weightCtrl.text.isEmpty) {
            _weightCtrl.text = (_num(p['weight'])).toStringAsFixed(1);
            _targetWeightCtrl.text =
                (_num(p['targetWeight'])).toStringAsFixed(1);
            _targetWeeksCtrl.text = (p['targetWeeks'] ?? 8).toString();
            _activity = _parseActivity(p['activity']?.toString());
          }

          final name = (p['name'] ?? 'Kullanıcı').toString();
          final mode = (p['mode'] ?? 'maintain').toString();

          final kcal = _num(p['kcalTarget']);
          final pr = _num(p['proteinTarget']);
          final cb = _num(p['carbTarget']);
          final ft = _num(p['fatTarget']);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Özet Kart ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _pill(context, _modeLabel(mode),
                            icon: Icons.flag_outlined),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _metricRow(context,
                        label: 'Kalori hedefi',
                        value: '${kcal.toStringAsFixed(0)} kcal'),
                    _metricRow(context,
                        label: 'Protein', value: '${pr.toStringAsFixed(0)} g'),
                    _metricRow(context,
                        label: 'Karbonhidrat',
                        value: '${cb.toStringAsFixed(0)} g'),
                    _metricRow(context,
                        label: 'Yağ', value: '${ft.toStringAsFixed(0)} g'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // --- Plan Güncelle Kart ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Planı güncelle',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _pill(context, _activityLabel(_activity),
                            icon: Icons.directions_run),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDec('Güncel kilo (kg)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _targetWeightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDec('Hedef kilo (kg)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _targetWeeksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec('Hedef süre (hafta)'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ActivityLevel>(
                      value: _activity,
                      items: ActivityLevel.values
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(_activityLabel(a)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _activity = v ?? _activity),
                      decoration: _inputDec('Aktivite'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // --- Butonlar ---
              SizedBox(
                width: double.infinity,
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: () => _recalculateAndSave(user.uid, p),
                        child: const Text('Planı yeniden hesapla'),
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/profile-form');
                  },
                  child: const Text('Onboarding formunu tekrar aç'),
                ),
              ),

              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}
