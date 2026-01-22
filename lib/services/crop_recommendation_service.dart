import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Model for crop recommendation
class CropRecommendation {
  final String recommendedCrop;
  final String reason;
  final double expectedYieldIncrease; // percentage
  final List<String> bestVarieties;
  final IrrigationPlan irrigation;
  final FertilizerPlan fertilizer;
  final PestControlPlan pestControl;
  final List<String> tamilNaduSchemes;
  final String estimatedInvestment;

  CropRecommendation({
    required this.recommendedCrop,
    required this.reason,
    required this.expectedYieldIncrease,
    required this.bestVarieties,
    required this.irrigation,
    required this.fertilizer,
    required this.pestControl,
    required this.tamilNaduSchemes,
    required this.estimatedInvestment,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      recommendedCrop: json['recommendedCrop'] ?? 'Not specified',
      reason: json['reason'] ?? '',
      expectedYieldIncrease: (json['expectedYieldIncrease'] as num?)?.toDouble() ?? 10.0,
      bestVarieties: List<String>.from(json['bestVarieties'] ?? []),
      irrigation: IrrigationPlan.fromJson(json['irrigation'] ?? {}),
      fertilizer: FertilizerPlan.fromJson(json['fertilizer'] ?? {}),
      pestControl: PestControlPlan.fromJson(json['pestControl'] ?? {}),
      tamilNaduSchemes: List<String>.from(json['tamilNaduSchemes'] ?? []),
      estimatedInvestment: json['estimatedInvestment'] ?? 'Contact dealer',
    );
  }
}

class IrrigationPlan {
  final String method; // Drip, Sprinkler, Flood, etc.
  final String frequency;
  final String waterQuantity;
  final List<String> criticalStages;
  final String tamilNaduSubsidy;
  final List<String> recommendedProducts;

  IrrigationPlan({
    required this.method,
    required this.frequency,
    required this.waterQuantity,
    required this.criticalStages,
    required this.tamilNaduSubsidy,
    required this.recommendedProducts,
  });

  factory IrrigationPlan.fromJson(Map<String, dynamic> json) {
    return IrrigationPlan(
      method: json['method'] ?? 'Drip Irrigation',
      frequency: json['frequency'] ?? 'Every 7-10 days',
      waterQuantity: json['waterQuantity'] ?? '50-60 mm',
      criticalStages: List<String>.from(json['criticalStages'] ?? []),
      tamilNaduSubsidy: json['tamilNaduSubsidy'] ?? '50% subsidy available',
      recommendedProducts: List<String>.from(json['recommendedProducts'] ?? []),
    );
  }
}

class FertilizerPlan {
  final List<FertilizerStage> stages;
  final String organicAlternative;
  final String governmentScheme;

  FertilizerPlan({
    required this.stages,
    required this.organicAlternative,
    required this.governmentScheme,
  });

  factory FertilizerPlan.fromJson(Map<String, dynamic> json) {
    return FertilizerPlan(
      stages: (json['stages'] as List?)?.map((s) => FertilizerStage.fromJson(s)).toList() ?? [],
      organicAlternative: json['organicAlternative'] ?? 'Cow dung or vermicompost',
      governmentScheme: json['governmentScheme'] ?? 'Tamil Nadu Soil Health Card Scheme',
    );
  }
}

class FertilizerStage {
  final String stage;
  final String product;
  final String dosage;
  final String timing;
  final String cost;

  FertilizerStage({
    required this.stage,
    required this.product,
    required this.dosage,
    required this.timing,
    required this.cost,
  });

  factory FertilizerStage.fromJson(Map<String, dynamic> json) {
    return FertilizerStage(
      stage: json['stage'] ?? 'Basal',
      product: json['product'] ?? 'NPK',
      dosage: json['dosage'] ?? '100 kg/ha',
      timing: json['timing'] ?? 'At planting',
      cost: json['cost'] ?? '₹5,000',
    );
  }
}

class PestControlPlan {
  final List<PestStrategy> majorPests;
  final String preventiveMeasures;
  final String organicMethods;
  final String chemicalOption;

