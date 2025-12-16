import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model for product recommendation
class ProductRecommendation {
  final String productName;
  final String governmentScheme;
  final String description;
  final String applicationMethod;
  final String imageFilename;
  final String estimatedCost;

  ProductRecommendation({
    required this.productName,
    required this.governmentScheme,
    required this.description,
    required this.applicationMethod,
    required this.imageFilename,
    required this.estimatedCost,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      productName: json['productName'] ?? 'Not specified',
      governmentScheme: json['governmentScheme'] ?? 'General Market',
      description: json['description'] ?? '',
      applicationMethod: json['applicationMethod'] ?? '',
      imageFilename: json['imageFilename'] ?? 'default.png',
      estimatedCost: json['estimatedCost'] ?? 'Contact dealer',
    );
  }

  // Get full asset path based on product type
  String getAssetPath(String productType) {
    return 'assets/$productType/$imageFilename';
  }
}

class OpenAIService {
  static const String _apiKey =
      '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';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Get 10% yield improvement recommendations for farmers
  static Future<Map<String, List<ProductRecommendation>>>
  get10PercentYieldGuide({
    required String cropName,
    required String district,
    required String soilType,
    required double currentYield,
  }) async {
    try {
      final targetYield = currentYield * 1.10;
      final prompt =
          '''
You are an agricultural expert for Odisha, India. A farmer grows $cropName in $district with $soilType soil, current yield: ${currentYield.toStringAsFixed(2)} T/Ha.

Recommend 3 specific products (PEST CONTROL, FERTILIZER, IRRIGATION) to increase yield from ${currentYield.toStringAsFixed(2)} to ${targetYield.toStringAsFixed(2)} T/Ha (10% increase).

IMPORTANT RULES:
1. Only recommend products available in Odisha (government or local market)
2. Prefer Odisha Government schemes/brands
3. Each product MUST have an image filename that exists in the assets folder
4. Keep descriptions simple for farmers (2-3 sentences in simple language)

Available product images:
PEST: neem_oil.png, chlorpyrifos.png, monocrotophos.png, malathion.png
FERTILIZER: npk_fertilizer.png, urea.png, dap.png, potash.png, organic_manure.png
IRRIGATION: drip_irrigation.png, sprinkler.png, pvc_pipes.png, water_pump.png

Return ONLY valid JSON (no markdown):
{
  "pestControl": [
    {
      "productName": "Product name",
      "governmentScheme": "Scheme/General Market",
      "description": "Simple 2-3 sentence description how it helps 10% yield",
      "applicationMethod": "When and how to use in farmer language",
      "imageFilename": "exact_filename.png",
      "estimatedCost": "₹XXX per acre"
    }
  ],
  "fertilizer": [... same structure ...],
  "irrigation": [... same structure ...]
}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an Odisha agricultural expert. Return ONLY valid JSON, no markdown or extra text. Recommend only locally available products.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 1200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'].trim();

        // Remove markdown if present
        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> jsonData = jsonDecode(content);
        print('✅ OpenAI 10% Yield Guide received');

        return {
          'pestControl': (jsonData['pestControl'] as List)
              .map((e) => ProductRecommendation.fromJson(e))
              .toList(),
          'fertilizer': (jsonData['fertilizer'] as List)
              .map((e) => ProductRecommendation.fromJson(e))
              .toList(),
          'irrigation': (jsonData['irrigation'] as List)
              .map((e) => ProductRecommendation.fromJson(e))
              .toList(),
        };
      } else {
        print('❌ OpenAI Error: ${response.statusCode} - ${response.body}');
        return _getFallbackRecommendations();
      }
    } catch (e) {
      print('❌ Error in 10% Yield Guide: $e');
      return _getFallbackRecommendations();
    }
  }

  static Map<String, List<ProductRecommendation>>
  _getFallbackRecommendations() {
    return {
      'pestControl': [
        ProductRecommendation(
          productName: 'Neem Oil Organic Spray',
          governmentScheme: 'Available at Govt. Agriculture Centers',
          description:
              'Natural pest control protects crops from insects and diseases. Safe for plants and increases healthy growth by 10-12%.',
          applicationMethod:
              'Mix 5ml with 1L water. Spray every 15 days on leaves in evening.',
          imageFilename: 'neem_oil.png',
          estimatedCost: '₹150 per liter',
        ),
      ],
      'fertilizer': [
        ProductRecommendation(
          productName: 'NPK 19:19:19 Complex',
          governmentScheme: 'IFFCO/Coromandel Brands',
          description:
              'Balanced nutrients for healthy plant growth. Boosts flowering and fruiting, increasing yield by 12-15%.',
          applicationMethod:
              'Apply 50kg per acre during flowering. Mix in soil near plant roots.',
          imageFilename: 'npk_fertilizer.png',
          estimatedCost: '₹800 per 50kg bag',
        ),
      ],
      'irrigation': [
        ProductRecommendation(
          productName: 'Drip Irrigation Kit',
          governmentScheme: 'PMKSY Subsidy 90%',
          description:
              'Saves 40% water and gives direct root watering. Steady moisture increases yield by 15-20%.',
          applicationMethod:
              'Install drip lines along plant rows. Water 1 hour daily in morning.',
          imageFilename: 'drip_irrigation.png',
          estimatedCost: '₹25,000 per acre (90% subsidy available)',
        ),
      ],
    };
  }

  /// Generate dynamic recommendations using OpenAI
  /// Combines ML prediction, Excel variety data, weather, soil, and date context
  Future<Map<String, dynamic>> generateDynamicRecommendations({
    required Map<String, dynamic> mlPrediction,
    required Map<String, dynamic> varietyData,
    required Map<String, dynamic> farmData,
    required String selectedVariety,
    required String district,
  }) async {
    try {
      final prompt = _buildPrompt(
        mlPrediction: mlPrediction,
        varietyData: varietyData,
        farmData: farmData,
        selectedVariety: selectedVariety,
        district: district,
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert agricultural advisor for Odisha Government, specializing in crop management, fertilizers, irrigation, and pest control. Provide practical, local, farmer-friendly recommendations in simple language.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Parse the JSON response from LLM
        return _parseRecommendations(content);
      } else {
        print('❌ OpenAI API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception(
          'Failed to get recommendations: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ OpenAI Service Error: $e');
      rethrow;
    }
  }

  String _buildPrompt({
    required Map<String, dynamic> mlPrediction,
    required Map<String, dynamic> varietyData,
    required Map<String, dynamic> farmData,
    required String selectedVariety,
    required String district,
  }) {
    final currentDate = DateTime.now();
    final season = _getSeason(currentDate.month);

    return '''
**CONTEXT: Odisha Government Agricultural Advisory**
Date: ${currentDate.day}/${currentDate.month}/${currentDate.year}
Season: $season
District: $district

**ML MODEL PREDICTION:**
- Crop: ${mlPrediction['crop']} ($selectedVariety)
- Expected Yield: ${mlPrediction['yield_forecast']} tonnes
- Confidence: ${mlPrediction['confidence_level']}%
- Economic Estimate: ₹${mlPrediction['min_income']}-${mlPrediction['max_income']}

**FARM DATA:**
- Area: ${farmData['area']} acres
- Soil pH: ${farmData['soil_ph']}
- Soil Organic Carbon: ${farmData['soil_organic_carbon']}%
- Average Temperature: ${farmData['tavg_climate']}°C
- Min/Max Temp: ${farmData['tmin_climate']}°C / ${farmData['tmax_climate']}°C
- Annual Rainfall: ${farmData['prcp_annual_climate']}mm
- Zinc: ${farmData['zn %']}%, Iron: ${farmData['fe%']}%, Copper: ${farmData['cu %']}%
- Manganese: ${farmData['mn %']}%, Boron: ${farmData['b %']}%, Sulfur: ${farmData['s %']}%

**VARIETY-SPECIFIC DATA (from Excel):**
- NDVI Mean: ${varietyData['ndvi'] ?? 'N/A'}
- Soil Texture: ${varietyData['soil_texture'] ?? 'N/A'}
- Elevation: ${varietyData['elevation'] ?? 'N/A'}m
- Regional Avg Rainfall: ${varietyData['rainfall'] ?? 'N/A'}mm

**TASK:**
Generate PRACTICAL, DATE-AWARE recommendations for Odisha farmers. Return ONLY a valid JSON object (no markdown, no code blocks) with this exact structure:

{
  "fertilizer_stages": [
    {
      "day": 0,
      "stage": "Basal Application",
      "icon": "eco",
      "products": [
        {"name": "Product Name", "qty": "XX kg/acre", "price": "₹XXX", "brand": "IFFCO/Coromandel/Local"},
        ...
      ],
      "tips": [
        "Tip 1 with current date/weather consideration",
        "Tip 2 specific to $selectedVariety variety",
        "Tip 3 for $district district soil"
      ],
      "importance": "HIGH",
      "application_date": "DD MMM YYYY"
    },
    ... (4-5 stages: Basal, Tillering, Panicle, Flowering)
  ],
  "irrigation_stages": [
    {
      "stage": "Seedling Stage (Day 1-20)",
      "waterLevel": "2-3 inches",
      "frequency": "Every 3-4 days",
      "critical": true,
      "products": [
        {"name": "Jain Drip Kit", "price": "₹28,000"},
        {"name": "Kirloskar 1HP Pump", "price": "₹12,000"}
      ],
      "tips": [
        "Current rainfall: ${farmData['prcp_annual_climate']}mm - adjust accordingly",
        "Soil moisture tip for ${varietyData['soil_texture']} soil"
      ],
      "growth_stage_days": "1-20"
    },
    ... (5-6 growth stages)
  ],
  "pest_control": [
    {
      "pest": "Stem Borer",
      "risk_level": "HIGH/MEDIUM/LOW",
      "timing": "Week 3-5",
      "preventive": [
        "Light trap installation (best in $season)",
        "Pheromone traps for $selectedVariety"
      ],
      "treatment": [
        {"name": "Product", "dosage": "XX ml/acre", "price": "₹XXX", "type": "Organic/Chemical"}
      ],
      "monitoring": "Check every 3 days during peak season"
    },
    ... (3-5 major pests)
  ],
  "weather_advisory": "Based on current date ${currentDate.day}/${currentDate.month} and rainfall ${farmData['prcp_annual_climate']}mm, specific advice...",
  "variety_specific_tips": [
    "Tip 1 unique to $selectedVariety variety",
    "Tip 2 for current growth stage",
    "Tip 3 for soil deficiency (Zn: ${farmData['zn %']}%, Fe: ${farmData['fe%']}%)"
  ]
}

**REQUIREMENTS:**
1. Use REAL Odisha brands: IFFCO, Coromandel, Rashtriya Chemicals, Jain Irrigation, Kirloskar
2. Base fertilizer timing on CURRENT DATE and crop cycle
3. Adjust irrigation based on ACTUAL rainfall data (${farmData['prcp_annual_climate']}mm)
4. Consider soil deficiencies (low Zn/Fe need micronutrient supplements)
5. Give variety-specific advice for $selectedVariety
6. Include district-specific considerations for $district
7. Return ONLY valid JSON, no markdown formatting
''';
  }

  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Summer (Zaid)';
    if (month >= 6 && month <= 9) return 'Kharif (Monsoon)';
    if (month >= 10 && month <= 11) return 'Rabi (Winter)';
    return 'Rabi (Winter)';
  }

  Map<String, dynamic> _parseRecommendations(String content) {
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

      return json.decode(cleaned.trim());
    } catch (e) {
      print('❌ Failed to parse LLM response: $e');
      print('Content: $content');
      rethrow;
    }
  }
}
