import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to generate AI-powered crop recommendations using ChatGPT
class AIRecommendationService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Generate variety-specific recommendations for 10% yield increase
  static Future<VarietyRecommendations?> generateRecommendations({
    required String crop,
    required List<String> varieties,
    required String district,
    required double currentYield,
    required double targetYield,
    required Map<String, dynamic> soilData,
    required Map<String, dynamic> climateData,
  }) async {
    try {
      final prompt = _buildPrompt(
        crop: crop,
        varieties: varieties,
        district: district,
        currentYield: currentYield,
        targetYield: targetYield,
        soilData: soilData,
        climateData: climateData,
      );

      final response = await http
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
                      '''You are an expert agricultural advisor specializing in Tamil Nadu (Tamil) state agriculture practices. 
You provide ONLY official recommendations approved by the Tamil Nadu Department of Agriculture & Farmers' Empowerment.
Always cite Tamil Nadu government sources, KVK (Krishi Vigyan Kendra) guidelines, and state agricultural university research.
Format output as valid JSON only, no markdown or explanations.''',
                },
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': 2000,
              'temperature': 0.3, // Low temperature for factual recommendations
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        debugPrint('✅ ChatGPT Response received');

        final recommendations = _parseRecommendations(content);
        return recommendations;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Invalid OpenAI API key');
        throw Exception('Invalid API key');
      } else {
        debugPrint('❌ API Error: ${response.statusCode}');
        throw Exception(
          'Failed to generate recommendations: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating AI recommendations: $e');
      return null;
    }
  }

  static String _buildPrompt({
    required String crop,
    required List<String> varieties,
    required String district,
    required double currentYield,
    required double targetYield,
    required Map<String, dynamic> soilData,
    required Map<String, dynamic> climateData,
  }) {
    return '''
TASK: Generate official Tamil Nadu government agricultural recommendations to increase ${crop} yield by 10%.

CURRENT SITUATION:
- Location: $district district, Tamil Nadu
- Crop: $crop
- Available Varieties: ${varieties.join(', ')}
- Current Predicted Yield: ${currentYield.toStringAsFixed(2)} tonnes/hectare
- Target Yield (10% increase): ${targetYield.toStringAsFixed(2)} tonnes/hectare

SOIL CONDITIONS:
- pH: ${soilData['ph']}
- Texture: ${soilData['texture']}
- Zinc: ${soilData['zn']}%
- Iron: ${soilData['fe']}%
- Copper: ${soilData['cu']}%
- Manganese: ${soilData['mn']}%
- Boron: ${soilData['b']}%
- Sulfur: ${soilData['s']}%

CLIMATE DATA:
- Average Temperature: ${climateData['tavg']}°C
- Min Temperature: ${climateData['tmin']}°C
- Max Temperature: ${climateData['tmax']}°C
- Daily Precipitation: ${climateData['prcp']}mm

REQUIREMENTS:
Generate ONLY official Tamil Nadu government recommendations including:

1. **Best Variety**: Which variety from the list is best suited? (with official reason)

2. **Fertilizer Schedule**: Complete NPK + micronutrient schedule as per Tamil Nadu Dept. of Agriculture
   - Pre-sowing application
   - Basal dose (at planting)
   - Top dressing (split doses with timing)
   - Micronutrient application (based on deficiencies)

3. **Irrigation Schedule**: Official Tamil Nadu government irrigation guidelines
   - Critical growth stages
   - Frequency and amount
   - Water-saving techniques (if applicable)

4. **Pest & Disease Management**: Official IPM practices approved by Odisha Agriculture
   - Common pests for this variety in $district
   - Preventive measures
   - Organic/chemical control (with trade names used in Odisha)
   - Application timing

5. **Additional Practices**: Any other official recommendations
   - Seed treatment
   - Spacing and plant density
   - Weed management
   - Harvesting practices

OUTPUT FORMAT (JSON only, no markdown):
{
  "recommended_variety": "variety name",
  "variety_reason": "why this variety is best",
  "fertilizer_schedule": [
    {
      "stage": "Pre-sowing",
      "timing": "15 days before sowing",
      "application": "FYM 5 tonnes/acre",
      "purpose": "soil enrichment"
    }
  ],
  "irrigation_schedule": [
    {
      "stage": "Germination",
      "timing": "0-10 days",
      "frequency": "Light irrigation every 2-3 days",
      "amount": "20-25mm"
    }
  ],
  "pest_control": [
    {
      "pest": "Stem Borer",
      "prevention": "Use pheromone traps",
      "treatment": "Apply Chlorantraniliprole 18.5% SC @ 150ml/acre",
      "timing": "30-35 days after transplanting"
    }
  ],
  "additional_practices": [
    "Seed treatment with Trichoderma @ 10g/kg seed",
    "Maintain 20cm x 15cm spacing for optimum plant density"
  ],
  "expected_yield_increase": "10-12%",
  "government_source": "Odisha Dept. of Agriculture, KVK $district"
}

Generate factual, implementable recommendations based on official Odisha agricultural guidelines.
''';
  }

  static VarietyRecommendations? _parseRecommendations(String content) {
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

      final Map<String, dynamic> parsed = json.decode(jsonStr);

      return VarietyRecommendations(
        recommendedVariety: parsed['recommended_variety'] ?? '',
        varietyReason: parsed['variety_reason'] ?? '',
        fertilizerSchedule:
            (parsed['fertilizer_schedule'] as List?)
                ?.map((item) => FertilizerApplication.fromJson(item))
                .toList() ??
            [],
        irrigationSchedule:
            (parsed['irrigation_schedule'] as List?)
                ?.map((item) => IrrigationSchedule.fromJson(item))
                .toList() ??
            [],
        pestControl:
            (parsed['pest_control'] as List?)
                ?.map((item) => PestControl.fromJson(item))
                .toList() ??
            [],
        additionalPractices: List<String>.from(
          parsed['additional_practices'] ?? [],
        ),
        expectedYieldIncrease: parsed['expected_yield_increase'] ?? '10%',
        governmentSource:
            parsed['government_source'] ?? 'Odisha Dept. of Agriculture',
      );
    } catch (e) {
      debugPrint('⚠️ Error parsing AI recommendations: $e');
      return null;
    }
  }
}

