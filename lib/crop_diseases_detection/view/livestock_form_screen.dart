import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../profile/controller/cattle_controller.dart';
import '../../services/livestock_diagnosis_service.dart';
import '../../profile/model/cattle_model.dart';
import '../../widgets/translated_text.dart';
import '../controller/disease_detection_controller.dart';
import '../../connections/controller/connections_controller.dart';
import 'disease_result_screen.dart';

class LivestockFormScreen extends StatefulWidget {
  const LivestockFormScreen({super.key});

  @override
  State<LivestockFormScreen> createState() => _LivestockFormScreenState();
}

class _LivestockFormScreenState extends State<LivestockFormScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _selectedCattleId;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Fetch cattle data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CattleController>().getCattleStream();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  bool get _canSubmit {
    return _imageFile != null && _selectedCattleId != null;
  }

  Future<void> _submitForm() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select cattle and upload an image')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFCCD2A)),
      ),
    );

    try {
      final service = LivestockDiagnosisService();
      
      // Call new custom DL model service
      final result = await service.diagnoseLivestock(
        imageFile: _imageFile!,
        cattleType: 'Livestock (ID: $_selectedCattleId)', 
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // AUTOMATIC ALERT TRIGGER
        // If a disease is detected (prediction is not "Healthy" or "Invalid"), trigger a map alert
        // Assuming model returns 'Healthy' for healthy animals.
        // We case-insensitive check to be safe.
        final isHealthy = result.predictedClass.toLowerCase() == 'healthy' || 
                          result.predictedClass.toLowerCase() == 'normal';
        
        if (!isHealthy) {
          try {
             final connectionsController = context.read<ConnectionsController>();
             await connectionsController.markRiskAlert(
               'Livestock Disease: ${result.predictedClass}',
               'LivestockDisease',
               15000, // 15 km radius
               imageFile: _imageFile,
               extraData: {
                 'disease': result.predictedClass,
                 'confidence': result.confidence,
               },
             );
             debugPrint('✅ Automatic Livestock Alert Triggered');
          } catch (e) {
             debugPrint('⚠️ Failed to trigger automatic alert: $e');
             // Don't block the result screen even if alert fails
          }
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DiseaseResultScreen(
              result: result,
              imagePath: _imageFile!.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Diagnosis Failed: $e'),
             backgroundColor: Colors.red,
           ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Health Assessment'),
        backgroundColor: const Color(0xFFFCCD2A),
        foregroundColor: Colors.black,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 1) { // 0 -> 1
            setState(() => _currentStep++);
          } else {
            _submitForm();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCCD2A),
                      foregroundColor: Colors.black,
                    ),
                    child: TranslatedText(_currentStep == 1 ? 'Submit' : 'Next'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const TranslatedText('Back', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Cattle Selection
          Step(
            title: const TranslatedText('Select Cattle'),
            content: StreamBuilder<List<CattleModel>>(
              stream: context.read<CattleController>().getCattleStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cattleList = snapshot.data!;
                if (cattleList.isEmpty) {
                  return const TranslatedText('No cattle found. Please add cattle in Profile first.');
                }
                return DropdownButtonFormField<String>(
                  value: _selectedCattleId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: TranslatedText('Choose Animal', style: TextStyle(color: Colors.grey)),
                  ),
                  items: cattleList.map((cattle) {
                    return DropdownMenuItem(
                      value: cattle.id,
                      child: Text('${cattle.breed} (${cattle.type}) - ${cattle.age}y'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCattleId = val),
                );
              },
            ),
            isActive: _currentStep >= 0,
          ),

          // Step 2: Image Upload
          Step(
            title: const TranslatedText('Upload Image'),
            content: Column(
              children: [
                if (_imageFile != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => setState(() => _imageFile = null),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildUploadButton(Icons.camera_alt, 'Camera', ImageSource.camera),
                      _buildUploadButton(Icons.photo_library, 'Gallery', ImageSource.gallery),
                    ],
                  ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () => _pickImage(source),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF2D5016)),
            const SizedBox(height: 8),
            TranslatedText(label),
          ],
        ),
      ),
    );
  }
}