  PestControlPlan({
    required this.majorPests,
    required this.preventiveMeasures,
    required this.organicMethods,
    required this.chemicalOption,
  });

  factory PestControlPlan.fromJson(Map<String, dynamic> json) {
    return PestControlPlan(
      majorPests: (json['majorPests'] as List?)?.map((p) => PestStrategy.fromJson(p)).toList() ?? [],
      preventiveMeasures: json['preventiveMeasures'] ?? 'Field sanitation and crop rotation',
      organicMethods: json['organicMethods'] ?? 'Neem oil spray (1500 ppm)',
      chemicalOption: json['chemicalOption'] ?? 'Consult agricultural officer',
    );
  }
}

class PestStrategy {
  final String pestName;
  final String symptom;
  final String prevention;
  final String treatment;

  PestStrategy({
    required this.pestName,
    required this.symptom,
    required this.prevention,
    required this.treatment,
  });

  factory PestStrategy.fromJson(Map<String, dynamic> json) {
    return PestStrategy(
      pestName: json['pestName'] ?? 'Stem Borer',
      symptom: json['symptom'] ?? 'Wilting of tillers',
      prevention: json['prevention'] ?? 'Light traps and pheromone traps',
      treatment: json['treatment'] ?? 'Spray Chlorantraniliprole 0.4ml/liter',
    );
  }
}

