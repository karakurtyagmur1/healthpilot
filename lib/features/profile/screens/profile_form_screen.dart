import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthpilot/services/firestore_service.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final data = {
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'height': double.tryParse(_heightCtrl.text) ?? 0,
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'email': user.email,
      };

      // ← burası önemli
      await FirestoreService().saveUserProfile(data);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
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
      appBar: AppBar(title: const Text('Profilini Tamamla')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Yaş'),
                validator: (v) => v == null || v.isEmpty ? 'Yaş gir' : null,
              ),
              TextFormField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Boy (cm)'),
              ),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kilo (kg)'),
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('Kaydet'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
