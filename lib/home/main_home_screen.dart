import 'package:flutter/material.dart';
import '../../profile/view/profile_view.dart';
import '../../crop_yield_prediction/view/prediction_with_detection_screen.dart';
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Prediction',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
