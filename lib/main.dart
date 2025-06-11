// main.dart
import 'package:flutter/material.dart';
import 'screens/auth/landingpage.dart';
import 'screens/auth/login.dart';
import 'screens/auth/regis.dart';
import 'screens/dashboard.dart';
import 'screens/materi/materipage.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const QuizCodeApp(),
    ),
  );
}

class QuizCodeApp extends StatelessWidget {
  const QuizCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuizCode',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      initialRoute: '/', // Start at login page
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) {
          final authProvider = Provider.of<AuthProvider>(context);
          return DashboardPage(token: authProvider.token.isNotEmpty ? authProvider.token : '');
        },
        '/materi': (context) {
          final authProvider = Provider.of<AuthProvider>(context);
          return MateriPage(token: authProvider.token.isNotEmpty ? authProvider.token : '');
        },
      },
    );
  }
}