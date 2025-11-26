import 'package:flutter/material.dart';
import '../controller/farm_data_controller.dart';
import '../model/farm_data_model.dart';

class LandDetailsScreen extends StatefulWidget {
  final LandDetailsModel? existingData;

  const LandDetailsScreen({super.key, this.existingData});

  @override
  State<LandDetailsScreen> createState() => _LandDetailsScreenState();
}

class _LandDetailsScreenState extends State<LandDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = FarmDataController();

  final _landSizeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _landSizeUnit = 'acres';
  String? _soilType;
  String? _irrigationType;
  String? _landTopography;

  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Theme colors
  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  static const accentColor = Color(0xFF6B8E23);
  static const textColor = Color(0xFF4A4A4A);

  final List<String> _soilTypes = [
    'Sandy',
    'Loamy',
    'Clay',
    'Silt',
    'Peaty',
    'Chalky',
    'Saline',
  ];

  final List<String> _irrigationTypes = [
    'Drip Irrigation',
    'Sprinkler',
    'Surface/Flood',
    'Sub-surface',
    'Rainfed',
  ];

  final List<String> _topographyTypes = [
    'Flat',
    'Gently Sloping',
    'Moderately Sloping',
    'Hilly',
    'Terraced',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    _landSizeController.text = data.landSize.toString();
    _landSizeUnit = data.landSizeUnit;
    _soilType = data.soilType;
    _irrigationType = data.irrigationType;
    _landTopography = data.landTopography;
    _latitude = data.location.latitude;
    _longitude = data.location.longitude;
    _addressController.text = data.location.address ?? '';
    _cityController.text = data.location.city ?? '';
    _stateController.text = data.location.state ?? '';
    _pincodeController.text = data.location.pincode ?? '';
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _controller.getCurrentLocation();

      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoadingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location captured successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission not granted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your farm location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final landDetails = LandDetailsModel(
      landSize: double.parse(_landSizeController.text),
      landSizeUnit: _landSizeUnit,
      location: LocationModel(
        latitude: _latitude!,
        longitude: _longitude!,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
        isManuallyMarked: true,
      ),
      soilType: _soilType,
      irrigationType: _irrigationType,
      landTopography: _landTopography,
    );

    // Return the data back to welcome screen
    Navigator.pop(context, landDetails);
  }

  @override
  void dispose() {
    _landSizeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Land Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            color: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Step 1 of 4',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.25,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Land Size
                    const Text(
                      'Land Size',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _landSizeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter size',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _landSizeUnit,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: ['acres', 'hectares']
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _landSizeUnit = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    const Text(
                      'Farm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // GPS Capture Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _latitude != null
                            ? Colors.green.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _latitude != null
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _latitude != null
                                    ? Icons.check_circle
                                    : Icons.my_location,
                                color: _latitude != null
                                    ? Colors.green
                                    : primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _latitude != null
                                          ? 'Location Captured'
                                          : 'Capture GPS Location',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _latitude != null
                                            ? Colors.green.shade700
                                            : textColor,
                                      ),
                                    ),
                                    if (_latitude != null)
                                      Text(
                                        'Lat: ${_latitude!.toStringAsFixed(6)}, '
                                        'Long: ${_longitude!.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor.withOpacity(0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_isLoadingLocation)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _getCurrentLocation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    _latitude != null ? 'Recapture' : 'Capture',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address fields (optional)
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address (Optional)',
                        hintText: 'Enter farm address',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: 'City (Optional)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              labelText: 'State (Optional)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Pincode (Optional)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Additional Land Details
                    const Text(
                      'Additional Details (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _soilType,
                      decoration: InputDecoration(
                        labelText: 'Soil Type',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _soilTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _soilType = value),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _irrigationType,
                      decoration: InputDecoration(
                        labelText: 'Irrigation Type',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _irrigationTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _irrigationType = value),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _landTopography,
                      decoration: InputDecoration(
                        labelText: 'Land Topography',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _topographyTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _landTopography = value),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next button
          Container(
            padding: const EdgeInsets.all(24),
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next: Soil Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
