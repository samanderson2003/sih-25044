import 'package:flutter/material.dart';
import '../model/new_crop_yield_model.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../prior_data/view/map_location_picker.dart';
import '../../services/ml_api_service.dart';
import '../../services/auto_farm_data_service.dart';
import '../../services/openai_service.dart';
import '../../widgets/translated_text.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import 'indian_crop_selection_screen.dart';

class NewCropYieldScreen extends StatefulWidget {
  const NewCropYieldScreen({super.key});

  @override
  State<NewCropYieldScreen> createState() => _NewCropYieldScreenState();
}

class _NewCropYieldScreenState extends State<NewCropYieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final FarmDataController _farmDataController = FarmDataController();
  final AutoFarmDataService _autoDataService = AutoFarmDataService();

  bool _isLoading = false;
  AgriAIResponse? _predictionResult;
  Map<String, List<ProductRecommendation>>? _aiRecommendations;
  bool _isLoadingRecommendations = false;

  // Location data
  double? _latitude;
  double? _longitude;
  String? _selectedDistrict;
  String _displayAddress = 'Tap to select location';

  // Address entry controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  bool _isGeocodingAddress = false;

  // Form controllers
  final TextEditingController _soilTypeController = TextEditingController();
  final TextEditingController _rainController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _socController = TextEditingController(
    text: '0.5',
  );
  final TextEditingController _ndviController = TextEditingController(
    text: '0.6',
  );
  final TextEditingController _ndviAnomalyController = TextEditingController(
    text: '0.0',
  );
  final TextEditingController _eviController = TextEditingController(
    text: '4000.0',
  );
  final TextEditingController _lstController = TextEditingController(
    text: '30.0',
  );
  final TextEditingController _elevationController = TextEditingController(
    text: '100.0',
  );
  final TextEditingController _dryWetIndexController = TextEditingController(
    text: '10.0',
  );

  final List<String> _soilTypes = [
    'Clay Loam',
    'Sandy Loam',
    'Clay',
    'Sandy Clay',
    'Sandy Clay Loam',
    'Loam',
    'Silt Loam',
  ];

  String _selectedSoilType = 'Clay Loam';

  @override
  void initState() {
    super.initState();
    _loadFarmDataFromProfile();
  }

  Future<void> _loadFarmDataFromProfile() async {
    try {
      final farmData = await _farmDataController.getFarmData();
      if (farmData != null && mounted) {
        setState(() {
          // Load location if available
          final location = farmData.farmBasics.location;
          _latitude = location.latitude;
          _longitude = location.longitude;
          _selectedDistrict = location.district;
          _displayAddress = location.district != null && location.state != null
              ? '${location.district}, ${location.state}'
              : 'Location loaded'; // This might need dynamic translation if used in UI directly

          // Load area
          _areaController.text = farmData.farmBasics.landSize.toString();
        });

        // Auto-fetch data if location is available
        if (_latitude != null && _longitude != null) {
          _autoFetchDataFromLocation(_latitude!, _longitude!);
        }
      } else {
        // Set default values
        setState(() {
          _soilTypeController.text = _selectedSoilType;
          _rainController.text = '1400';
          _tempController.text = '27.0';
          _phController.text = '6.5';
          _areaController.text = '2.0';
        });
      }
    } catch (e) {
      print('Error loading farm data: $e');
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _soilTypeController.dispose();
    _rainController.dispose();
    _tempController.dispose();
    _phController.dispose();
    _areaController.dispose();
    _socController.dispose();
    _ndviController.dispose();
    _ndviAnomalyController.dispose();
    _eviController.dispose();
    _lstController.dispose();
    _elevationController.dispose();
    _dryWetIndexController.dispose();
    super.dispose();
  }

  Future<void> _submitPrediction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      // Validate location
      if (_selectedDistrict == null) {
        throw Exception('Please select a location first');
      }

      // Prepare input data matching AgriAIInput model
      final input = AgriAIInput(
        district: _selectedDistrict!,
        soilType: _selectedSoilType,
        rainMm: double.parse(_rainController.text),
        tempC: double.parse(_tempController.text),
        ph: double.parse(_phController.text),
        areaAcres: double.parse(_areaController.text),
        soc: double.parse(_socController.text),
        ndviMax: double.parse(_ndviController.text),
        ndviAnomaly: double.parse(_ndviAnomalyController.text),
        eviMax: double.parse(_eviController.text),
        lst: double.parse(_lstController.text),
        elevation: double.parse(_elevationController.text),
        dryWetIndex: double.parse(_dryWetIndexController.text),
      );

      // Call ML API
      final response = await MLApiService.getAgriAIRecommendations(
        farmInput: input.toJson(),
      );

      if (response == null) {
        throw Exception('Failed to get response from API');
      }

      final result = AgriAIResponse.fromJson(response);

      setState(() {
        _predictionResult = result;
        _isLoading = false;
      });

      // Auto-load AI recommendations for top crop
      if (result.crops.isNotEmpty) {
        _load10PercentYieldGuide(result.crops.first);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Prediction Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load static 10% yield improvement guide for Rice
  Future<void> _load10PercentYieldGuide(CropRecommendation topCrop) async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    // Simulate brief loading for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    // Static rice farming recommendations
    final recommendations = {
      'pestControl': [
        ProductRecommendation(
          productName: 'Fipronil 0.3% GR',
          governmentScheme: 'General Market',
          description:
              'Controls stem borer, hopper, hispa and other soil pests. Apply 7 kg/ha as soil-applied granule or seed treatment.',
          applicationMethod: 'Soil/seed application at planting time',
          imageFilename: 'pest.png',
          estimatedCost: '₹450-600/ha',
        ),
        ProductRecommendation(
          productName: 'Flubendiamide 480 SC',
          governmentScheme: 'General Market',
          description:
              'Effective against stem borer and leaf folder. Provides long-lasting protection with low application rates.',
          applicationMethod: 'Foliar spray at 70 g/ha during pest appearance',
          imageFilename: 'pest.png',
          estimatedCost: '₹800-1000/ha',
        ),
        ProductRecommendation(
          productName: 'Trichogramma chilonis (Bio-agent)',
          governmentScheme: 'ICAR-NRRI, Cuttack, Odisha',
          description:
              'Eco-friendly egg parasitoid that reduces insecticide use. Natural pest control for sustainable farming.',
          applicationMethod:
              'Release 3 Trichocards/ha initially, repeat as needed',
          imageFilename: 'pest.png',
          estimatedCost: '₹200-300/ha',
        ),
      ],
      'fertilizer': [
        ProductRecommendation(
          productName: 'Urea (Nitrogen)',
          governmentScheme: 'Tamil Nadu Government Subsidy',
          description:
              'Essential nitrogen source for growth, green leaves, and tillering. Most important fertilizer for rice cultivation.',
          applicationMethod:
              'Apply in 2-3 splits: Basal, tillering, and panicle initiation stages',
          imageFilename: 'fert.png',
          estimatedCost: '₹266/bag (45kg) - Subsidized',
        ),
        ProductRecommendation(
          productName: 'DAP (Diammonium Phosphate)',
          governmentScheme: 'Tamil Nadu Government Subsidy',
          description:
              'Provides phosphorus for strong root development and panicle formation. Critical during early growth stages.',
          applicationMethod:
              'Apply as basal dose during land preparation at 100 kg/ha',
          imageFilename: 'fert.png',
          estimatedCost: '₹1,350/bag (50kg) - Subsidized',
        ),
        ProductRecommendation(
          productName: 'MOP (Muriate of Potash)',
          governmentScheme: 'General Market',
          description:
              'Improves grain filling and prevents lodging. Enhances disease resistance and grain quality.',
          applicationMethod:
              'Apply 60 kg/ha in 2 splits: half at transplanting, half at panicle initiation',
          imageFilename: 'fert.png',
          estimatedCost: '₹1,600-1,800/bag (50kg)',
        ),
        ProductRecommendation(
          productName: 'Zinc Sulphate (ZnSO₄)',
          governmentScheme: 'General Market',
          description:
              'Prevents Khaira disease (zinc deficiency), very common in rice. Essential micronutrient for healthy growth.',
          applicationMethod:
              'Apply 25 kg/ha mixed with sand or soil before transplanting',
          imageFilename: 'fert.png',
          estimatedCost: '₹40-60/kg',
        ),
      ],
      'irrigation': [
        ProductRecommendation(
          productName: 'Flood Irrigation System',
          governmentScheme: 'Traditional Method - Odisha',
          description:
              'Traditional flooding method for rice cultivation. Maintain 5-10 cm standing water during most growth stages. Drain before harvest.',
          applicationMethod:
              'Flood the field after transplanting and maintain water levels throughout growth period',
          imageFilename: 'flood.png',
          estimatedCost: 'Variable - depends on water source',
        ),
        ProductRecommendation(
          productName: 'Drip Irrigation (Water-saving)',
          governmentScheme: 'Pradhan Mantri Krishi Sinchayee Yojana (PMKSY)',
          description:
              'Modern water-efficient method. Delivers water directly to roots, reducing wastage by 40-50%. Can increase yield by 20-30%.',
          applicationMethod:
              'Install drip lines before planting. Water daily based on crop stage and weather',
          imageFilename: 'flood.png',
          estimatedCost: '₹45,000-60,000/ha (90% subsidy available)',
        ),
        ProductRecommendation(
          productName: 'Alternate Wetting and Drying (AWD)',
          governmentScheme: 'IRRI-Recommended Practice',
          description:
              'Saves water by 15-30% without reducing yield. Alternate between flooded and non-flooded conditions based on soil moisture.',
          applicationMethod:
              'Allow water to dry for 1-2 days, then re-flood. Use field water tube to monitor',
          imageFilename: 'flood.png',
          estimatedCost: 'No additional cost - water management practice',
        ),
      ],
    };

    setState(() {
      _aiRecommendations = recommendations;
      _isLoadingRecommendations = false;
    });

    print('✅ Static Rice Recommendations loaded successfully');
  }

  /// Auto-fetch ALL data from a specific location
  Future<void> _autoFetchDataFromLocation(double lat, double lon) async {
    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '📡 Fetching Data...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TranslatedText('Weather → Soil → Satellite'),
              ],
            ),
          ),
        );
      }

      // Get all data automatically for this location
      final farmData = await _autoDataService.getCompleteFarmData(
        customLat: lat,
        customLon: lon,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Fill form with fetched data
      setState(() {
        _selectedDistrict = farmData['district'] ?? 'Unknown';
        _selectedSoilType = farmData['soil_type'] ?? 'Clay Loam';
        _rainController.text = farmData['rain_mm'].toStringAsFixed(0);
        _tempController.text = farmData['temp_c'].toStringAsFixed(1);
        _phController.text = farmData['ph'].toStringAsFixed(1);
        _socController.text = farmData['soc'].toStringAsFixed(2);
        _ndviController.text = farmData['ndvi_max'].toStringAsFixed(2);
        _ndviAnomalyController.text = farmData['ndvi_anomaly'].toStringAsFixed(
          2,
        );
        _eviController.text = farmData['evi_max'].toStringAsFixed(1);
        _lstController.text = farmData['lst'].toStringAsFixed(1);
        _elevationController.text = farmData['elevation'].toStringAsFixed(1);
        _dryWetIndexController.text = farmData['dry_wet_index'].toStringAsFixed(
          1,
        );
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data auto-filled from satellite & weather APIs'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Auto-fetch failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Open map picker for location selection
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.coordinates.latitude;
        _longitude = result.coordinates.longitude;
        _selectedDistrict = result.district;
        _displayAddress = result.district != null && result.state != null
            ? '${result.district}, ${result.state}'
            : 'Location selected';

        // Update address fields if available
        if (result.address != null) _addressController.text = result.address!;
        if (result.city != null) _cityController.text = result.city!;
        if (result.state != null) _stateController.text = result.state!;
        if (result.pincode != null) _pincodeController.text = result.pincode!;
      });

      // Auto-fetch all other data
      _autoFetchDataFromLocation(_latitude!, _longitude!);
    }
  }

  /// Find location from manual address entry
  Future<void> _findLocationFromAddress() async {
    // Build complete address string
    String fullAddress = '';
    if (_addressController.text.isNotEmpty) {
      fullAddress += _addressController.text;
    }
    if (_cityController.text.isNotEmpty) {
      fullAddress += ', ${_cityController.text}';
    }
    if (_stateController.text.isNotEmpty) {
      fullAddress += ', ${_stateController.text}';
    }
    if (_pincodeController.text.isNotEmpty) {
      fullAddress += ' ${_pincodeController.text}';
    }

    if (fullAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one address field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeocodingAddress = true;
    });

    try {
      List<Location> locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        final location = locations.first;

        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
          _displayAddress = fullAddress;
          _isGeocodingAddress = false;
        });

        // Auto-fetch all data
        _autoFetchDataFromLocation(_latitude!, _longitude!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Location found! Fetching data...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isGeocodingAddress = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Location not found. Try different address'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isGeocodingAddress = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: _predictionResult == null ? _buildInputForm() : _buildResultsView(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Header - AI Crop Advisor with Indian Crops
            GestureDetector(
              onTap: () {
                // Navigate to Indian crop selection screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IndianCropSelectionScreen(
                      farmData: {
                        'soilType': _selectedSoilType,
                        'ph': double.tryParse(_phController.text) ?? 6.5,
                        'rainfallMm': double.tryParse(_rainController.text) ?? 1200.0,
                        'currentYield': 4.5,
                        'currentCrop': 'Rice',
                        'areaHectares': (double.tryParse(_areaController.text) ?? 1.0) * 0.404686, // Convert acres to hectares
                        'soilOrganic': double.tryParse(_socController.text) ?? 0.5,
                        'district': _selectedDistrict ?? 'Region',
                        'zinc': 0.8,
                        'iron': 0.9,
                        'copper': 0.6,
                        'manganese': 0.85,
                        'boron': 0.5,
                      },
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5016), Color(0xFF4A7C2C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            'AI Crop Advisor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          TranslatedText(
                            'Select crops available only in India',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Location Selection Section
            _buildSectionTitle('📍 Farm Location', Icons.location_on),
            const SizedBox(height: 12),

            // Location Display Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _latitude != null
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _latitude != null
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _latitude != null
                            ? Icons.check_circle
                            : Icons.location_off,
                        color: _latitude != null
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                                _displayAddress,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _latitude != null
                                    ? Colors.green.shade900
                                    : Colors.grey.shade700,
                                fontFamily: 'Roboto', // Avoid issues with some scripts? No, system font is better.
                              ),
                            ),
                            if (_latitude != null && _longitude != null)
                              Text(
                                'Lat: ${_latitude!.toStringAsFixed(6)}, Lon: ${_longitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(Icons.map, size: 18),
                          label: const TranslatedText('Pin on Map'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D5016),
                            side: const BorderSide(color: Color(0xFF2D5016)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Manual Address Entry (Expandable)
            ExpansionTile(
              title: const TranslatedText(
                'Or Enter Address Manually',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _addressController,
                  label: 'Street/Village',
                  hint: 'e.g., MG Road, Sector 5',
                  icon: Icons.home,
                  required: false,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        label: 'City/Taluk',
                        hint: 'e.g., Cuttack',
                        icon: Icons.location_city,
                        required: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _pincodeController,
                        label: 'Pincode',
                        hint: '753001',
                        icon: Icons.pin,
                        keyboardType: TextInputType.number,
                        required: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'e.g., Odisha',
                  icon: Icons.map,
                  required: false,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeocodingAddress
                        ? null
                        : _findLocationFromAddress,
                    icon: _isGeocodingAddress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.search_outlined, size: 20),
                    label: TranslatedText(
                      _isGeocodingAddress ? 'Searching...' : 'Find Location',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5016),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),

            const SizedBox(height: 24),

            // Farm Area Section (User Input)
            _buildSectionTitle('📐 Farm Size', Icons.crop_free),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _areaController,
              label: 'Farm Area (Acres)',
              hint: '2.5',
              icon: Icons.crop_free,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Auto-Fetched Data Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _latitude != null
                        ? TranslatedText(
                            '✅ Data auto-filled from satellite & weather APIs',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : TranslatedText(
                            'Select location to auto-fetch weather, soil & satellite data',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Soil Information Section (Auto-Filled)
            _buildSectionTitle(
              '🌱 Soil Information (Auto-Filled)',
              Icons.terrain,
            ),
            const SizedBox(height: 12),

            _buildDropdown(
              label: 'Soil Type',
              value: _selectedSoilType,
              items: _soilTypes,
              onChanged: (value) {
                setState(() {
                  _selectedSoilType = value!;
                });
              },
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: _phController,
              label: 'Soil pH',
              hint: '6.5',
              icon: Icons.science,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: _socController,
              label: 'Soil Organic Carbon (SOC)',
              hint: '0.5',
              icon: Icons.eco,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Climate Data Section (Auto-Filled)
            _buildSectionTitle('☀️ Climate Data (Auto-Filled)', Icons.wb_sunny),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _rainController,
              label: 'Annual Rainfall (mm)',
              hint: '1400',
              icon: Icons.water_drop,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            _buildTextField(
              controller: _tempController,
              label: 'Average Temperature (°C)',
              hint: '27.0',
              icon: Icons.thermostat,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Advanced Options (Collapsible)
            ExpansionTile(
              title: const TranslatedText(
                'Advanced Satellite Data',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _ndviController,
                        label: 'NDVI Max (Greenness)',
                        hint: '0.6',
                        icon: Icons.grass,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _ndviAnomalyController,
                        label: 'NDVI Anomaly (Pest Alert)',
                        hint: '0.0 (Set < -0.15 for pest)',
                        icon: Icons.bug_report,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _eviController,
                        label: 'EVI Max (Enhanced Vegetation Index)',
                        hint: '4000.0',
                        icon: Icons.eco,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _lstController,
                        label: 'LST (Land Surface Temperature °C)',
                        hint: '30.0',
                        icon: Icons.thermostat_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _elevationController,
                        label: 'Elevation (meters)',
                        hint: '100.0',
                        icon: Icons.terrain,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _dryWetIndexController,
                        label: 'Dry-Wet Index',
                        hint: '10.0',
                        icon: Icons.water_drop,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final result = _predictionResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Animated Success Visual - Seeds → Growth → Money
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D5016).withOpacity(0.1),
                  const Color(0xFF4A7C2C).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Seeds Animation
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/business/seeds.json',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plant',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward,
                  color: Colors.green.shade400,
                  size: 24,
                ),
                // Growth Animation
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/business/growth.json',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward,
                  color: Colors.green.shade400,
                  size: 24,
                ),
                // Money Animation
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/business/Money.json',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Yield Analysis - Simplified
          _buildSimplifiedYieldCard(result.yieldForecast),

          const SizedBox(height: 16),

          // Top Recommended Crops - Most Important Info First
          _buildSectionTitle('🌾 Best Crops for You', Icons.agriculture),
          const SizedBox(height: 12),
          ...result.crops.take(3).map((crop) => _buildSimplifiedCropCard(crop)),

          // Show More Crops (Expandable)
          if (result.crops.length > 3) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'View ${result.crops.length - 3} More Options',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
              children: result.crops
                  .skip(3)
                  .map((crop) => _buildSimplifiedCropCard(crop))
                  .toList(),
            ),
          ],

          const SizedBox(height: 16),

          // AI-Powered 10% Yield Improvement Guide
          _build10PercentYieldGuide(),

          const SizedBox(height: 16),

          // Advisory Plan - Only if needed
          if (result.hasOptimizationActions) ...[
            _buildSectionTitle('💡 Action Required', Icons.lightbulb_outline),
            const SizedBox(height: 12),
            ...result.advisoryPlan.map(
              (action) => _buildSimplifiedAdvisoryCard(action),
            ),
            const SizedBox(height: 16),
          ],

          // Reset Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _predictionResult = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const TranslatedText('New Prediction'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2D5016), width: 2),
                foregroundColor: const Color(0xFF2D5016),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSimplifiedYieldCard(YieldAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: TranslatedText(
                  'Yield Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simplified Yield Display
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      TranslatedText(
                        'Current Yield',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${analysis.currentYieldTonsHa.toStringAsFixed(2)} T/Ha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      TranslatedText(
                        'Potential Yield',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${analysis.potentialYieldTonsHa.toStringAsFixed(2)} T/Ha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedCropCard(CropRecommendation crop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: crop.isGoodMatch
              ? Colors.green.shade200
              : Colors.orange.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: Color(0xFF2D5016),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.variety,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                    Text(
                      crop.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(crop.status, style: const TextStyle(fontSize: 16)),
            ],
          ),

          const SizedBox(height: 12),

          // Key Metrics - Compact Grid
          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  'Yield/Ha',
                  '${crop.predictedYield.toStringAsFixed(2)} T',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactMetric(
                  'Total',
                  '${crop.totalProductionTons.toStringAsFixed(2)} T',
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Revenue - Highlighted
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.currency_rupee,
                  color: Colors.green.shade700,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Estimated Revenue',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${crop.estimatedRevenueInr.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(crop.matchScore * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
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

  Widget _buildCompactMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedAdvisoryCard(OptimizationAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.problem,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSimpleDetailRow(
                  'Recommended',
                  action.details.commercialProduct,
                ),
                const SizedBox(height: 6),
                _buildSimpleDetailRow(
                  'Organic Option',
                  action.details.organicAlternative,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2D5016)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2D5016), size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: TranslatedText(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        label: TranslatedText(label, style: TextStyle(color: Colors.grey.shade700)),
        // labelText: label, // Replaced with widget for translation
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2D5016)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        label: TranslatedText(label, style: TextStyle(color: Colors.grey.shade700)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: TranslatedText(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  /// Build AI-powered 10% Yield Improvement Guide with Tabs
  Widget _build10PercentYieldGuide() {
    if (_isLoadingRecommendations) {
      return Center(
        child: Lottie.asset(
          'assets/loading.json',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
      );
    }

    if (_aiRecommendations == null) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            '🎯 AI Guide: Increase Yield by 10%',
            Icons.analytics,
          ),
          const SizedBox(height: 8),
          Text(
            'Simple steps with pictures to help you grow more',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tab Bar
                TabBar(
                  labelColor: const Color(0xFF2D5016),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF2D5016),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(Icons.bug_report), text: 'Pest Control'),
                    Tab(icon: Icon(Icons.eco), text: 'Fertilizer'),
                    Tab(icon: Icon(Icons.water_drop), text: 'Irrigation'),
                  ],
                ),
                // Tab Views
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    children: [
                      _buildProductTab(
                        _aiRecommendations!['pestControl']!,
                        'Pest Control Product',
                      ),
                      _buildProductTab(
                        _aiRecommendations!['fertilizer']!,
                        'Fertilizer Product',
                      ),
                      _buildProductTab(
                        _aiRecommendations!['irrigation']!,
                        'Irrigation Product',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual product tab with image and details
  Widget _buildProductTab(
    List<ProductRecommendation> products,
    String productType,
  ) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'No recommendations available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2D5016).withOpacity(0.1),
                          const Color(0xFF4A7C2C).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: () {
                        // Determine which static image to show based on product type
                        String fallbackImage;
                        if (productType.contains('Pest')) {
                          fallbackImage = 'assets/prediction/pest.png';
                        } else if (productType.contains('Fertilizer')) {
                          fallbackImage = 'assets/prediction/fert.png';
                        } else {
                          fallbackImage = 'assets/prediction/irrig.png';
                        }

                        return Image.asset(
                          fallbackImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Ultimate fallback if even static images fail
                            return Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey.shade400,
                            );
                          },
                        );
                      }(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Product Name
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(height: 4),

                // Government Scheme Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.governmentScheme,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Description - How it helps
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Application Method
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.checklist,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How to Use:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.applicationMethod,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Cost:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      product.estimatedCost,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
