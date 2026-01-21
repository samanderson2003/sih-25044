import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controller/disease_detection_controller.dart';
import 'disease_result_screen.dart';
import 'livestock_detection_view.dart';
import '../../widgets/translated_text.dart';

class CropDetectionScreen extends StatefulWidget {
  const CropDetectionScreen({super.key});

  @override
  State<CropDetectionScreen> createState() => _CropDetectionScreenState();
}

class _CropDetectionScreenState extends State<CropDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedCrop;

  // Available crops matching your trained models
  final List<Map<String, dynamic>> _availableCrops = [
    {
      'name': 'Rice',
      'key': 'rice_segmented',
      'icon': '🌾',
      'color': Color(0xFFD4AF37),
    },
    {
      'name': 'Tomato', // Common
      'key': 'tomato_segmented',
      'icon': '🍅',
      'color': Color(0xFFFF6347),
    },
    {
      'name': 'Carrot', // New
      'key': 'carrot_segmented',
      'icon': '🥕',
      'color': Color(0xFFED9121),
    },
    {
      'name': 'Maize', // New
      'key': 'maize_segmented',
      'icon': '🌽',
      'color': Color(0xFFFBEC5D),
    },
    {
      'name': 'Cucumber', // New
      'key': 'cucumber_segmented',
      'icon': '🥒',
      'color': Color(0xFF228B22),
    },
    {
      'name': 'Brinjal', // New
      'key': 'brinjal_segmented',
      'icon': '🍆',
      'color': Color(0xFF4B0082),
    },
    {
      'name': 'Guava', // New
      'key': 'guava_segmented',
      'icon': '🍈',
      'color': Color(0xFF98FB98),
    },
    {
      'name': 'Watermelon', // New
      'key': 'watermelon_segmented',
      'icon': '🍉',
      'color': Color(0xFFDC143C),
    },
    {
      'name': 'Apple', // Common
      'key': 'apple_segmented',
      'icon': '🍎',
      'color': Color(0xFFDC143C),
    },
    {
      'name': 'Grape',
      'key': 'grape_segmented',
      'icon': '🍇',
      'color': Color(0xFF6A5ACD),
    },
    {
      'name': 'Strawberry',
      'key': 'strawberry_segmented',
      'icon': '🍓',
      'color': Color(0xFFFF1493),
    },
    {
      'name': 'Peach',
      'key': 'peach_segmented',
      'icon': '🍑',
      'color': Color(0xFFFFDAB9),
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
  }

  Future<void> _checkApiHealth() async {
    final controller = context.read<DiseaseDetectionController>();
    final isHealthy = await controller.checkHealth();
    if (!isHealthy && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Detection service is offline. Please start the server.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        _processImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    final controller = context.read<DiseaseDetectionController>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF2D5016)),
                SizedBox(height: 16),
                TranslatedText('Analyzing image...'),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await controller.detectDisease(
      imageFile,
      modelKey: _selectedCrop, // Pass selected crop model
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result != null) {
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DiseaseResultScreen(result: result, imagePath: imageFile.path),
          ),
        );
      } else {
        // Show error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                TranslatedText('Detection Failed'),
              ],
            ),
            content: TranslatedText(
              controller.error ?? 'Failed to detect disease. Please try again.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const TranslatedText(
                  'OK',
                  style: TextStyle(color: Color(0xFF2D5016)),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  bool _isLivestockMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F0),
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton('CROP', !_isLivestockMode),
              _buildToggleButton('LIVESTOCK', _isLivestockMode),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: _isLivestockMode
          ? const LivestockDetectionView()
          : _selectedCrop == null
              ? _buildCropSelectionView()
              : _buildImageCaptureView(),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _isLivestockMode = text == 'LIVESTOCK';
          if (_isLivestockMode) {
            _selectedCrop = null; // Reset crop selection when switching
          }
        });
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isLivestockMode ? const Color(0xFFFCCD2A) : const Color(0xFF2D5016))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: TranslatedText(
          text,
          style: TextStyle(
            color: isSelected
                ? (_isLivestockMode ? Colors.black : Colors.white)
                : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCropSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Title
          TranslatedText(
            'Select Crop Type',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            'Choose the crop you want to analyze for diseases',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          // Crop Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _availableCrops.length,
            itemBuilder: (context, index) {
              final crop = _availableCrops[index];
              return _buildCropCard(crop);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCrop = crop['key'];
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (crop['color'] as Color).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji Icon
            Text(crop['icon'], style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            // Crop Name
            TranslatedText(
              crop['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: crop['color'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaptureView() {
    final selectedCropData = _availableCrops.firstWhere(
      (crop) => crop['key'] == _selectedCrop,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Back button and selected crop display
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCrop = null;
                  });
                },
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
              ),
              Text(
                selectedCropData['icon'],
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 8),
              TranslatedText(
                selectedCropData['name'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: selectedCropData['color'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title Section
          TranslatedText(
            'Crop Disease Detection',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            'Upload or capture an image of your crop to detect diseases',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          // Camera Option
          _buildDetectionOption(
            icon: Icons.camera_alt,
            title: 'Take Photo',
            description: 'Capture image using camera',
            color: const Color(0xFF2D5016),
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 16),

          // Gallery Option
          _buildDetectionOption(
            icon: Icons.photo_library,
            title: 'Choose from Gallery',
            description: 'Select image from your device',
            color: const Color(0xFF3D6B23),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: 30),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2D5016).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF2D5016),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    TranslatedText(
                      'Tips for Best Results',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem('Ensure good lighting conditions'),
                _buildTipItem('Focus on affected leaf or plant part'),
                _buildTipItem('Avoid blurry or distant images'),
                _buildTipItem('Capture clear visible symptoms'),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Recent Detections
          Consumer<DiseaseDetectionController>(
            builder: (context, controller, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TranslatedText(
                        'Recent Detections',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                      if (controller.history.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear History'),
                                content: const Text(
                                  'Are you sure you want to clear all detection history?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      controller.clearHistory();
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (controller.history.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No recent detections',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.history.length,
                      itemBuilder: (context, index) {
                        final item = controller.history[index];
                        return _buildHistoryItem(item, index);
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, size: 16, color: Color(0xFF2D5016)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(DetectionHistory item, int index) {
    final controller = context.read<DiseaseDetectionController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(item.imagePath),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        ),
        title: Text(
          item.result.predictedClass,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.result.getSeverityColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(item.result.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: item.result.getSeverityColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, h:mm a').format(item.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            controller.removeHistoryItem(index);
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiseaseResultScreen(
                result: item.result,
                imagePath: item.imagePath,
              ),
            ),
          );
        },
      ),
    );
  }
}
