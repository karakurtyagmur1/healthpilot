import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthpilot/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final pass2 = _password2Controller.text.trim();

    if (email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      setState(() => _errorText = 'Lütfen tüm alanları doldurun.');
      return;
    }
    if (pass != pass2) {
      setState(() => _errorText = 'Şifreler eşleşmiyor.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorText = 'Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthService().registerWithEmail(email: email, password: pass);

      if (!mounted) return;

      // İstersen burada profile form'a yönlendirebiliriz:
      // Navigator.pushReplacementNamed(context, '/profile-form');

      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      String msg = 'Kayıt başarısız.';
      if (e.code == 'email-already-in-use') {
        msg = 'Bu e-posta zaten kullanılıyor.';
      } else if (e.code == 'invalid-email') {
        msg = 'Geçersiz e-posta adresi.';
      } else if (e.code == 'weak-password') {
        msg = 'Şifre çok zayıf.';
      }
      setState(() => _errorText = msg);
    } catch (e) {
      setState(() => _errorText = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _header() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hesap Oluştur',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Yeni hesabınla hedeflerini kaydet ve takibe başla.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                _header(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: cs.outlineVariant.withOpacity(0.6)),
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
                      if (_errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: cs.onErrorContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: TextStyle(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure1,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure1 = !_obscure1),
                            icon: Icon(_obscure1
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password2Controller,
                        obscureText: _obscure2,
                        decoration: InputDecoration(
                          labelText: 'Şifre (tekrar)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure2 = !_obscure2),
                            icon: Icon(_obscure2
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        onSubmitted: (_) => _register(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Kayıt Ol'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Zaten hesabın var mı?',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Giriş yap'),
                          ),
                        ],
                      ),
                    ],
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