/// Service to generate AI-powered crop recommendations for Tamil Nadu farmers
class CropRecommendationService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Get comprehensive crop recommendation based on farmer data
  /// Tamil Nadu focused with 10% yield improvement strategies
  static Future<CropRecommendation?> recommendCrop({
    required String district,
    required String soilType,
    required double soilPh,
    required double rainfallMm,
    required double currentYield,
    required String currentCrop,
    required double areaHectares,
    required double soilOrganic,
    required Map<String, double> soilNutrients, // Zinc, Iron, Copper, etc.
  }) async {
    try {
      final prompt = _buildRecommendationPrompt(
        district: district,
        soilType: soilType,
        soilPh: soilPh,
        rainfallMm: rainfallMm,
        currentYield: currentYield,
        currentCrop: currentCrop,
        areaHectares: areaHectares,
        soilOrganic: soilOrganic,
        soilNutrients: soilNutrients,
      );

      debugPrint('🌾 ===== CROP RECOMMENDATION REQUEST START =====');
      debugPrint('📍 District: $district');
      debugPrint('🌱 Current Crop: $currentCrop');
      debugPrint('📊 Current Yield: ${currentYield.toStringAsFixed(2)} T/Ha');
      debugPrint('🔍 Building recommendation prompt...');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']!}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an expert agricultural advisor specializing in Tamil Nadu farming.
Your recommendations MUST:
1. Focus ONLY on crops suitable for Tamil Nadu climate and soil
2. Recommend products/schemes available in Tamil Nadu
3. Consider current yield and how to increase by 10%
4. Provide practical, farmer-friendly advice
5. Return ONLY valid JSON, no markdown or explanations''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2500,
        }),
      ).timeout(const Duration(seconds: 60));

      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'].trim();

        // Remove markdown if present
        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> jsonData = jsonDecode(content);
        final recommendation = CropRecommendation.fromJson(jsonData);

        debugPrint('✅ Crop Recommendation Generated');
        debugPrint('🌾 Recommended: ${recommendation.recommendedCrop}');
        debugPrint('📈 Yield Increase: ${recommendation.expectedYieldIncrease}%');
        debugPrint('🌾 ===== CROP RECOMMENDATION REQUEST END (SUCCESS) =====');

        return recommendation;
      } else if (response.statusCode == 401) {
        debugPrint('❌ Invalid OpenAI API key');
        return null;
      } else {
        debugPrint('❌ API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting crop recommendation: $e');
      return null;
    }
  }

  static String _buildRecommendationPrompt({
    required String district,
    required String soilType,
    required double soilPh,
    required double rainfallMm,
    required double currentYield,
    required String currentCrop,
    required double areaHectares,
    required double soilOrganic,
    required Map<String, double> soilNutrients,
  }) {
    return '''
**FARMER DATA - Tamil Nadu Region:**

Location: $district District, Tamil Nadu
Current Crop: $currentCrop
Current Yield: ${currentYield.toStringAsFixed(2)} T/Ha
Farm Area: ${areaHectares.toStringAsFixed(2)} Hectares

**SOIL INFORMATION:**
- Type: $soilType
- pH: ${soilPh.toStringAsFixed(1)}
- Organic Carbon: ${soilOrganic.toStringAsFixed(1)}%
- Annual Rainfall: ${rainfallMm.toStringAsFixed(0)} mm
- Micronutrients:
  - Zinc: ${soilNutrients['zinc']?.toStringAsFixed(1) ?? 'N/A'} ppm
  - Iron: ${soilNutrients['iron']?.toStringAsFixed(1) ?? 'N/A'} ppm
  - Copper: ${soilNutrients['copper']?.toStringAsFixed(1) ?? 'N/A'} ppm
  - Manganese: ${soilNutrients['manganese']?.toStringAsFixed(1) ?? 'N/A'} ppm
  - Boron: ${soilNutrients['boron']?.toStringAsFixed(1) ?? 'N/A'} ppm

**TAMIL NADU SUITABLE CROPS:**
Only recommend from: Rice, Sugarcane, Groundnut, Coconut, Banana, Papaya, Turmeric, Chilli, Cotton, Maize, Pulses, Vegetables

**TASK:**
Recommend ONE best crop to maximize yield from ${currentYield.toStringAsFixed(2)} T/Ha to at least ${(currentYield * 1.10).toStringAsFixed(2)} T/Ha (10% increase).

Return ONLY valid JSON (no markdown):
{
  "recommendedCrop": "Crop Name",
  "reason": "Why this crop is best for the conditions (2-3 sentences)",
  "expectedYieldIncrease": 15.0,
  "bestVarieties": [
    "Improved Variety 1",
    "Improved Variety 2",
    "Improved Variety 3"
  ],
  "irrigation": {
    "method": "Drip/Sprinkler/Flood",
    "frequency": "Every X days",
    "waterQuantity": "X mm",
    "criticalStages": [
      "Stage 1",
      "Stage 2"
    ],
    "tamilNaduSubsidy": "% subsidy under scheme",
    "recommendedProducts": [
      "Brand/Type with cost",
      "Brand/Type with cost"
    ]
  },
  "fertilizer": {
    "stages": [
      {
        "stage": "Basal",
        "product": "NPK ratio or specific product",
        "dosage": "X kg/ha",
        "timing": "When to apply",
        "cost": "₹X"
      },
      {
        "stage": "Top dressing",
        "product": "Urea",
        "dosage": "60 kg/ha",
        "timing": "At flowering",
        "cost": "₹3,000"
      }
    ],
    "organicAlternative": "FYM/compost alternative",
    "governmentScheme": "Tamil Nadu Soil Health Card Scheme / PMKSY details"
  },
  "pestControl": {
    "majorPests": [
      {
        "pestName": "Pest name",
        "symptom": "Observable symptom",
        "prevention": "Preventive measure",
        "treatment": "Product@dosage e.g., Chlorpyrifos 2.5ml/liter"
      }
    ],
    "preventiveMeasures": "Field sanitation, crop rotation details",
    "organicMethods": "Neem oil@ppm or natural alternatives",
    "chemicalOption": "Last resort with safety measures"
  },
  "tamilNaduSchemes": [
    "Pradhan Mantri Fasal Bima Yojana",
    "Tamil Nadu Soil Health Card Scheme",
    "Irrigation subsidy details"
  ],
  "estimatedInvestment": "₹X per hectare for inputs"
}

IMPORTANT:
1. Recommend ONLY Tamil Nadu suitable crops
2. Include REAL Tamil Nadu government schemes: PMFBY, Soil Health Card, PMKSY, TN-specific schemes
3. All products must be available in Tamil Nadu markets
4. Realistic yield increase (10-20% is achievable)
5. Focus on soil deficiencies - recommend corrective measures
6. Return ONLY JSON, no explanations
''';
  }
}
