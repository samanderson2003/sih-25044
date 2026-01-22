import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../crop_diseases_detection/model/disease_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LivestockDiagnosisService {
  // Custom DL Model API
  static const String _apiUrl = 'https://ml1.nandhaprabhur.me/predict';

  Future<DiseaseResult> diagnoseLivestock({
    required File imageFile,
    String? cattleType, // Optional, for context if the model supports it
  }) async {
    try {
      debugPrint('🔗 Connecting to DL Model: $_apiUrl');
      
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Model Response: $data');

        // Parse Prediction
        String predictedClass = data['prediction'] ?? data['class'] ?? 'Unknown';
        
        // Format common keys for better UI
        if (predictedClass.toUpperCase() == 'LUMPY') {
          predictedClass = 'Lumpy Skin Disease';
        } else if (predictedClass.toUpperCase() == 'FOOT_AND_MOUTH') {
          predictedClass = 'Foot and Mouth Disease';
        } else {
             // Capitalize first letter of each word
             predictedClass = predictedClass.split('_').map((word) {
                if (word.isEmpty) return word;
                return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
             }).join(' ');
        }

        // Parse Confidence (e.g., "96.77%" -> 0.9677)
        String confidenceStr = data['confidence'].toString().replaceAll('%', '');
        double confidence = (double.tryParse(confidenceStr) ?? 0.0) / 100.0;

        return DiseaseResult(
          predictedClass: predictedClass,
          confidence: confidence,
          description: data['description'] ?? 'Detected by AI Model based on visual symptoms.',
          treatment: data['treatment'] ?? data['remedy'] ?? 'Please consult a veterinarian immediately for confirmation and treatment.',
          // Mock fields
          model: 'Custom DL',
          predictedIndex: -1,
          classes: [],
          probabilities: [],
          topPredictions: [],
        );
      } else {
        debugPrint('❌ Model Error: ${response.statusCode} - ${response.body}');
        throw Exception('Model analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Diagnosis Service Error: $e');
      throw Exception('Failed to connect to AI model: $e');
    }
  }
}
