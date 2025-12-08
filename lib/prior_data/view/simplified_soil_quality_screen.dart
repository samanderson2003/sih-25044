import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../model/farm_data_model.dart';
import '../controller/soil_satellite_service.dart';
import '../../services/soil_report_ocr_service.dart';

/// Step 2: Soil Quality - Only 6 essential micronutrients for ML model
/// Simplified from 16 fields to 6 critical nutrients
class SimplifiedSoilQualityScreen extends StatefulWidget {
  final FarmBasicsModel farmBasics;
  final SoilQualityModel? initialData;
  final Function(SoilQualityModel) onSave;

  const SimplifiedSoilQualityScreen({
    super.key,
    required this.farmBasics,
    this.initialData,
    required this.onSave,
  });

  @override
  State<SimplifiedSoilQualityScreen> createState() =>
      _SimplifiedSoilQualityScreenState();
}

class _SimplifiedSoilQualityScreenState
    extends State<SimplifiedSoilQualityScreen> {
  final _formKey = GlobalKey<FormState>();
  final SoilSatelliteService _satelliteService = SoilSatelliteService();
  final ImagePicker _imagePicker = ImagePicker();

  // Only 6 micronutrients needed for ML model
  final _zincController = TextEditingController();
  final _ironController = TextEditingController();
  final _copperController = TextEditingController();
  final _manganeseController = TextEditingController();
  final _boronController = TextEditingController();
  final _sulfurController = TextEditingController();

  String _dataSource = 'manual';
  bool _skipSoilTest = false;
  bool _isProcessingImage = false;
  File? _uploadedImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.initialData!;
    _zincController.text = data.zinc?.toString() ?? '';
    _ironController.text = data.iron?.toString() ?? '';
    _copperController.text = data.copper?.toString() ?? '';
    _manganeseController.text = data.manganese?.toString() ?? '';
    _boronController.text = data.boron?.toString() ?? '';
    _sulfurController.text = data.sulfur?.toString() ?? '';
    _dataSource = data.dataSource;
  }

  void _loadRegionalDefaults() async {
    // Show loading indicator
    setState(() {
      _dataSource = 'satellite';
    });

    try {
      // Fetch satellite data based on actual location coordinates
      final satelliteData = await _satelliteService.getSoilDataForLocation(
        latitude: widget.farmBasics.location.latitude,
        longitude: widget.farmBasics.location.longitude,
        state: widget.farmBasics.location.state,
      );

      if (!mounted) return;

      setState(() {
        _zincController.text = satelliteData.zinc?.toStringAsFixed(1) ?? '';
        _ironController.text = satelliteData.iron?.toStringAsFixed(1) ?? '';
        _copperController.text = satelliteData.copper?.toStringAsFixed(1) ?? '';
        _manganeseController.text =
            satelliteData.manganese?.toStringAsFixed(1) ?? '';
        _boronController.text = satelliteData.boron?.toStringAsFixed(1) ?? '';
        _sulfurController.text = satelliteData.sulfur?.toStringAsFixed(2) ?? '';
        _dataSource = 'satellite';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.satellite_alt, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Satellite data loaded for location (${widget.farmBasics.location.latitude.toStringAsFixed(3)}, ${widget.farmBasics.location.longitude.toStringAsFixed(3)}). Update with lab test for accuracy.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error loading satellite data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Upload and process soil test report image
  Future<void> _uploadLabReport(ImageSource source) async {
    try {
      // Check if API key is configured
      if (!SoilReportOCRService.isConfigured()) {
        if (!mounted) return;
        _showApiKeyDialog();
        return;
      }

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessingImage = true;
        _uploadedImage = File(pickedFile.path);
      });

      if (!mounted) return;

      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2D5016)),
              const SizedBox(height: 16),
              const Text(
                'Analyzing soil test report...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Using AI to extract nutrient values',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );

      // Extract soil data from image
      final extractedData = await SoilReportOCRService.extractSoilData(
        File(pickedFile.path),
      );

      if (!mounted) return;

      // Close processing dialog
      Navigator.of(context).pop();

      if (extractedData != null && extractedData.isNotEmpty) {
        // Fill in the extracted values
        setState(() {
          if (extractedData.containsKey('zinc')) {
            _zincController.text = extractedData['zinc']!.toStringAsFixed(1);
          }
          if (extractedData.containsKey('iron')) {
            _ironController.text = extractedData['iron']!.toStringAsFixed(1);
          }
          if (extractedData.containsKey('copper')) {
            _copperController.text = extractedData['copper']!.toStringAsFixed(
              1,
            );
          }
          if (extractedData.containsKey('manganese')) {
            _manganeseController.text = extractedData['manganese']!
                .toStringAsFixed(1);
          }
          if (extractedData.containsKey('boron')) {
            _boronController.text = extractedData['boron']!.toStringAsFixed(1);
          }
          if (extractedData.containsKey('sulfur')) {
            _sulfurController.text = extractedData['sulfur']!.toStringAsFixed(
              2,
            );
          }
          _dataSource = 'lab_report';
          _isProcessingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Lab report analyzed! ${extractedData.length} nutrients extracted. Please verify values.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _isProcessingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Could not extract data from image. Please enter values manually.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessingImage = false;
      });

      if (!mounted) return;

      // Close processing dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      String errorMessage = 'Error processing image';
      if (e.toString().contains('API key')) {
        errorMessage =
            'Invalid API key. Please configure OpenAI API key in the app.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show dialog to configure API key
  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Required'),
        content: const Text(
          'To use AI-powered lab report extraction, you need to configure your OpenAI API key.\n\n'
          '1. Get your API key from: https://platform.openai.com/api-keys\n'
          '2. Open lib/services/soil_report_ocr_service.dart\n'
          '3. Replace YOUR_OPENAI_API_KEY_HERE with your actual key\n\n'
          'Alternatively, you can enter values manually or use satellite data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Upload Soil Test Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'AI will extract nutrient values automatically',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2D5016)),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture soil test report'),
              onTap: () {
                Navigator.pop(context);
                _uploadLabReport(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF2D5016),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing image'),
              onTap: () {
                Navigator.pop(context);
                _uploadLabReport(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _saveData() {
    // If skipping soil test, use satellite/regional defaults
    if (_skipSoilTest) {
      final defaults = SoilQualityModel.withDefaults(
        widget.farmBasics.location.state,
      );
      // Override dataSource to 'satellite' to track this
      final satelliteData = SoilQualityModel(
        zinc: defaults.zinc,
        iron: defaults.iron,
        copper: defaults.copper,
        manganese: defaults.manganese,
        boron: defaults.boron,
        sulfur: defaults.sulfur,
        dataSource: 'satellite',
        fetchedAt: DateTime.now(),
      );
      widget.onSave(satelliteData);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final soilQuality = SoilQualityModel(
      zinc: _zincController.text.isNotEmpty
          ? double.parse(_zincController.text)
          : null,
      iron: _ironController.text.isNotEmpty
          ? double.parse(_ironController.text)
          : null,
      copper: _copperController.text.isNotEmpty
          ? double.parse(_copperController.text)
          : null,
      manganese: _manganeseController.text.isNotEmpty
          ? double.parse(_manganeseController.text)
          : null,
      boron: _boronController.text.isNotEmpty
          ? double.parse(_boronController.text)
          : null,
      sulfur: _sulfurController.text.isNotEmpty
          ? double.parse(_sulfurController.text)
          : null,
      dataSource: _dataSource,
      fetchedAt: DateTime.now(),
    );

    widget.onSave(soilQuality);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),

            // Section title
            _buildSectionTitle('🧪 Micronutrients'),
            const SizedBox(height: 8),
            Text(
              'Enter values from your soil test report or use regional defaults',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Satellite data warning
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Satellite data is estimated. For best predictions, use actual soil test report.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadRegionalDefaults,
                    icon: const Icon(Icons.satellite_alt),
                    label: const Text('Use Satellite Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.orange.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Upload Lab Report Button (NEW)
            ElevatedButton.icon(
              onPressed: _isProcessingImage ? null : _showImageSourceDialog,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Lab Report (AI Extract)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Show uploaded image preview
            if (_uploadedImage != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.file(
                            _uploadedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                _uploadedImage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Lab report uploaded & processed',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _skipSoilTest,
                onChanged: (value) {
                  setState(() {
                    _skipSoilTest = value ?? false;
                  });
                },
                title: Row(
                  children: [
                    const Text('Skip soil test'),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.satellite_alt,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Use satellite/regional data (less accurate)',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // Soil nutrients section
            if (!_skipSoilTest) ...[
              _buildNutrientField(
                controller: _zincController,
                label: 'Zinc (Zn)',
                icon: Icons.science,
                hint: 'e.g., 80',
              ),
              const SizedBox(height: 16),
              _buildNutrientField(
                controller: _ironController,
                label: 'Iron (Fe)',
                icon: Icons.science,
                hint: 'e.g., 94',
              ),
              const SizedBox(height: 16),
              _buildNutrientField(
                controller: _copperController,
                label: 'Copper (Cu)',
                icon: Icons.science,
                hint: 'e.g., 90',
              ),
              const SizedBox(height: 16),
              _buildNutrientField(
                controller: _manganeseController,
                label: 'Manganese (Mn)',
                icon: Icons.science,
                hint: 'e.g., 97',
              ),
              const SizedBox(height: 16),
              _buildNutrientField(
                controller: _boronController,
                label: 'Boron (B)',
                icon: Icons.science,
                hint: 'e.g., 98',
              ),
              const SizedBox(height: 16),
              _buildNutrientField(
                controller: _sulfurController,
                label: 'Sulfur (S)',
                icon: Icons.science,
                hint: 'e.g., 0.7',
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _skipSoilTest
                      ? 'Continue with Satellite Data →'
                      : 'Save to Profile →',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/main');
                  },
                  child: Text(
                    'Set Profile Later',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D5016),
      ),
    );
  }

  Widget _buildNutrientField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2D5016)),
        suffixText: '%',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Optional field
        }
        final num = double.tryParse(value);
        if (num == null || num < 0) {
          return 'Invalid value';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _zincController.dispose();
    _ironController.dispose();
    _copperController.dispose();
    _manganeseController.dispose();
    _boronController.dispose();
    _sulfurController.dispose();
    super.dispose();
  }
}
