import 'package:flutter/material.dart';
import '../model/farm_data_model.dart';
import '../controller/farm_data_controller.dart';
import '../controller/climate_service.dart';
import 'farm_basics_screen.dart';
import 'simplified_soil_quality_screen.dart';

/// Simplified 2-step data collection flow
/// Step 1: Farm Basics (location, size, crop, season)
/// Step 2: Soil Quality (6 micronutrients)
class SimplifiedDataCollectionFlow extends StatefulWidget {
  final FarmDataModel? initialFarmData;

  const SimplifiedDataCollectionFlow({super.key, this.initialFarmData});

  @override
  State<SimplifiedDataCollectionFlow> createState() =>
      _SimplifiedDataCollectionFlowState();
}

class _SimplifiedDataCollectionFlowState
    extends State<SimplifiedDataCollectionFlow> {
  final FarmDataController _controller = FarmDataController();
  final ClimateService _climateService = ClimateService();

  FarmBasicsModel? _farmBasics;
  SoilQualityModel? _soilQuality;
  ClimateDataModel? _climateData;

  int _currentStep = 0;
  bool _isLoadingClimate = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data if editing
    if (widget.initialFarmData != null) {
      _farmBasics = widget.initialFarmData!.farmBasics;
      _soilQuality = widget.initialFarmData!.soilQuality;
      _climateData = widget.initialFarmData!.climateData;
    }
  }

  void _onFarmBasicsSaved(FarmBasicsModel farmBasics) async {
    setState(() {
      _farmBasics = farmBasics;
      _isLoadingClimate = true;
    });

    // Fetch climate data in background
    try {
      print('🌍 Fetching climate data for predictions...');
      final climate = await _climateService.getClimateDataWithFallback(
        latitude: farmBasics.location.latitude,
        longitude: farmBasics.location.longitude,
        state: farmBasics.location.state,
      );

      setState(() {
        _climateData = climate;
        _isLoadingClimate = false;
      });
    } catch (e) {
      print('❌ Error fetching climate: $e');
      setState(() {
        _isLoadingClimate = false;
      });
    }

    // Move to next step
    setState(() {
      _currentStep = 1;
    });
  }

  void _onSoilQualitySaved(SoilQualityModel soilQuality) async {
    setState(() {
      _soilQuality = soilQuality;
      _isSaving = true;
    });

    try {
      // Create complete farm data model
      final farmData = FarmDataModel(
        userId: '', // Will be set by controller
        farmBasics: _farmBasics!,
        soilQuality: _soilQuality!,
        climateData: _climateData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      await _controller.saveFarmData(farmData);

      if (!mounted) return;

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialFarmData != null
                ? '✅ Farm data updated successfully!'
                : '✅ Farm data saved successfully!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to profile or home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2D5016)),
              const SizedBox(height: 24),
              Text(
                widget.initialFarmData != null
                    ? 'Updating your farm data...'
                    : 'Saving your farm data...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saving to your profile',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('Farm Data Collection'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D5016)),
          ),
          Container(
            color: const Color(0xFFF8F6F0),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(1, 'Farm Basics', _currentStep >= 0),
                Container(
                  width: 40,
                  height: 2,
                  color: _currentStep >= 1
                      ? const Color(0xFF2D5016)
                      : Colors.grey.shade300,
                ),
                _buildStepIndicator(2, 'Soil Quality', _currentStep >= 1),
              ],
            ),
          ),
          const Divider(height: 1),

          // Climate loading indicator
          if (_isLoadingClimate)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D5016),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fetching climate data from NASA POWER API...',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // Step content
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                // Step 1: Farm Basics
                FarmBasicsScreen(
                  initialData: _farmBasics,
                  onSave: _onFarmBasicsSaved,
                ),

                // Step 2: Soil Quality
                if (_farmBasics != null)
                  SimplifiedSoilQualityScreen(
                    farmBasics: _farmBasics!,
                    initialData: _soilQuality,
                    onSave: _onSoilQualitySaved,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF2D5016) : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF2D5016) : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
