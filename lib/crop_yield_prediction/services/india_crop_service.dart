import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for getting India-specific crops and their inputs
class IndiaCropService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Get list of crops suitable for Indian farming
  static Future<List<Map<String, dynamic>>?> getIndianCrops({
    required String soilType,
    required double soilPh,
    required double rainfallMm,
    required String region,
  }) async {
    try {
      debugPrint('🌾 Fetching Indian crops for region: $region...');

      final prompt = '''You are an expert in Indian agriculture. Based on the farmer's soil and climate conditions, suggest the TOP 10 MOST SUITABLE CROPS available in India.

FARM CONDITIONS:
- Soil Type: $soilType
- pH Level: ${soilPh.toStringAsFixed(1)}
- Annual Rainfall: ${rainfallMm.toStringAsFixed(0)} mm
- Region: South India

Return ONLY a JSON array with this structure (NO markdown, NO extra text):
[
  {
    "crop_name": "Rice",
    "hindi_name": "धान",
    "suitability_score": 9,
    "water_requirement": "1200-1500 mm",
    "growing_season": "4-5 months",
    "yield_potential": "5-7 tons/hectare",
    "market_demand": "Very High",
    "major_use": "Food grain"
  },
  {
    "crop_name": "Sugarcane",
    "hindi_name": "गन्ना",
    "suitability_score": 8,
    "water_requirement": "1200-1500 mm",
    "growing_season": "12 months",
    "yield_potential": "60-80 tons/hectare",
    "market_demand": "High",
    "major_use": "Sugar/Industrial"
  }
]

IMPORTANT:
1. Include ONLY crops officially grown in India
2. Rank by suitability for the given soil and climate
3. Include Hindi names for better farmer understanding
4. Provide realistic yield potentials for Indian conditions
5. All crops must be commercially viable in Indian market
6. Include crops from various categories (cereals, pulses, cash crops, vegetables)
''';

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
              'content':
                  'You are an expert in Indian agriculture. Return ONLY valid JSON array, no markdown.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'].trim();

        // Remove markdown if present
        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .replaceAll('```dart', '')
            .trim();

        final crops = jsonDecode(content) as List;
        debugPrint('✅ Fetched ${crops.length} Indian crops');
        return crops.map((c) => c as Map<String, dynamic>).toList();
      } else {
        debugPrint('❌ Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching Indian crops: $e');
      return null;
    }
  }

  /// Get Indian fertilizers and pesticides for a specific crop
  static Future<Map<String, dynamic>?> getIndianInputsForCrop({
    required String cropName,
    required String soilType,
    required double soilPh,
    required double currentYield,
  }) async {
    try {
      debugPrint('🌾 Fetching Indian inputs for crop: $cropName...');

      final prompt = '''You are an expert in Indian agricultural inputs and farming practices. Based on the farmer's conditions, recommend SPECIFIC FERTILIZERS AND PESTICIDES officially available and registered in India.

CROP AND FARM DATA:
- Crop: $cropName
- Soil Type: $soilType
- pH Level: ${soilPh.toStringAsFixed(1)}
- Current Yield: ${currentYield.toStringAsFixed(2)} tons/hectare

Return ONLY a JSON object with this structure (NO markdown, NO extra text):
{
  "crop_name": "$cropName",
  "recommended_fertilizers": {
    "standard_products": [
      {
        "product_name": "DAP (Di-Ammonium Phosphate)",
        "composition": "18:46:0 (N:P:K)",
        "application_stage": "Pre-sowing/Basal application",
        "dose_per_hectare": "200-250 kg",
        "timing": "15 days before planting",
        "cost_approx": "₹4000-5000 per 50kg bag",
        "availability": "Widely available across India",
        "yield_increase_potential": "+15-20%",
        "approved_by": "Department of Fertilizers, India"
      },
      {
        "product_name": "Urea",
        "composition": "46:0:0 (N:P:K)",
        "application_stage": "Top-dressing in splits",
        "dose_per_hectare": "100-150 kg",
        "timing": "At tillering, ear initiation, grain filling",
        "cost_approx": "₹6000-7000 per 50kg bag",
        "availability": "Universal availability",
        "yield_increase_potential": "+10-15%",
        "approved_by": "Department of Fertilizers, India"
      }
    ],
    "organic_alternatives": [
      {
        "product_name": "Neem Cake",
        "composition": "Organic nitrogen (3-5%)",
        "application_stage": "Basal application",
        "dose_per_hectare": "2-2.5 tons",
        "timing": "At field preparation",
        "cost_approx": "₹8000-10000 per ton",
        "availability": "Available through agricultural cooperatives",
        "yield_increase_potential": "+8-12%",
        "certified_organic": true
      }
    ],
    "micronutrient_boosters": [
      {
        "product_name": "Zinc Sulfate (ZnSO4)",
        "composition": "Zinc 21%",
        "dose_per_hectare": "10-25 kg",
        "deficiency_symptoms": "Stunted growth, pale leaves",
        "cost_approx": "₹200-300 per kg",
        "approved_by": "NITI Aayog"
      }
    ]
  },
  "recommended_pesticides": {
    "insecticides": [
      {
        "pest_name": "Army Worm",
        "product_name": "Chlorpyriphos 20% EC",
        "trade_names": ["Dursban", "Chlor-20"],
        "dose": "1.5 liters per hectare",
        "water_required": "600-800 liters",
        "application_frequency": "Once every 10-14 days",
        "waiting_period_days": 14,
        "cost_approx": "₹250-350 per liter",
        "registered_with": "ICAR, Ministry of Agriculture",
        "approved_for": "Food crops",
        "organic_alternative": "Bacillus thuringiensis (Bt spray)"
      }
    ],
    "fungicides": [
      {
        "disease_name": "Leaf Spot",
        "product_name": "Carbendazim 50% WP",
        "trade_names": ["Bavistin", "Carbasan"],
        "dose": "1 kg per hectare",
        "water_required": "600 liters",
        "application_frequency": "Every 10-15 days",
        "waiting_period_days": 7,
        "cost_approx": "₹200-250 per kg",
        "registered_with": "ICAR, India",
        "approved_for": "All crops",
        "organic_alternative": "Bordeaux mixture (1%)"
      }
    ],
    "organic_bioagents": [
      {
        "pest_type": "General pest control",
        "product_name": "Trichoderma viride",
        "application_stage": "Soil treatment at sowing",
        "dose": "2.5 kg per hectare",
        "cost_approx": "₹500-800 per kg",
        "availability": "ICAR institutes, agricultural universities",
        "benefits": "Soil health improvement, pest suppression",
        "certified_organic": true
      }
    ]
  },
  "integrated_pest_management": {
    "cultural_practices": [
      "Practice crop rotation",
      "Use resistant varieties",
      "Proper field sanitation"
    ],
    "monitoring_protocol": "Weekly scouting for pest presence",
    "threshold_for_action": "Economic injury level based on pest count",
    "safety_guidelines": "Always follow label instructions and wear PPE"
  },
  "government_schemes_and_subsidies": {
    "fertilizer_subsidy": "Government provides subsidy on DAP, Urea, MOP",
    "pest_management_scheme": "PMKSY component for plant protection",
    "approved_products_list": "Ministry of Agriculture & Farmers Welfare",
    "registration_database": "CIB & RC (Central Insecticide Board & Registration Committee)"
  },
  "expected_yield_improvement": {
    "with_recommended_inputs": "${(currentYield * 1.15).toStringAsFixed(2)} tons/hectare",
    "improvement_percentage": "15% increase",
    "total_investment": "₹15000-20000 per hectare",
    "roi_months": "3-4 months"
  }
}

IMPORTANT GUIDELINES:
1. ONLY recommend products officially registered in India
2. Include trade names commonly used by Indian farmers
3. Provide realistic Indian market prices
4. Include Ministry/Department approval information
5. Always provide organic alternatives
6. Include safety guidelines and waiting periods
7. Reference official databases (ICAR, CIB & RC)
8. Provide dosages in units used by Indian farmers
9. Include subsidy information where applicable
10. Focus on commercially available products in Indian markets
''';

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
              'content':
                  'You are an expert in Indian agriculture and authorized agricultural inputs. Return ONLY valid JSON, no markdown.',
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
            .replaceAll('```dart', '')
            .trim();

        final inputs = jsonDecode(content);
        debugPrint('✅ Fetched Indian inputs for $cropName');
        return inputs as Map<String, dynamic>;
      } else {
        debugPrint('❌ Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching Indian inputs: $e');
      return null;
    }
  }
}
