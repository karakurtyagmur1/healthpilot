import 'features/profile/screens/profile_screen.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/profile/screens/profile_form_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';

  runApp(const HealthPilotApp());
}

class HealthPilotApp extends StatelessWidget {
  const HealthPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1DB954);

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A84FF),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF0A84FF),
        secondary: const Color(0xFF34C759),
        surface: const Color(0xFFF6F7F8),
        surfaceContainerHighest: const Color(0xFFE9ECEF),
        outlineVariant: const Color(0xFFDADDE1),
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F3F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w900),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthPilot',
      theme: theme,
      home: const LoginScreen(),
      routes: {
        '/profile': (context) => ProfileScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile-form': (context) => const ProfileFormScreen(),
      },
    );
  }
}
