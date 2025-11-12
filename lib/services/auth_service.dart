import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Kayıt olma fonksiyonu
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // 🔹 Giriş yapma fonksiyonu
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // 🔹 Çıkış yapma fonksiyonu
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 🔹 Şu anda giriş yapan kullanıcıyı getir
  User? get currentUser => _auth.currentUser;
}
