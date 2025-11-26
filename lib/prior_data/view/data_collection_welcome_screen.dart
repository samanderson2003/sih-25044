import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/farm_data_controller.dart';
import '../model/farm_data_model.dart';
import 'land_details_screen.dart';
import 'soil_quality_screen.dart';
import 'past_data_screen.dart';
import 'crop_details_screen.dart';

class DataCollectionWelcomeScreen extends StatefulWidget {
  const DataCollectionWelcomeScreen({super.key});

  @override
  State<DataCollectionWelcomeScreen> createState() =>
      _DataCollectionWelcomeScreenState();
}

class _DataCollectionWelcomeScreenState
    extends State<DataCollectionWelcomeScreen> {
  final _controller = FarmDataController();

  // Track completion of each step
  LandDetailsModel? _landDetails;
  SoilQualityModel? _soilQuality;
  PastDataModel? _pastData;
  CropDetailsModel? _cropDetails;

  bool _isLoading = true;
  bool _isSaving = false;

  // Theme colors
  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  static const accentColor = Color(0xFF6B8E23);
  static const textColor = Color(0xFF4A4A4A);

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final existingData = await _controller.getFarmData();
    if (existingData != null && mounted) {
      setState(() {
        _landDetails = existingData.landDetails;
        _soilQuality = existingData.soilQuality;
        _pastData = existingData.pastData;
        _cropDetails = existingData.cropDetails;
      });
    }
    setState(() => _isLoading = false);
  }

  bool get _allStepsComplete =>
      _landDetails != null &&
      _soilQuality != null &&
      _pastData != null &&
      _cropDetails != null;

  Future<void> _handleSubmit() async {
    if (!_allStepsComplete) return;

    setState(() => _isSaving = true);

    try {
      final farmData = FarmDataModel(
        userId: FirebaseAuth.instance.currentUser!.uid,
        landDetails: _landDetails!,
        soilQuality: _soilQuality!,
        pastData: _pastData!,
        cropDetails: _cropDetails!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _controller.saveFarmData(farmData);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('Profile Complete!'),
            content: const Text(
              'Your farm profile has been created successfully.',
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/main', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleUpdateLater() {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Header
              const Text(
                'Farm Profile Setup',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Let\'s collect some information about your farm to provide you with accurate predictions',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Progress steps - now clickable
              Expanded(
                child: ListView(
                  children: [
                    _buildClickableStepCard(
                      context: context,
                      icon: Icons.location_on_outlined,
                      title: 'Land Details',
                      description: 'Size, location, and basic information',
                      stepNumber: 1,
                      isCompleted: _landDetails != null,
                      onTap: () => _navigateToLandDetails(context),
                    ),
                    const SizedBox(height: 16),
                    _buildClickableStepCard(
                      context: context,
                      icon: Icons.science_outlined,
                      title: 'Soil Quality',
                      description: 'Soil nutrients and composition data',
                      stepNumber: 2,
                      isCompleted: _soilQuality != null,
                      onTap: _landDetails != null
                          ? () => _navigateToSoilQuality(context)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildClickableStepCard(
                      context: context,
                      icon: Icons.history,
                      title: 'Past Data',
                      description: 'Previous crop history and yields',
                      stepNumber: 3,
                      isCompleted: _pastData != null,
                      onTap: _soilQuality != null
                          ? () => _navigateToPastData(context)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildClickableStepCard(
                      context: context,
                      icon: Icons.agriculture_outlined,
                      title: 'Current Crop',
                      description: 'Details about your current cultivation',
                      stepNumber: 4,
                      isCompleted: _cropDetails != null,
                      onTap: _pastData != null
                          ? () => _navigateToCropDetails(context)
                          : null,
                    ),
                  ],
                ),
              ),

              // Submit or Update Later button
              if (_allStepsComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
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
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleUpdateLater,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Profile Later',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (!_allStepsComplete)
                Center(
                  child: Text(
                    'Click on each step above to fill in details',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLandDetails(BuildContext context) async {
    final result = await Navigator.push<LandDetailsModel>(
      context,
      MaterialPageRoute(
        builder: (context) => LandDetailsScreen(existingData: _landDetails),
      ),
    );

    if (result != null) {
      setState(() => _landDetails = result);
    }
  }

  void _navigateToSoilQuality(BuildContext context) async {
    final result = await Navigator.push<SoilQualityModel>(
      context,
      MaterialPageRoute(
        builder: (context) => SoilQualityScreen(
          landDetails: _landDetails!,
          existingData: _soilQuality,
        ),
      ),
    );

    if (result != null) {
      setState(() => _soilQuality = result);
    }
  }

  void _navigateToPastData(BuildContext context) async {
    final result = await Navigator.push<PastDataModel>(
      context,
      MaterialPageRoute(
        builder: (context) => PastDataScreen(
          landDetails: _landDetails!,
          soilQuality: _soilQuality!,
          existingData: _pastData,
        ),
      ),
    );

    if (result != null) {
      setState(() => _pastData = result);
    }
  }

  void _navigateToCropDetails(BuildContext context) async {
    final result = await Navigator.push<CropDetailsModel>(
      context,
      MaterialPageRoute(
        builder: (context) => CropDetailsScreen(
          landDetails: _landDetails!,
          soilQuality: _soilQuality!,
          pastData: _pastData!,
          existingData: _cropDetails,
        ),
      ),
    );

    if (result != null) {
      setState(() => _cropDetails = result);
    }
  }

  Widget _buildClickableStepCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required int stepNumber,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? Colors.green
                : isEnabled
                ? primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Step number badge or checkmark
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isEnabled
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? primaryColor : Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : isEnabled
                    ? accentColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isCompleted
                    ? Colors.green
                    : isEnabled
                    ? accentColor
                    : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? textColor : Colors.grey,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled
                          ? textColor.withOpacity(0.6)
                          : Colors.grey.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isEnabled
                  ? primaryColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