class VarietyRecommendations {
  final String recommendedVariety;
  final String varietyReason;
  final List<FertilizerApplication> fertilizerSchedule;
  final List<IrrigationSchedule> irrigationSchedule;
  final List<PestControl> pestControl;
  final List<String> additionalPractices;
  final String expectedYieldIncrease;
  final String governmentSource;

  VarietyRecommendations({
    required this.recommendedVariety,
    required this.varietyReason,
    required this.fertilizerSchedule,
    required this.irrigationSchedule,
    required this.pestControl,
    required this.additionalPractices,
    required this.expectedYieldIncrease,
    required this.governmentSource,
  });
}

class FertilizerApplication {
  final String stage;
  final String timing;
  final String application;
  final String purpose;

  FertilizerApplication({
    required this.stage,
    required this.timing,
    required this.application,
    required this.purpose,
  });

  factory FertilizerApplication.fromJson(Map<String, dynamic> json) {
    return FertilizerApplication(
      stage: json['stage'] ?? '',
      timing: json['timing'] ?? '',
      application: json['application'] ?? '',
      purpose: json['purpose'] ?? '',
    );
  }
}

class IrrigationSchedule {
  final String stage;
  final String timing;
  final String frequency;
  final String amount;

  IrrigationSchedule({
    required this.stage,
    required this.timing,
    required this.frequency,
    required this.amount,
  });

  factory IrrigationSchedule.fromJson(Map<String, dynamic> json) {
    return IrrigationSchedule(
      stage: json['stage'] ?? '',
      timing: json['timing'] ?? '',
      frequency: json['frequency'] ?? '',
      amount: json['amount'] ?? '',
    );
  }
}

class PestControl {
  final String pest;
  final String prevention;
  final String treatment;
  final String timing;

  PestControl({
    required this.pest,
    required this.prevention,
    required this.treatment,
    required this.timing,
  });

  factory PestControl.fromJson(Map<String, dynamic> json) {
    return PestControl(
      pest: json['pest'] ?? '',
      prevention: json['prevention'] ?? '',
      treatment: json['treatment'] ?? '',
      timing: json['timing'] ?? '',
    );
  }
}
