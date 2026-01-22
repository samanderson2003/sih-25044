import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Comprehensive crop recommendation with detailed analysis
class ComprehensiveRecommendationService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Generate comprehensive crop recommendations with yield analysis
  static Future<Map<String, dynamic>?> generateComprehensiveRecommendations({
    required String district,
    required String soilType,
    required double soilPh,
    required double rainfallMm,
    required double currentYield,
    required String currentCrop,
    required double areaHectares,
    required double soilOrganic,
    required Map<String, dynamic> soilNutrients,
  }) async {
    try {
      debugPrint('🌾 Starting comprehensive recommendation generation...');

      final prompt = _buildComprehensivePrompt(
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
              'content': '''You are an expert agricultural consultant specializing in South India farming practices. 
You provide data-driven, practical recommendations based on soil, climate, and economic factors.
Generate ONLY valid JSON, no markdown or extra text.
Focus on proven, locally-available solutions that farmers can implement immediately.''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 3000,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'].trim();

        // Remove markdown if present
        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final recommendations = jsonDecode(content);
        debugPrint('✅ Comprehensive recommendations generated successfully');
        return recommendations;
      } else {
        debugPrint('❌ Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in comprehensive recommendations: $e');
      return null;
    }
  }

  static String _buildComprehensivePrompt({
    required String district,
    required String soilType,
    required double soilPh,
    required double rainfallMm,
    required double currentYield,
    required String currentCrop,
    required double areaHectares,
    required double soilOrganic,
    required Map<String, dynamic> soilNutrients,
  }) {
    final targetYield = currentYield * 1.10; // 10% improvement target
    final potentialYield = currentYield * 1.25; // Realistic potential
    
    return '''
FARMER DATA ANALYSIS:
- District Location: $district
- Farm Area: ${areaHectares.toStringAsFixed(2)} hectares
- Current Crop: $currentCrop
- Current Yield: ${currentYield.toStringAsFixed(2)} T/Ha
- Target Yield (10% increase): ${targetYield.toStringAsFixed(2)} T/Ha
- Realistic Potential: ${potentialYield.toStringAsFixed(2)} T/Ha

SOIL PROFILE:
- Type: $soilType
- pH Level: ${soilPh.toStringAsFixed(1)}
- Organic Carbon: ${soilOrganic.toStringAsFixed(2)}%
- Zinc: ${(soilNutrients['zinc'] as num?)?.toStringAsFixed(2) ?? 'Unknown'}%
- Iron: ${(soilNutrients['iron'] as num?)?.toStringAsFixed(2) ?? 'Unknown'}%
- Copper: ${(soilNutrients['copper'] as num?)?.toStringAsFixed(2) ?? 'Unknown'}%
- Manganese: ${(soilNutrients['manganese'] as num?)?.toStringAsFixed(2) ?? 'Unknown'}%
- Boron: ${(soilNutrients['boron'] as num?)?.toStringAsFixed(2) ?? 'Unknown'}%

CLIMATE DATA:
- Annual Rainfall: ${rainfallMm.toStringAsFixed(0)} mm
- Region Characteristics: South India agro-climate

REQUIREMENTS:
Provide a comprehensive agricultural plan as JSON with EXACTLY this structure:

{
  "yield_analysis": {
    "current_yield": $currentYield,
    "target_yield_10pct": $targetYield,
    "potential_yield": $potentialYield,
    "yield_improvement_potential": "${((potentialYield - currentYield) / currentYield * 100).toStringAsFixed(1)}%",
    "current_status": "Brief assessment of current productivity",
    "improvement_opportunities": [
      "Specific opportunity 1",
      "Specific opportunity 2",
      "Specific opportunity 3"
    ]
  },
  
  "best_crop_alternatives": [
    {
      "crop_name": "Crop Name",
      "suitability_score": "1-10",
      "expected_yield": X.XX,
      "market_demand": "High/Medium/Low",
      "profitability": "₹XXXXX per hectare",
      "growing_season_months": 5,
      "water_requirement_mm": 600,
      "reason": "Why this crop is suitable for this soil/climate",
      "risks": ["Risk 1", "Risk 2"],
      "success_probability": "85%"
    },
    {
      "crop_name": "Alternative Crop",
      "suitability_score": "1-10",
      "expected_yield": X.XX,
      "market_demand": "High/Medium/Low",
      "profitability": "₹XXXXX per hectare",
      "growing_season_months": 4,
      "water_requirement_mm": 500,
      "reason": "Why this crop is suitable",
      "risks": ["Risk 1"],
      "success_probability": "80%"
    },
    {
      "crop_name": "Third Alternative",
      "suitability_score": "1-10",
      "expected_yield": X.XX,
      "market_demand": "High/Medium/Low",
      "profitability": "₹XXXXX per hectare",
      "growing_season_months": 6,
      "water_requirement_mm": 700,
      "reason": "Diverse option",
      "risks": ["Risk 1"],
      "success_probability": "75%"
    }
  ],

  "recommended_management_plan": {
    "fertilizer_strategy": {
      "standard_option": {
        "stage": "Application Stage",
        "nitrogen_kg_ha": XX,
        "phosphorus_kg_ha": XX,
        "potassium_kg_ha": XX,
        "product_examples": ["Product 1", "Product 2"],
        "cost_per_ha": "₹XXXX",
        "expected_yield_impact": "+X%"
      },
      "organic_option": {
        "stage": "Application Stage",
        "products": ["Organic input 1", "Organic input 2"],
        "application_rate": "XX kg/ha",
        "cost_per_ha": "₹XXXX",
        "expected_yield_impact": "+X%",
        "note": "Suitable for certified organic farming"
      }
    },

    "pest_control_strategy": {
      "standard_option": {
        "pest_name": "Major Pest",
        "treatment": "Chemical/Biological solution",
        "product_recommendation": "Specific product with dosage",
        "cost": "₹XXXX",
        "timing": "Days after planting",
        "effectiveness": "90%"
      },
      "organic_option": {
        "pest_name": "Major Pest",
        "treatment": "Organic/Bio solution",
        "product_recommendation": "Neem/Biological agent",
        "cost": "₹XXXX",
        "timing": "Days after planting",
        "effectiveness": "75%"
      }
    },

    "irrigation_strategy": {
      "standard_option": {
        "method": "Irrigation method (Drip/Flood/Sprinkler)",
        "water_requirement_mm": XXX,
        "critical_growth_stages": ["Stage 1", "Stage 2"],
        "irrigation_schedule": "Detailed schedule with dates",
        "cost_per_ha": "₹XXXX",
        "water_savings": "X% compared to flood"
      },
      "organic_option": {
        "method": "Water-efficient organic method",
        "mulching": "Yes/No with details",
        "water_requirement_mm": XXX,
        "cost_per_ha": "₹XXXX",
        "note": "Environmentally sustainable approach"
      }
    }
  },

  "economic_analysis": {
    "investment_required": {
      "standard_approach": "₹XXXXX per hectare",
      "organic_approach": "₹XXXXX per hectare"
    },
    "expected_income": {
      "current_crop": "₹XXXXX",
      "recommended_crop": "₹XXXXX",
      "improvement": "₹XXXXX (+X%)"
    },
    "break_even_period": "X months",
    "roi": "X% per season",
    "payback_period": "X months"
  },

  "implementation_timeline": [
    {
      "phase": "Month 1: Preparation",
      "tasks": ["Task 1", "Task 2"]
    },
    {
      "phase": "Month 2-3: Planting",
      "tasks": ["Task 1", "Task 2"]
    }
  ],

  "risk_mitigation": {
    "weather_risk": "Mitigation strategy",
    "market_risk": "Price support/contract farming option",
    "pest_outbreak": "Emergency response plan",
    "financial_risk": "Insurance options available"
  },

  "success_factors": [
    "Critical factor 1",
    "Critical factor 2",
    "Critical factor 3"
  ]
}

IMPORTANT GUIDELINES:
1. All recommendations MUST be suitable for South India climate and soil
2. Include BOTH standard (conventional) AND organic options for each strategy
3. All costs should be realistic and based on current market prices
4. Yield improvements should be achievable and measurable
5. Suggest 3 best alternative crops ranked by suitability
6. Provide specific product names available in the region
7. Include detailed cost-benefit analysis
8. Do NOT explicitly mention any specific state - use regional characteristics instead
9. Focus on practical, implementable solutions
10. Include risk assessment and mitigation strategies

Return ONLY the JSON object with no additional text.
''';
  }
}
