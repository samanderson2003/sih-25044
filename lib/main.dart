import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/view/login_screen.dart';
import 'auth/view/register_screen.dart';
import 'home/view/home_screen.dart';
import 'crop_yield_prediction/view/crop_yield_prediction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropYield - Smart Farming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5016),
          primary: const Color(0xFF2D5016),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F6F0),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const HomeScreen(),
        '/crop-prediction': (context) => const CropYieldPredictionScreen(),
      },
    );
  }
}
