import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/screens/splash_screen.dart';
import 'package:staff_app/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Staff App',
      navigatorKey: navigatorKey, // Use global navigator key for logout
      theme: ThemeData(
        textTheme: GoogleFonts.urbanistTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}
