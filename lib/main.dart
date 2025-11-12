import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// senin diğer ekranların
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/profile/screens/profile_form_screen.dart';

// YENİ: chat ekranını da ekliyoruz
import 'features/chat/screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HealthPilotApp());
}

class HealthPilotApp extends StatelessWidget {
  const HealthPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthPilot',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
      ),
      home: const LoginScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile-form': (context) => const ProfileFormScreen(),

        // YENİ: asistan ekranı
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}
