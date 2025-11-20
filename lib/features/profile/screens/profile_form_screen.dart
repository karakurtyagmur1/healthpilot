import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';

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

  String _gender = 'female';
  String _goal = 'lose';

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Oturum bulunamadı. Lütfen tekrar giriş yapın.';
      });
      return;
    }

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'age': int.tryParse(_ageCtrl.text) ?? 0,
      'height': double.tryParse(_heightCtrl.text) ?? 0,
      'weight': double.tryParse(_weightCtrl.text) ?? 0,
      'gender': _gender,
      'goal': _goal,
      'updatedAt': DateTime.now(),
    };

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await FirestoreService().saveUserProfile(user.uid, data);

      if (!mounted) return;
      // Profil kaydı sonrası anasayfaya yönlendir
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() {
        _error = e.toString();
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
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ad Soyad girin';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Yaş'),
                ),
                TextFormField(
                  controller: _heightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Boy (cm)'),
                ),
                TextFormField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cinsiyet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'female',
                      groupValue: _gender,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _gender = v);
                      },
                    ),
                    const Text('Kadın'),
                    Radio<String>(
                      value: 'male',
                      groupValue: _gender,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _gender = v);
                      },
                    ),
                    const Text('Erkek'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hedef',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _goal,
                  items: const [
                    DropdownMenuItem(
                      value: 'lose',
                      child: Text('Kilo vermek'),
                    ),
                    DropdownMenuItem(
                      value: 'maintain',
                      child: Text('Korumak'),
                    ),
                    DropdownMenuItem(
                      value: 'gain',
                      child: Text('Kilo almak'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _goal = v);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Kaydet'),
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
