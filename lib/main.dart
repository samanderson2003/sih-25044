// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'auth/view/login_screen.dart';
import 'auth/view/register_screen.dart';
import 'home/main_home_screen.dart';
import 'crop_yield_prediction/view/crop_yield_prediction_screen.dart';
import 'crop_diseases_detection/controller/disease_detection_controller.dart';
import 'profile/controller/cattle_controller.dart';
import 'terms&permissions/controller/terms&conditions_controller.dart';
import 'terms&permissions/view/terms&conditions_view.dart';
import 'terms&permissions/view/permissions_screen.dart';
import 'prior_data/controller/farm_data_controller.dart';
import 'prior_data/view/simplified_data_collection_flow.dart';
import 'providers/language_provider.dart';
import 'connections/controller/connections_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe Firebase initialization: only initialize if not already initialized.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized (fresh).');
    } else {
      debugPrint('Firebase already initialized — reusing existing instance.');
    }
    
    // Initialize dotenv
    await dotenv.load(fileName: ".env");
    
  } catch (e, st) {
    // Log error but continue so the app shows an error UI instead of crashing.
    debugPrint('Firebase initialization error: $e');
    debugPrintStack(stackTrace: st);
    // We intentionally do not rethrow here so the app can show an error screen.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controllers/providers used across the app here.
    // Use ChangeNotifierProvider only for classes that extend ChangeNotifier.
    // Use plain Provider for non-ChangeNotifier classes.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        // If DiseaseDetectionController extends ChangeNotifier keep this as is.
        // If it doesn't, change to Provider< DiseaseDetectionController >(...)
        ChangeNotifierProvider(create: (_) => DiseaseDetectionController()),
        // TermsConditionsController and FarmDataController apparently don't extend ChangeNotifier
        // so we register them with plain Provider.
        Provider<TermsConditionsController>(create: (_) => TermsConditionsController()),
        Provider<FarmDataController>(create: (_) => FarmDataController()),
        Provider<CattleController>(create: (_) => CattleController()),
        ChangeNotifierProvider(create: (_) => ConnectionsController()),
      ],
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
    // If Firebase failed to initialize at startup, show a friendly error screen.
    if (Firebase.apps.isEmpty) {
      return const FirebaseInitErrorScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScaffold();
        }

        // User is not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is logged in - check onboarding status
        return FutureBuilder<Widget>(
          future: _determineNextScreen(context),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScaffold();
            }

            return futureSnapshot.data ?? const LoginScreen();
          },
        );
      },
    );
  }

  Future<Widget> _determineNextScreen(BuildContext context) async {
    // Use provider controllers that were registered in MultiProvider.
    // If for some reason the provider isn't available, fallback to creating a local instance.
    TermsConditionsController termsController;
    try {
      termsController = Provider.of<TermsConditionsController>(context, listen: false);
    } catch (_) {
      termsController = TermsConditionsController();
    }
    final hasAcceptedTerms = await termsController.hasAcceptedTerms();

    if (!hasAcceptedTerms) {
      return const TermsConditionsScreen();
    }

    // Permissions controller may not be provided; use local shim if needed.
    final permissionsController = PermissionsController();
    final permissionStatus = await permissionsController.checkPermissionStatus();
    final hasLocation = permissionStatus['location'] ?? false;

    if (!hasLocation) {
      return const PermissionsScreen();
    }

    FarmDataController farmDataController;
    try {
      farmDataController = Provider.of<FarmDataController>(context, listen: false);
    } catch (_) {
      farmDataController = FarmDataController();
    }
    final isFarmDataComplete = await farmDataController.isFarmDataComplete();

    if (!isFarmDataComplete) {
      return const SimplifiedDataCollectionFlow();
    }

    // All onboarding complete - go to home
    return const MainHomeScreen();
  }
}

/// Simple consistent loading scaffold used while checking auth/onboarding.
class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// Screen shown when Firebase wasn't initialized (so the app can't use Firebase features).
class FirebaseInitErrorScreen extends StatelessWidget {
  const FirebaseInitErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('Initialization Error'),
        backgroundColor: const Color(0xFF2D5016),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Firebase failed to initialize.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Check your Firebase options, internet connection, and logs. '
                'You can still use parts of the app that do not require Firebase.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                ),
                onPressed: () {
                  _attemptReinitialize(context);
                },
                child: const Text('Retry Initialization'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attemptReinitialize(BuildContext context) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Retry failed: $e')));
    }
  }
}

/// Lightweight PermissionsController shim.
/// Replace with your actual implementation if available.
class PermissionsController {
  /// Example check which returns a map of permission statuses.
  /// Replace or expand with your actual permission logic.
  Future<Map<String, bool>> checkPermissionStatus() async {
    // small delay to simulate async permission checks
    await Future.delayed(const Duration(milliseconds: 150));
    // Default to false so app navigates to PermissionsScreen and requests them.
    return {'location': false};
  }
}
