import 'package:flutter/material.dart';
import '../../widgets/translated_text.dart';
import 'livestock_form_screen.dart';

class LivestockDetectionView extends StatelessWidget {
  const LivestockDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Page Title
          const TranslatedText(
            'Livestock Health Check',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
            ),
          ),
          const SizedBox(height: 20),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2D5016)),
                    SizedBox(width: 10),
                    TranslatedText(
                      'Inspection Guide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const TranslatedText(
                  '1. Check livestock for lethargy, unusual behavior, or physical symptoms.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
                ),
                const SizedBox(height: 8),
                const TranslatedText(
                  '2. Inspect for unusual discharge, sores, or loss of appetite.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
                ),
                const SizedBox(height: 8),
                const TranslatedText(
                  '3. Use the Scan feature for AI-based analysis of photos and symptoms.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Start Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LivestockFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const TranslatedText(
              'Start Health Scan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCCD2A), // Yellow from React Native code
              foregroundColor: const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }
}
