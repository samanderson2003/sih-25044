import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to extract soil test data from lab report images using ChatGPT Vision API
class SoilReportOCRService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Extract soil nutrient data from lab report image
  static Future<Map<String, double>?> extractSoilData(File imageFile) async {
    try {
      // Read image file as base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare the request
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']!}',
            },
            body: json.encode({
              'model': 'gpt-4o', // GPT-4 Vision model
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are an expert soil test report analyzer. Extract micronutrient values from various soil lab report formats.

NUTRIENTS TO EXTRACT (look for any of these names/abbreviations):
1. Zinc: "Zinc", "Zn", "Available Zinc", "Available Zn" → output as "zinc"
2. Iron: "Iron", "Fe", "Available Iron", "Available Fe" → output as "iron"  
3. Copper: "Copper", "Cu", "Available Copper", "Available Cu" → output as "copper"
4. Manganese: "Manganese", "Mn", "Available Manganese", "Available Mn" → output as "manganese"
5. Boron: "Boron", "B", "Available Boron", "Available B" → output as "boron"
6. Sulfur: "Sulfur", "Sulphur", "S", "Available Sulfur", "Available S" → output as "sulfur"

UNIT CONVERSIONS:
- If in kg/ha: divide by 1 to get ppm (approximate)
- If in ppm, mg/kg: use as-is
- For Sulfur: if in kg/ha, divide by 200 to get % (approximate)
- For Sulfur: if in ppm, divide by 10000 to get %

OUTPUT FORMAT:
Return ONLY a JSON object with these exact lowercase keys: zinc, iron, copper, manganese, boron, sulfur
If a value is not found, use null.
All values should be in ppm (except sulfur which should be in %).

EXAMPLES:
Input: "Available Zinc (ppm): 1.87" → Output: "zinc": 1.87
Input: "Available Iron: 57.31 ppm" → Output: "iron": 57.31
Input: "Zinc (Zn) 75.0 ppm" → Output: "zinc": 75.0
Input: "Available S (kg/ha): 21.45" → Output: "sulfur": 0.10725 (21.45/200)
Input: "Boron 4.85 ppm" → Output: "boron": 4.85

Sample output: {"zinc": 1.87, "iron": 57.31, "copper": 1.81, "manganese": 25.07, "boron": 4.85, "sulfur": 0.10}

IMPORTANT: Return ONLY the JSON object, no explanations or markdown.''',
                },
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text':
                          'Analyze this soil test report image and extract the 6 micronutrient values. Return only JSON.',
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$base64Image',
                      },
                    },
                  ],
                },
              ],
              'max_tokens': 500,
              'temperature': 0.1, // Low temperature for consistent extraction
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        debugPrint('✅ ChatGPT Response: $content');

        // Parse the JSON response
        final soilData = _parseJsonResponse(content);

        if (soilData != null && soilData.isNotEmpty) {
          debugPrint('✅ Extracted soil data: $soilData');
          return soilData;
        } else {
          debugPrint('⚠️ No valid data extracted from response');
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Invalid API key. Please check your OpenAI API key.');
        throw Exception(
          'Invalid API key. Please configure your OpenAI API key in soil_report_ocr_service.dart',
        );
      } else {
        debugPrint('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error extracting soil data: $e');
      rethrow;
    }
  }

  /// Parse JSON response from ChatGPT (handles markdown code blocks)
  static Map<String, double>? _parseJsonResponse(String content) {
    try {
      // Remove markdown code blocks if present
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      // Parse JSON
      final Map<String, dynamic> parsed = json.decode(jsonStr);

      // Convert to Map<String, double>
      final Map<String, double> result = {};
      for (final key in [
        'zinc',
        'iron',
        'copper',
        'manganese',
        'boron',
        'sulfur',
      ]) {
        if (parsed.containsKey(key) && parsed[key] != null) {
          final value = parsed[key];
          if (value is num) {
            result[key] = value.toDouble();
          } else if (value is String) {
            final numValue = double.tryParse(value);
            if (numValue != null) {
              result[key] = numValue;
            }
          }
        }
      }

      return result.isNotEmpty ? result : null;
    } catch (e) {
      debugPrint('⚠️ Error parsing JSON: $e');
      return null;
    }
  }

  /// Check if API key is configured in .env
  static bool isConfigured() {
    return dotenv.env['OPENAI_API_KEY'] != null &&
        dotenv.env['OPENAI_API_KEY']!.isNotEmpty;
  }
}
