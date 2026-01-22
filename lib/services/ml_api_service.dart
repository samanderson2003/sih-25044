// ml_api_service.dart - Connect Flutter to Python ML API
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_service.dart';
import 'crop_recommendation_service.dart';
import '../crop_yield_prediction/services/comprehensive_recommendation_service.dart';

class MLApiService {
  // Android Emulator: Use 10.0.2.2 (maps to host's localhost)
  // Physical Device: Use your Mac's IP with ML server port 8000
  // ML Server runs on: http://192.168.137.33:8000
  static const String baseUrl =
      'http://192.168.137.33:8000'; // Crop Yield ML API

  // For Android emulator testing, use:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  /// Check if API server is running
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' && data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('❌ API Health Check Failed: $e');
      return false;
    }
  }

  /// Get intelligent daily actions for a specific date
  static Future<Map<String, dynamic>?> getDailyActions({
    required Map<String, dynamic> farmData,
    String? targetDate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/daily-actions'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'farm_data': farmData,
              'target_date':
                  targetDate ?? DateTime.now().toIso8601String().split('T')[0],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
          '❌ Daily Actions Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Daily Actions Request Failed: $e');
      return null;
    }
  }

  /// Get ML-powered yield prediction
  static Future<Map<String, dynamic>?> predictYield({
    required Map<String, dynamic> farmData,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'), // FastAPI endpoint
            headers: {'Content-Type': 'application/json'},
            body: json.encode(farmData), // Send farmData directly, not wrapped
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
          '❌ Yield Prediction Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Yield Prediction Request Failed: $e');
      return null;
    }
  }

  /// Get comprehensive plan: daily actions + yield + economics
  static Future<Map<String, dynamic>?> getComprehensivePlan({
    required Map<String, dynamic> farmData,
    String? targetDate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/comprehensive-plan'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'farm_data': farmData,
              'target_date':
                  targetDate ?? DateTime.now().toIso8601String().split('T')[0],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
          '❌ Comprehensive Plan Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Comprehensive Plan Request Failed: $e');
      return null;
    }
  }

  /// NEW: Get AI-powered recommendations using OpenAI (bypasses ML backend)
  /// This directly calls OpenAI with the farm data to generate Tamil Nadu specific recommendations
  static Future<Map<String, dynamic>?> getAgriAIRecommendations({
    required Map<String, dynamic> farmInput,
  }) async {
    try {
      print('🔍 ===== OPENAI AGRI-AI RECOMMENDATIONS START =====');
      print('📡 Input Parameters:');
      farmInput.forEach((key, value) {
        print('   $key: $value');
      });

      // Extract data from farmInput
      final district = farmInput['district'] as String? ?? 'Tamil Nadu';
      final soilType = farmInput['soil_type'] as String? ?? 'Loam';
      final rainMm = farmInput['rain_mm'] as double? ?? 1200.0;
      final tempC = farmInput['temp_c'] as double? ?? 28.0;
      final ph = farmInput['ph'] as double? ?? 6.5;
      final areaAcres = farmInput['area_acres'] as double? ?? 1.0;
      final soc = farmInput['soc'] as double? ?? 0.5;
      final ndviMax = farmInput['ndvi_max'] as double? ?? 0.7;
      final eviMax = farmInput['evi_max'] as double? ?? 4200.0;
      final elevation = farmInput['elevation'] as double? ?? 276.0;

      print('✅ Extracted farm parameters successfully');

      // Build context for OpenAI
      final farmData = {
        'district': district,
        'soil_ph': ph,
        'soil_organic_carbon': soc,
        'tavg_climate': tempC,
        'tmin_climate': tempC - 5,
        'tmax_climate': tempC + 5,
        'prcp_annual_climate': rainMm,
        'elevation': elevation,
        'area': areaAcres,
        'zn %': 0.8,
        'fe%': 0.9,
        'cu %': 0.6,
        'mn %': 0.85,
        'b %': 0.5,
        's %': 0.7,
      };

      final varietyData = {
        'ndvi': ndviMax,
        'evi': eviMax,
        'soil_texture': soilType,
        'elevation': elevation,
        'rainfall': rainMm,
      };

      final mlPrediction = {
        'crop': 'Rice',
        'yield_forecast': 5.0,
        'confidence_level': 75,
        'min_income': 50000,
        'max_income': 75000,
      };

      print('📤 Calling OpenAI Service for recommendations...');

      final stopwatch = Stopwatch()..start();

      // Call OpenAI directly - use as instance method
      final openAIService = OpenAIService();
      final recommendations =
          await openAIService.generateDynamicRecommendations(
        mlPrediction: mlPrediction,
        varietyData: varietyData,
        farmData: farmData,
        selectedVariety: 'High Yield Variety',
        district: district,
      );

      stopwatch.stop();
      print('⏱️ OpenAI Response received in ${stopwatch.elapsedMilliseconds}ms');

      if (recommendations != null) {
        print('✅ Successfully generated recommendations');
        print('✅ Recommendation Keys: ${recommendations.keys.toList()}');

        // Format response to match AgriAIResponse structure
        final formattedResponse = {
          'status': 'success',
          'farm_profile': {
            'district': district,
            'soil_type': soilType,
            'area_acres': areaAcres,
            'ph': ph,
            'rainfall': rainMm,
          },
          'yield_forecast': {
            'per_hectare_tonnes': 5.0,
            'confidence_level': 75,
            'estimated_income_low': 50000,
            'estimated_income_high': 75000,
          },
          'advisory_plan': recommendations['fertilizer_stages'] ??
              recommendations['irrigation_stages'] ??
              [],
          'crops': [
            {
              'name': 'Rice',
              'yield_forecast': 5.0,
              'confidence': 75,
              'recommendations': recommendations,
            }
          ],
          'recommendations': recommendations,
          'generated_at': DateTime.now().toIso8601String(),
        };

        print('✅ Formatted response with all recommendations');
        print('🔍 ===== OPENAI AGRI-AI RECOMMENDATIONS END (SUCCESS) =====');
        return formattedResponse;
      } else {
        print('❌ OpenAI returned null response');
        throw Exception('Failed to generate recommendations from OpenAI');
      }
    } on Exception catch (e) {
      print('❌ Exception: $e');
      print('💡 Troubleshooting:');
      print('   1. Check OpenAI API key in .env file');
      print('   2. Verify API key has sufficient credits');
      print('   3. Check network connectivity');
      print('🔍 ===== OPENAI AGRI-AI RECOMMENDATIONS END (EXCEPTION) =====');
      return null;
    }
  }

  /// Helper: Convert farm data from Firestore to API format
  static Map<String, dynamic> prepareFarmDataForAPI({
    required Map<String, dynamic> farmBasics,
    required Map<String, dynamic> soilQuality,
    required Map<String, dynamic> climateData,
    String? plantingDate,
  }) {
    return {
      'crop': (farmBasics['selectedCrops'] as List<dynamic>?)?.first ?? 'Rice',
      'area': (farmBasics['landSize'] ?? 1.0) * 0.404686, // Acres to hectares
      'area_acres': farmBasics['landSize'] ?? 1.0,
      'planting_date':
          plantingDate ??
          DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String()
              .split('T')[0],
      'climate': {
        'tavg_climate': climateData['tavgClimate'] ?? 28.0,
        'tmin_climate': climateData['tminClimate'] ?? 24.0,
        'tmax_climate': climateData['tmaxClimate'] ?? 33.0,
        'prcp_annual_climate': climateData['prcpAnnualClimate'] ?? 5.0,
      },
      'soil': {
        'zn': soilQuality['zinc'] ?? 80.0,
        'fe': soilQuality['iron'] ?? 90.0,
        'cu': soilQuality['copper'] ?? 85.0,
        'mn': soilQuality['manganese'] ?? 95.0,
        'b': soilQuality['boron'] ?? 95.0,
        's': soilQuality['sulfur'] ?? 0.5,
      },
      'season': farmBasics['season'] ?? 'Kharif',
    };
  }

  /// Get AI crop recommendation for Tamil Nadu farmers
  /// Uses OpenAI to recommend best crop based on farm conditions
  static Future<CropRecommendation?> getAICropRecommendation({
    required String district,
    required String soilType,
    required double soilPh,
    required double rainfallMm,
    required double currentYield,
    required String currentCrop,
    required double areaHectares,
    required double soilOrganic,
    Map<String, double>? soilNutrients,
  }) async {
    try {
      print('🌾 ===== AI CROP RECOMMENDATION REQUEST =====');
      print('📍 District: $district');
      print('🌱 Current Crop: $currentCrop');
      print('📊 Current Yield: ${currentYield.toStringAsFixed(2)} T/Ha');

      final nutrients = soilNutrients ?? {
        'zinc': 0.8,
        'iron': 0.9,
        'copper': 0.6,
        'manganese': 0.85,
        'boron': 0.5,
      };

      final recommendation = await CropRecommendationService.recommendCrop(
        district: district,
        soilType: soilType,
        soilPh: soilPh,
        rainfallMm: rainfallMm,
        currentYield: currentYield,
        currentCrop: currentCrop,
        areaHectares: areaHectares,
        soilOrganic: soilOrganic,
        soilNutrients: nutrients,
      );

      if (recommendation != null) {
        print('✅ Recommendation received: ${recommendation.recommendedCrop}');
        print('📈 Expected yield increase: ${recommendation.expectedYieldIncrease}%');
        print('💰 Estimated investment: ${recommendation.estimatedInvestment}');
      } else {
        print('❌ No recommendation generated');
      }

      return recommendation;
    } catch (e) {
      print('❌ Error getting crop recommendation: $e');
      return null;
    }
  }

  /// Get comprehensive recommendations with detailed yield analysis
  static Future<Map<String, dynamic>?> getComprehensiveRecommendations({
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
      print('🌾 ===== COMPREHENSIVE RECOMMENDATION REQUEST START =====');
      print('📍 Location: $district');
      print('🌱 Current Crop: $currentCrop');
      print('📊 Current Yield: ${currentYield.toStringAsFixed(2)} T/Ha');

      final stopwatch = Stopwatch()..start();

      final recommendations = await ComprehensiveRecommendationService
          .generateComprehensiveRecommendations(
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

      stopwatch.stop();
      print('⏱️ Response received in ${stopwatch.elapsedMilliseconds}ms');

      if (recommendations != null) {
        print('✅ Yield Analysis:');
        final yieldAnalysis = recommendations['yield_analysis'];
        if (yieldAnalysis != null) {
          print('   Current: ${yieldAnalysis['current_yield']} T/Ha');
          print('   Target (+10%): ${yieldAnalysis['target_yield_10pct']} T/Ha');
          print('   Potential: ${yieldAnalysis['potential_yield']} T/Ha');
          print('   Improvement Potential: ${yieldAnalysis['yield_improvement_potential']}');
        }

        print('✅ Best Crop Alternatives:');
        final crops = recommendations['best_crop_alternatives'] as List?;
        if (crops != null && crops.isNotEmpty) {
          for (var i = 0; i < crops.length && i < 3; i++) {
            print('   ${i + 1}. ${crops[i]['crop_name']} - Score: ${crops[i]['suitability_score']}/10');
          }
        }

        print('✅ Economic Analysis:');
        final economics = recommendations['economic_analysis'];
        if (economics != null) {
          print('   Expected Income Improvement: ${economics['expected_income']['improvement']}');
          print('   ROI: ${economics['roi']}');
        }

        print('🌾 ===== COMPREHENSIVE RECOMMENDATION REQUEST END (SUCCESS) =====');
        return recommendations;
      } else {
        print('❌ Failed to generate recommendations');
        return null;
      }
    } catch (e) {
      print('❌ Error: $e');
      print('🌾 ===== COMPREHENSIVE RECOMMENDATION REQUEST END (ERROR) =====');
      return null;
    }
  }
}
