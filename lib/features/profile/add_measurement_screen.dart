import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../services/firestore_service.dart';

class AddMeasurementScreen extends StatefulWidget {
  const AddMeasurementScreen({super.key});

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  final _fs = FirestoreService();
  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_date);

  double _toDouble(String s) {
    return double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'Oturum bulunamadı.');
      return;
    }

    final weight = _toDouble(_weightCtrl.text);
    if (weight <= 0) {
      setState(() => _error = 'Geçerli bir kilo girin.');
      return;
    }

    final waist = _toDouble(_waistCtrl.text);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // 1) ölçüm kaydı ekle
      await _fs.addMeasurement(
        userId: uid,
        dateKey: _dateKey,
        weightKg: weight,
        waistCm: waist <= 0 ? null : waist,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      // 2) profile "son kilo"yu da güncelle
      await _fs.saveUserProfile(uid, {
        'weight': weight,
        'updatedAt': DateTime.now(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kilo Güncelle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tarih'),
              subtitle: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_date)),
              trailing: const Icon(Icons.calendar_today_outlined, size: 20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),

            const SizedBox(height: 10),
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Kilo',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _waistCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Bel (opsiyonel)',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('Kaydet'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
