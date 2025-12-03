import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth/view/login_screen.dart';
import 'auth/view/register_screen.dart';
import 'home/main_home_screen.dart';
import 'crop_yield_prediction/view/crop_yield_prediction_screen.dart';
import 'crop_diseases_detection/controller/disease_detection_controller.dart';
import 'terms&permissions/controller/terms&conditions_controller.dart';
import 'terms&permissions/view/terms&conditions_view.dart';
import 'terms&permissions/view/permissions_screen.dart';
import 'prior_data/controller/farm_data_controller.dart';
import 'prior_data/view/simplified_data_collection_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiseaseDetectionController(),
      child: MaterialApp(
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
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/main': (context) => const MainHomeScreen(),
          '/crop-prediction': (context) => const CropYieldPredictionScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F6F0),
            body: Center(
              child: Lottie.asset(
                'assets/loading.json',
                width: 200,
                height: 200,
              ),
            ),
          );
        }

        // User is not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is logged in - check onboarding status
        return FutureBuilder<Widget>(
          future: _determineNextScreen(),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8F6F0),
                body: Center(
                  child: Lottie.asset(
                    'assets/loading.json',
                    width: 200,
                    height: 200,
                  ),
                ),
              );
            }

            return futureSnapshot.data ?? const LoginScreen();
          },
        );
      },
    );
  }

  Future<Widget> _determineNextScreen() async {
    // Check if user has accepted terms
    final termsController = TermsConditionsController();
    final hasAcceptedTerms = await termsController.hasAcceptedTerms();

    if (!hasAcceptedTerms) {
      return const TermsConditionsScreen();
    }

    // Check if permissions are granted
    final permissionsController = PermissionsController();
    final permissionStatus = await permissionsController
        .checkPermissionStatus();
    final hasLocation = permissionStatus['location'] ?? false;

    if (!hasLocation) {
      return const PermissionsScreen();
    }

    // Check if farm data is complete
    final farmDataController = FarmDataController();
    final isFarmDataComplete = await farmDataController.isFarmDataComplete();

    if (!isFarmDataComplete) {
      return const SimplifiedDataCollectionFlow();
    }

    // All onboarding complete - go to home
    return const MainHomeScreen();
  }
}
