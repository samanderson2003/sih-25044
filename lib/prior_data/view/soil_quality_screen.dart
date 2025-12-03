// lib/crop_yield_prediction/view/soil_quality_screen.dart

import 'package:flutter/material.dart';
import '../controller/farm_data_controller.dart';
import '../model/farm_data_model.dart';
import 'soil_test_centers_screen.dart';

class SoilQualityScreen extends StatefulWidget {
  final LandDetailsModel landDetails;
  final SoilQualityModel? existingData;

  const SoilQualityScreen({
    super.key,
    required this.landDetails,
    this.existingData,
  });

  @override
  State<SoilQualityScreen> createState() => _SoilQualityScreenState();
}

class _SoilQualityScreenState extends State<SoilQualityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = FarmDataController();

  // Controllers for all soil parameters
  final _zincController = TextEditingController();
  final _ironController = TextEditingController();
  final _copperController = TextEditingController();
  final _manganeseController = TextEditingController();
  final _boronController = TextEditingController();
  final _sulfurController = TextEditingController();
  final _phController = TextEditingController();
  final _organicCarbonController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();

  String? _soilType;
  String _dataSource = 'manual';
  bool _isLoadingSatelliteData = false;

  // Theme colors
  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
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

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    _zincController.text = data.zinc?.toString() ?? '';
    _ironController.text = data.iron?.toString() ?? '';
    _copperController.text = data.copper?.toString() ?? '';
    _manganeseController.text = data.manganese?.toString() ?? '';
    _boronController.text = data.boron?.toString() ?? '';
    _sulfurController.text = data.sulfur?.toString() ?? '';
    _phController.text = data.ph?.toString() ?? '';
    _organicCarbonController.text = data.organicCarbon?.toString() ?? '';
    _nitrogenController.text = data.nitrogen?.toString() ?? '';
    _phosphorusController.text = data.phosphorus?.toString() ?? '';
    _potassiumController.text = data.potassium?.toString() ?? '';
    _soilType = data.soilType;
    _dataSource = data.dataSource;
  }

  Future<void> _loadSatelliteData() async {
    setState(() => _isLoadingSatelliteData = true);

    try {
      final satelliteData = await _controller.getSoilDataFromSatellite(
        widget.landDetails.location.latitude,
        widget.landDetails.location.longitude,
      );

      setState(() => _isLoadingSatelliteData = false);

      if (satelliteData != null && mounted) {
        // Show disclaimer dialog
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 8),
                Expanded(child: Text('Satellite Data Disclaimer')),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satellite-based soil data provides estimates:\n',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text('✅ RELIABLE (70-85% accuracy):'),
                  Text('  • pH level', style: TextStyle(fontSize: 13)),
                  Text('  • Organic carbon', style: TextStyle(fontSize: 13)),
                  Text('  • Soil texture\n', style: TextStyle(fontSize: 13)),
                  Text('⚠️ ESTIMATED (50-70% accuracy):'),
                  Text(
                    '  • Micronutrients (Zn, Fe, Cu, Mn, B, S)',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '  • Based on soil properties\n',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text('❌ NOT AVAILABLE:'),
                  Text(
                    '  • Available Phosphorus (P)',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '  • Available Potassium (K)\n',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    'For accurate crop planning, we STRONGLY recommend:\n'
                    '• Getting soil tested at a certified lab\n'
                    '• Updating these values with actual results\n'
                    '• Using satellite data only temporarily\n\n'
                    'Proceed with satellite estimates?',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Use Estimates'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          _fillSatelliteData(satelliteData);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to fetch satellite data. Please try again or enter manually.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingSatelliteData = false);
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

  void _fillSatelliteData(SoilQualityModel data) {
    setState(() {
      _zincController.text = data.zinc?.toStringAsFixed(2) ?? '';
      _ironController.text = data.iron?.toStringAsFixed(2) ?? '';
      _copperController.text = data.copper?.toStringAsFixed(2) ?? '';
      _manganeseController.text = data.manganese?.toStringAsFixed(2) ?? '';
      _boronController.text = data.boron?.toStringAsFixed(2) ?? '';
      _sulfurController.text = data.sulfur?.toStringAsFixed(2) ?? '';
      _phController.text = data.ph?.toStringAsFixed(1) ?? '';
      _organicCarbonController.text =
          data.organicCarbon?.toStringAsFixed(2) ?? '';
      _nitrogenController.text = data.nitrogen?.toStringAsFixed(0) ?? '';
      _phosphorusController.text = data.phosphorus?.toStringAsFixed(0) ?? '';
      _potassiumController.text = data.potassium?.toStringAsFixed(0) ?? '';
      _soilType = data.soilType;
      _dataSource = 'satellite';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Satellite data loaded. Please update with lab results when available.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _viewTestCenters() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoilTestCentersScreen(
          latitude: widget.landDetails.location.latitude,
          longitude: widget.landDetails.location.longitude,
        ),
      ),
    );
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;

    final soilData = SoilQualityModel(
      zinc: double.tryParse(_zincController.text),
      iron: double.tryParse(_ironController.text),
      copper: double.tryParse(_copperController.text),
      manganese: double.tryParse(_manganeseController.text),
      boron: double.tryParse(_boronController.text),
      sulfur: double.tryParse(_sulfurController.text),
      soilType: _soilType,
      ph: double.tryParse(_phController.text),
      organicCarbon: double.tryParse(_organicCarbonController.text),
      nitrogen: double.tryParse(_nitrogenController.text),
      phosphorus: double.tryParse(_phosphorusController.text),
      potassium: double.tryParse(_potassiumController.text),
      dataSource: _dataSource,
      isAccurate: _dataSource != 'satellite',
      testDate: DateTime.now(),
    );

    Navigator.pop(context, soilData);
  }

  @override
  void dispose() {
    _zincController.dispose();
    _ironController.dispose();
    _copperController.dispose();
    _manganeseController.dispose();
    _boronController.dispose();
    _sulfurController.dispose();
    _phController.dispose();
    _organicCarbonController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Soil Quality Data'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Step 2 of 4',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.5,
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
                    const Text(
                      'How would you like to provide soil data?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionCard(
                            icon: Icons.location_searching,
                            title: 'Satellite',
                            subtitle: 'Quick estimate',
                            onTap: _loadSatelliteData,
                            isLoading: _isLoadingSatelliteData,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOptionCard(
                            icon: Icons.map_outlined,
                            title: 'Test Centers',
                            subtitle: 'Find nearby labs',
                            onTap: _viewTestCenters,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Soil Parameters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the values from your soil test report',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _soilType,
                      decoration: _inputDecoration('Soil Type*'),
                      items: _soilTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _soilType = value),
                      validator: (value) =>
                          value == null ? 'Please select soil type' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Micronutrients (%)'),
                    _buildParameterRow(
                      _zincController,
                      _ironController,
                      'Zinc (Zn)*',
                      'Iron (Fe)*',
                    ),
                    _buildParameterRow(
                      _copperController,
                      _manganeseController,
                      'Copper (Cu)*',
                      'Manganese (Mn)*',
                    ),
                    _buildParameterRow(
                      _boronController,
                      _sulfurController,
                      'Boron (B)*',
                      'Sulfur (S)*',
                    ),

                    const SizedBox(height: 16),

                    _buildSectionHeader('Macronutrients (kg/ha)'),
                    _buildParameterRow(
                      _nitrogenController,
                      _phosphorusController,
                      'Nitrogen (N)',
                      'Phosphorus (P)',
                    ),
                    _buildSingleParameter(
                      _potassiumController,
                      'Potassium (K)',
                    ),

                    const SizedBox(height: 16),

                    _buildSectionHeader('Other Parameters'),
                    _buildParameterRow(
                      _phController,
                      _organicCarbonController,
                      'pH Level',
                      'Organic Carbon (%)',
                    ),

                    if (_dataSource == 'satellite') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using satellite data. Please update with lab results.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

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
                  'Next: Past Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildParameterRow(
    TextEditingController controller1,
    TextEditingController controller2,
    String label1,
    String label2,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller1,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(label1),
              validator: label1.contains('*')
                  ? (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid';
                      return null;
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller2,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(label2),
              validator: label2.contains('*')
                  ? (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid';
                      return null;
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleParameter(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
