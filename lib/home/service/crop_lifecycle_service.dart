import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/home/model/crop_model.dart';

/// Service to generate crop lifecycle stages dynamically using ChatGPT API
class CropLifecycleService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Generate 8-stage crop lifecycle for the given crop
  /// Returns list of CropStage objects with days, names, actions, and descriptions
  static Future<List<CropStage>?> generateCropLifecycle({
    required String cropName,
    String? soilType,
    String? climate,
    String? location,
  }) async {
    try {
      debugPrint('📤 Generating lifecycle for $cropName using ChatGPT...');

      // Build context from farm data
      final contextInfo = StringBuffer();
      if (soilType != null) contextInfo.write('Soil: $soilType. ');
      if (climate != null) contextInfo.write('Climate: $climate. ');
      if (location != null) contextInfo.write('Location: $location. ');

      // Prepare the request with retry logic
      http.Response? response;
      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries) {
        try {
          response = await http
              .post(
                Uri.parse(_apiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']!}',
                },
                body: json.encode({
                  'model': 'gpt-4o',
                  'messages': [
                    {
                      'role': 'system',
                      'content':
                          '''You are an expert agricultural advisor. Generate a detailed crop lifecycle with 8 standard farming stages.

THE 8 STAGES (in order):
1. Land Preparation
2. Seed Selection & Treatment  
3. Sowing/Transplanting
4. Irrigation Management
5. Intercultural Operations
6. Plant Protection
7. Harvesting
8. Post-Harvest Processing

FOR EACH STAGE PROVIDE:
- daysAfterPlanting: Number of days after planting when this stage occurs (stage 1 should be negative days like -15 to -7 for pre-planting prep)
- stageName: One of the 8 stage names above
- actionTitle: Short action phrase (3-5 words) like "Prepare soil bed" or "Apply nitrogen fertilizer"
- description: Detailed 2-3 sentence guide with SPECIFIC QUANTITIES, DOSAGES, and MEASUREMENTS. Include exact amounts for fertilizers (kg/hectare or g/kg), pesticides (ml/liter or g/liter), water (liters or cm depth), seed rates, spacing, etc. Always mention quality standards and specific product names or chemical compounds.
- icon: Choose from these Flutter icons (just the name): agriculture, water_drop, eco, pest_control, grass, science, verified, local_florist

IMPORTANT RULES FOR DESCRIPTIONS:
- Always include specific quantities: "Apply 120 kg/ha of Urea" instead of "Apply urea"
- Mention quality: "Use certified seeds with 85% germination" instead of "Use good seeds"
- Include timing: "Apply at 30 DAS (Days After Sowing)" 
- Add dosage for pesticides: "Chlorpyrifos @ 2.5 ml/liter of water"
- Specify measurements: "Maintain 5-7 cm water depth" not "adequate water"

OUTPUT FORMAT:
Return ONLY a JSON array with 8 objects, no markdown or explanations.

Example:
[
  {
    "daysAfterPlanting": -15,
    "stageName": "Land Preparation",
    "actionTitle": "Deep plow and level",
    "description": "Plow the field to 20-25 cm depth. Level properly. Apply 10 tonnes/hectare of well-decomposed farmyard manure or 5 tonnes/ha of compost. Ensure EC < 4 dS/m for optimal growth.",
    "icon": "agriculture"
  },
  {
    "daysAfterPlanting": -3,
    "stageName": "Seed Selection & Treatment",
    "actionTitle": "Treat seeds with fungicide",
    "description": "Select certified seeds with 85% germination rate. Treat with Carbendazim @ 2g/kg seed or Thiram @ 3g/kg. Alternatively, use Trichoderma viride @ 4g/kg for organic farming.",
    "icon": "science"
  },
  {
    "daysAfterPlanting": 30,
    "stageName": "Irrigation Management",
    "actionTitle": "First critical irrigation",
    "description": "Apply 50-60 mm irrigation depth. Maintain 5-7 cm standing water for rice. Schedule next irrigation when soil moisture drops to 70% field capacity. Use drip at 4 liters/hr for vegetables.",
    "icon": "water_drop"
  },
  {
    "daysAfterPlanting": 35,
    "stageName": "Intercultural Operations",
    "actionTitle": "Top dressing of nitrogen",
    "description": "Apply 60 kg/ha Urea (equivalent to 27 kg N/ha) as top dressing. Apply Potash @ 30 kg/ha. Perform manual weeding or spray Pretilachlor @ 500g/ha within 3 days of transplanting.",
    "icon": "eco"
  },
  {
    "daysAfterPlanting": 60,
    "stageName": "Plant Protection",
    "actionTitle": "Control stem borer",
    "description": "Monitor pest population using pheromone traps (8 traps/ha). If ETL exceeds, spray Chlorantraniliprole @ 0.4 ml/liter or Cartap Hydrochloride @ 2g/liter. Apply neem oil 1500 ppm @ 5 ml/liter for organic control.",
    "icon": "pest_control"
  }
]

IMPORTANT: Return ONLY the JSON array, no other text.''',
                    },
                    {
                      'role': 'user',
                      'content':
                          'Generate the 8-stage crop lifecycle for $cropName crop with SPECIFIC QUANTITIES and DOSAGES for all inputs. ${contextInfo.isNotEmpty ? 'Farm context: $contextInfo' : ''} Return only JSON array.',
                    },
                  ],
                  'max_tokens': 2500,
                  'temperature': 0.3, // Low temperature for consistency
                }),
              )
              .timeout(
                const Duration(seconds: 45),
                onTimeout: () {
                  throw Exception('Request timed out after 45 seconds');
                },
              );

          // Success - break retry loop
          break;
        } catch (e) {
          retryCount++;
          if (retryCount > maxRetries) {
            debugPrint('❌ Failed after $maxRetries retries: $e');
            rethrow;
          }
          debugPrint('⚠️ Retry $retryCount/$maxRetries after error: $e');
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }

      if (response == null) {
        throw Exception('Failed to get response from API');
      }

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        debugPrint('✅ ChatGPT Response: $content');

        // Parse the JSON response
        final stages = _parseLifecycleResponse(content);

        if (stages != null && stages.isNotEmpty) {
          debugPrint(
            '✅ Generated ${stages.length} lifecycle stages for $cropName',
          );
          return stages;
        } else {
          debugPrint('⚠️ No valid stages extracted from response');
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Invalid API key. Please check your OpenAI API key.');
        throw Exception(
          'Invalid API key. Please configure your OpenAI API key in crop_lifecycle_service.dart',
        );
      } else if (response.statusCode == 429) {
        throw Exception(
          'Rate limit exceeded. Please try again in a few minutes.',
        );
      } else {
        debugPrint('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'API request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating crop lifecycle: $e');
      return null;
    }
  }

  /// Parse ChatGPT JSON response into CropStage objects
  static List<CropStage>? _parseLifecycleResponse(String content) {
    try {
      // Remove markdown code blocks if present
      String cleaned = content.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final List<dynamic> jsonArray = json.decode(cleaned);

      return jsonArray.map((item) {
        return CropStage(
          daysAfterPlanting: item['daysAfterPlanting'] as int,
          stageName: item['stageName'] as String,
          actionTitle: item['actionTitle'] as String,
          description: item['description'] as String,
          icon: item['icon'] as String,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error parsing lifecycle JSON: $e');
      return null;
    }
  }

  /// Cache for generated lifecycles to avoid repeated API calls
  static final Map<String, List<CropStage>> _cache = {};

  /// Get lifecycle with caching
  static Future<List<CropStage>?> getCachedLifecycle({
    required String cropName,
    String? soilType,
    String? climate,
    String? location,
    bool forceRefresh = false,
  }) async {
    final cacheKey = cropName.toLowerCase();

    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      debugPrint('✅ Using cached lifecycle for $cropName');
      return _cache[cacheKey];
    }

    // Generate new lifecycle
    final stages = await generateCropLifecycle(
      cropName: cropName,
      soilType: soilType,
      climate: climate,
      location: location,
    );

    // Cache the result if successful
    if (stages != null && stages.isNotEmpty) {
      _cache[cacheKey] = stages;
    }

    return stages;
  }

  /// Clear the cache (useful for testing or when user wants fresh data)
  static void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Cleared lifecycle cache');
  }
}
