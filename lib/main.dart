import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PSApp(),
    ),
  );
}

class PSApp extends StatelessWidget {
  const PSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الحريفة PS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0b0e14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38bdf8),
          secondary: Color(0xFF4ade80),
          surface: Color(0xFF1c2128),
        ),
        cardColor: const Color(0xFF1c2128),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF38bdf8),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return state.isAdmin ? const HomeScreen() : const LoginScreen();
  }
}
