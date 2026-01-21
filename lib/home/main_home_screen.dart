import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profile/view/profile_view.dart';
import '../../crop_yield_prediction/view/prediction_with_detection_screen.dart';
import '../../connections/view/connections_screen.dart';
import '../home/view/screens/home_screen.dart' as crop_home;
import '../../providers/language_provider.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0; // Start with home tab

  final List<Widget> _screens = [
    const crop_home.HomeScreen(), // Crop management home
    const PredictionWithDetectionScreen(), // Combined Prediction + Detection
    const ConnectionsScreen(), // AgriConnect - Map, Chat, News
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: const Color(0xFF2D5016),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/home.png',
                  width: 28,
                  height: 28,
                  color: _currentIndex == 0
                      ? const Color(0xFF2D5016)
                      : Colors.grey,
                ),
                label: _getLabel(languageProvider.currentLanguage.code, 'Home'),
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/prediction.png',
                  width: 28,
                  height: 28,
                  color: _currentIndex == 1
                      ? const Color(0xFF2D5016)
                      : Colors.grey,
                ),
                label: _getLabel(languageProvider.currentLanguage.code, 'Prediction'),
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/connect.png',
                  width: 28,
                  height: 28,
                  color: _currentIndex == 2
                      ? const Color(0xFF2D5016)
                      : Colors.grey,
                ),
                label: _getLabel(languageProvider.currentLanguage.code, 'Connect'),
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/profile.png',
                  width: 28,
                  height: 28,
                  color: _currentIndex == 3
                      ? const Color(0xFF2D5016)
                      : Colors.grey,
                ),
                label: _getLabel(languageProvider.currentLanguage.code, 'Profile'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLabel(String code, String feature) {
    switch (feature) {
      case 'Home':
        if (code == 'or') return 'ଘର';
        if (code == 'hi') return 'होम';
        if (code == 'ta') return 'முகப்பு';
        return 'Home';
      case 'Prediction':
        if (code == 'or') return 'ପୂର୍ବାନୁମାନ';
        if (code == 'hi') return 'भविष्यवाणी';
        if (code == 'ta') return 'கணிப்பு';
        return 'Prediction';
      case 'Connect':
        if (code == 'or') return 'ସଂଯୋଗ';
        if (code == 'hi') return 'जुड़ाव';
        if (code == 'ta') return 'சமூகம்';
        return 'Connect';
      case 'Profile':
        if (code == 'or') return 'ପ୍ରୋଫାଇଲ୍';
        if (code == 'hi') return 'प्रोफाइल';
        if (code == 'ta') return 'சுயவிவரம்';
        return 'Profile';
      default:
        return feature;
    }
  }
}
