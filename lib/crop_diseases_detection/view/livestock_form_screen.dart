import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../profile/controller/cattle_controller.dart';
import '../../services/livestock_diagnosis_service.dart';
import '../../profile/model/cattle_model.dart';
import '../../widgets/translated_text.dart';
import '../controller/disease_detection_controller.dart';
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
  final TextEditingController _symptomsController = TextEditingController();
  int _currentStep = 0;

  final List<String> _questions = [
    "Diarrhea: Have you noticed any signs of diarrhea (chronic or bloody)?",
    "Weight Loss: Are they losing weight despite normal appetite?",
    "Coat Condition: Does the cattle have a poor or unhealthy coat?",
    "Milk Production: Is there a noticeable reduction in milk production?",
    "Fever: Is the cattle showing signs of fever?",
    "Anemia: Do they have pale gums or appear weak?",
    "Lymph Nodes: Are there visible swellings in lymph nodes?",
    "Appetite Loss: Has there been a recent loss of appetite?",
    "Straining: Is there straining during defecation?",
    "Dehydration: Signs of dehydration (sunken eyes, dry nose)?",
    "Abortion: Has there been any recent abortion (if pregnant)?",
    "Neurological: Any incoordination or abnormal behavior?",
    "Movement: Does the cattle lack coordination or appear clumsy?",
    "Muscle Tremors: Are there muscle tremors or sound sensitivity?",
    "Activity Level: Is the cattle lethargic?",
  ];

  late List<String?> _answers;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(_questions.length, null);
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

  void _updateAnswer(int index, String answer) {
    setState(() {
      _answers[index] = answer;
    });
  }

  bool get _canSubmit {
    return _imageFile != null &&
        _selectedCattleId != null &&
        !_answers.contains(null);
  }

  Future<void> _submitForm() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and upload an image')),
      );
      return;
    }

    final controller = context.read<DiseaseDetectionController>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFCCD2A)),
      ),
    );

    // Prepare questionnaire data
    final questionnaire = <String, String>{};
    for (int i = 0; i < _questions.length; i++) {
      questionnaire[_questions[i]] = _answers[i]!;
    }
    questionnaire['additional_symptoms'] = _symptomsController.text;
    questionnaire['cattle_id'] = _selectedCattleId!;

    try {
      // Use the direct AI service using the provided key
      final service = LivestockDiagnosisService();
      
      // Get cattle type name for context
      // We need to look up the cattle object from the controller or just pass ID.
      // Ideally we would pass "Cow" or "Goat". For now, we'll pass a generic string 
      // or try to find it if we had the list handy. 
      // The prompt will work with just "Livestock" if needed, but type is better.
      
      final result = await service.diagnoseLivestock(
        imageFile: _imageFile!,
        symptoms: questionnaire,
        cattleType: 'Livestock (ID: $_selectedCattleId)', 
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Add to history via controller for persistence (optional, but good for UI consistency)
        // controller.addManualResult(result, _imageFile!); // We would need to implement this in controller
        
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
             content: Text('AI Diagnosis Failed: $e'),
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
          if (_currentStep < 2) {
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
                    child: TranslatedText(_currentStep == 2 ? 'Submit' : 'Next'),
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
                    // labelText: 'Choose Animal', // Removed string label
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

          // Step 3: Questionnaire
          Step(
            title: const TranslatedText('Symptoms'),
            content: Column(
              children: [
                ...List.generate(_questions.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: TranslatedText(
                                _questions[index],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildChoiceChip(index, 'Yes'),
                            const SizedBox(width: 10),
                            _buildChoiceChip(index, 'No'),
                            const SizedBox(width: 10),
                            _buildChoiceChip(index, 'Not Sure'),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                TextField(
                  controller: _symptomsController,
                  decoration: const InputDecoration(
                    label: TranslatedText('Additional Symptoms', style: TextStyle(color: Colors.grey)),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            isActive: _currentStep >= 2,
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

  Widget _buildChoiceChip(int index, String option) {
    final isSelected = _answers[index] == option;
    return ChoiceChip(
      label: TranslatedText(option),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _updateAnswer(index, option);
      },
      selectedColor: const Color(0xFFFCCD2A),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.black87),
    );
  }
}
