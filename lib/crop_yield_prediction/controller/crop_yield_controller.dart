import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/crop_yield_model.dart';

class CropYieldController {
  // For Physical Device: use computer's IP (port 5002 to avoid macOS AirPlay conflict)
  static const String baseUrl = 'http://192.168.5.102:5002'; // Crop Yield API

  Future<CropPredictionResponse> predictCropYield(
    CropPredictionInput input,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(input.toJson()),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timeout - Please check if API server is running',
              );
            },
          );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return CropPredictionResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to predict crop yield: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to API: $e');
    }
  }

  Future<Map<String, dynamic>> checkApiHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API health check failed');
      }
    } catch (e) {
      throw Exception('Error checking API health: $e');
    }
  }
}
