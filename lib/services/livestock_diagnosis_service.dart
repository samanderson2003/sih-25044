import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../crop_diseases_detection/model/disease_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LivestockDiagnosisService {
  // OpenAI implementation using the key provided by the user
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<DiseaseResult> diagnoseLivestock({
    required File imageFile,
    required Map<String, String> symptoms,
    required String cattleType, // e.g., "Cow - Gir"
  }) async {
    try {
      // 1. Convert image to Base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 2. Construct the prompt from symptoms
      final StringBuffer symptomBuffer = StringBuffer();
      symptoms.forEach((key, value) {
        symptomBuffer.writeln('- $key: $value');
      });

      // 3. Prepare the request payload
      final requestBody = {
        "model": "gpt-4o",
        "messages": [
          {
            "role": "system",
            "content": "You are an expert veterinarian AI. Your task is to diagnose livestock health issues by carefully analyzing the provided image and symptoms. "
                "Follow this strict reasoning process:"
                "1. **Subject Validation**: First, checks if the image contains a valid livestock animal (Cow, Buffalo, Goat, Sheep, Pig). "
                "   - If the image contains a person, object (pen, pencil, etc.), or non-livestock animal, REJECT it immediately."
                "   - Return 'predicted_class': 'Invalid Image', 'description': 'The image does not appear to be a livestock animal. Please upload a clear photo of a cow, goat, or buffalo.'."
                "2. **Visual Analysis**: If valid, list all visual abnormalities you see in the image (e.g., lumps, lesions, discharge, swelling). "
                "3. **Symptom Matching**: Compare these visual findings with the reported text symptoms. "
                "4. **Diagnosis**: Based on the combination of strong visual evidence and reported symptoms, determine the disease. "
                "Note: If you see distinct skin nodules or lumps across the body, this is a very strong indicator of 'Lumpy Skin Disease', even if some text symptoms are missing. "
                "Provide the FINAL result in valid JSON format (without markdown) with these keys: "
                "predicted_class (Specific disease name, 'Healthy', or 'Invalid Image'), "
                "confidence (float 0.0-1.0), "
                "description (Explain your visual observations and how they led to the diagnosis), "
                "treatment (Recommended remedy/action or 'None' if invalid)."
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Diagnose this $cattleType. \nSymptoms reported:\n${symptomBuffer.toString()}"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "max_tokens": 500
      };

      // 4. Call OpenAI API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Clean content if it contains markdown code blocks
        String cleanJson = content.toString().replaceAll('```json', '').replaceAll('```', '').trim();
        
        final resultData = jsonDecode(cleanJson);

        return DiseaseResult(
          predictedClass: resultData['predicted_class'] ?? 'Unknown',
          confidence: (resultData['confidence'] as num?)?.toDouble() ?? 0.0,
          description: resultData['description'] ?? 'No description available.',
          treatment: resultData['treatment'] ?? 'Consult a vet.',
          // Required mock fields for DiseaseResult compatibility
          model: 'gpt-4o',
          predictedIndex: -1,
          classes: [],
          probabilities: [],
          topPredictions: [],
        );
      } else {
        debugPrint('OpenAI Error: ${response.statusCode} - ${response.body}');
        throw Exception('Diagnosis failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Diagnosis Service Error: $e');
      throw Exception('Failed to diagnose livestock: $e');
    }
  }
}
