import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthpilot/services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthService().signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      String msg = 'Giriş başarısız.';
      if (e.code == 'user-not-found') {
        msg = 'Bu e-posta ile kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        msg = 'Şifre hatalı.';
      } else if (e.code == 'invalid-credential') {
        msg = 'E-posta veya şifre hatalı.';
      }
      setState(() {
        _errorText = msg;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Beklenmeyen bir hata oluştu: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthPilot - Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorText != null) ...[
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Şifre'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Giriş Yap'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Hesabın yok mu? Kayıt ol'),
            ),
          ],
        ),
      ),
    );
  }
}
