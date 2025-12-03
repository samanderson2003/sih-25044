import 'package:flutter/material.dart';
import '../../profile/view/profile_view.dart';
import '../../crop_yield_prediction/view/prediction_with_detection_screen.dart';
import '../../connections/view/connections_screen.dart';
import '../home/view/screens/home_screen.dart' as crop_home;

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
              color: _currentIndex == 0 ? const Color(0xFF2D5016) : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/prediction.png',
              width: 28,
              height: 28,
              color: _currentIndex == 1 ? const Color(0xFF2D5016) : Colors.grey,
            ),
            label: 'Prediction',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/connect.png',
              width: 28,
              height: 28,
              color: _currentIndex == 2 ? const Color(0xFF2D5016) : Colors.grey,
            ),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/profile.png',
              width: 28,
              height: 28,
              color: _currentIndex == 3 ? const Color(0xFF2D5016) : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
