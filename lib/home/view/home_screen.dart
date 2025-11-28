import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/view/profile_view.dart';
import '../../crop_yield_prediction/view/crop_yield_prediction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Start with home tab

  final List<Widget> _screens = [
    const DetectionScreen(),
    const DashboardScreen(),
    const CropYieldPredictionScreen(),
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
        type: BottomNavigationBarType
            .fixed, // Prevents animation when more than 3 items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Detection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Prediction',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Detection Screen
class DetectionScreen extends StatelessWidget {
  const DetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Detection'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 100,
              color: const Color(0xFF2D5016).withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Crop Detection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Coming soon...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CropYield Dashboard'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              color: const Color(0xFF2D5016),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome to CropYield!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your smart farming assistant',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.trending_up,
                    title: 'Yield Prediction',
                    subtitle: 'Predict crop yield',
                    onTap: () {
                      // Switch to prediction tab
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() {
                        homeState._currentIndex = 2;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Detection',
                    subtitle: 'Scan crops',
                    onTap: () {
                      // Switch to detection tab
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() {
                        homeState._currentIndex = 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Features Section
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.cloud,
              title: 'Weather-Based Insights',
              description: 'Get predictions based on climate data',
            ),
            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.science,
              title: 'Soil Analysis',
              description: 'Analyze soil nutrients and health',
            ),
            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.attach_money,
              title: 'Economic Estimates',
              description: 'Calculate expected profits and ROI',
            ),
            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.lightbulb,
              title: 'Smart Recommendations',
              description: 'Get AI-powered farming advice',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: const Color(0xFF2D5016),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D5016).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2D5016),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
