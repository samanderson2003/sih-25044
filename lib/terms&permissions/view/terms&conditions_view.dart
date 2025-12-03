import 'package:flutter/material.dart';
import '../controller/terms&conditions_controller.dart';
import 'permissions_screen.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final TermsConditionsController _controller = TermsConditionsController();
  bool _isAccepted = false;
  bool _isLoading = false;

  // Theme colors
  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  static const textColor = Color(0xFF4A4A4A);

  Future<void> _handleAccept() async {
    if (!_isAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _controller.acceptTerms();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      // Navigate to permissions screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Terms content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please read and accept our terms to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Terms sections
                  _buildSection(
                    '1. Acceptance of Terms',
                    'By accessing and using CropYield, you accept and agree to be bound by the terms and provision of this agreement.',
                  ),
                  _buildSection(
                    '2. Use of Service',
                    'Our crop yield prediction service provides estimates based on the data you provide. While we strive for accuracy, predictions are not guaranteed and should be used as guidance only.',
                  ),
                  _buildSection(
                    '3. User Data',
                    'You agree to provide accurate information about your farm, soil conditions, and crops. We collect and store this data to improve our prediction models and provide personalized recommendations.',
                  ),
                  _buildSection(
                    '4. Location Services',
                    'We use your location to fetch accurate weather data and help you find nearby soil testing centers. Your location data is stored securely and never shared with third parties.',
                  ),
                  _buildSection(
                    '5. Privacy',
                    'Your privacy is important to us. We collect only necessary data to provide our services. Your farm data and predictions remain private and are never sold to third parties.',
                  ),
                  _buildSection(
                    '6. Soil Data Sources',
                    'We offer multiple ways to input soil data:\n\n• Manual Entry: Most accurate, based on your soil test reports\n• Satellite Data: Less accurate, for quick estimates\n• Soil Test Centers: We help you locate nearby testing facilities',
                  ),
                  _buildSection(
                    '7. Accuracy Disclaimer',
                    'Crop yield predictions are estimates based on historical data and current conditions. Actual yields may vary due to unforeseen factors like pests, diseases, or extreme weather events.',
                  ),
                  _buildSection(
                    '8. Changes to Terms',
                    'We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of new terms.',
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom section with checkbox and button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkbox
                InkWell(
                  onTap: () => setState(() => _isAccepted = !_isAccepted),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAccepted,
                        onChanged: (value) =>
                            setState(() => _isAccepted = value ?? false),
                        activeColor: primaryColor,
                      ),
                      Expanded(
                        child: Text(
                          'I have read and agree to the Terms & Conditions',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Accept & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}
