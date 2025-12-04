// ml_api_service.dart - Connect Flutter to Python ML API
import 'dart:convert';
import 'package:http/http.dart' as http;

class MLApiService {
  // Android Emulator: Use 10.0.2.2 (maps to host's localhost)
  // Physical Device: Use your Mac's IP (e.g., 'http://192.168.1.10:5000')
  // Find IP: System Settings > Network > Wi-Fi > Details
  static const String baseUrl = 'http://10.0.2.2:5001';

  // For physical device testing, use your Mac's IP:
  // static const String baseUrl = 'http://192.168.1.XXX:5000';

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
            Uri.parse('$baseUrl/api/predict-yield'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'farm_data': farmData}),
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
}
