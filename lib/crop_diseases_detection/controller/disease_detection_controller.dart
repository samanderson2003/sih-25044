import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/disease_result.dart';

class DiseaseDetectionController extends ChangeNotifier {
  // For Android Emulator: use 10.0.2.2
  // For Physical Device: use your computer's IP address
  // Update this IP to your computer's local IP when testing on physical device
  static const String _emulatorUrl = 'http://10.0.2.2:5001';
  static const String _physicalDeviceUrl =
      'http://192.168.5.102:5001'; // Your computer's IP

  // Connection timeout in seconds
  static const int _connectionTimeout = 15;

  // Auto-detect if running on emulator or physical device
  static String get _baseUrl {
    // On physical Android device, use the computer's IP
    // On emulator, use 10.0.2.2
    if (Platform.isAndroid) {
      // Check if running on emulator by checking build properties
      return _physicalDeviceUrl; // Change to _emulatorUrl if using Android Emulator
    }
    // For iOS simulator, localhost works directly
    return 'http://localhost:5001';
  }

  bool _isLoading = false;
  String? _error;
  DiseaseResult? _currentResult;
  List<DetectionHistory> _history = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  DiseaseResult? get currentResult => _currentResult;
  List<DetectionHistory> get history => _history;

  /// Check if API is available
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(Duration(seconds: _connectionTimeout));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Get available models
  Future<Map<String, dynamic>?> getAvailableModels() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/disease-models'))
          .timeout(Duration(seconds: _connectionTimeout));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to get models: $e');
    }
    return null;
  }

  /// Detect disease from image file
  Future<DiseaseResult?> detectDisease(
    File imageFile, {
    String? modelKey,
  }) async {
    _isLoading = true;
    _error = null;
    _currentResult = null;
    notifyListeners();

    try {
      debugPrint('🔗 Connecting to: $_baseUrl/api/detect-disease');
      debugPrint('📝 Model key: ${modelKey ?? "default"}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/detect-disease'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add model selection if specified
      if (modelKey != null) {
        request.fields['model'] = modelKey;
      }

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        Duration(seconds: _connectionTimeout),
        onTimeout: () {
          throw Exception(
            'Connection timed out. Please ensure the detection server is running.',
          );
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _currentResult = DiseaseResult.fromJson(data);

        // Add to history
        _history.insert(
          0,
          DetectionHistory(
            result: _currentResult!,
            imagePath: imageFile.path,
            timestamp: DateTime.now(),
          ),
        );

        // Keep only last 20 items
        if (_history.length > 20) {
          _history = _history.take(20).toList();
        }

        _error = null;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['detail'] ?? 'Detection failed';
        _currentResult = null;
      }
    } catch (e) {
      _error = 'Failed to connect to detection service: $e';
      _currentResult = null;
      debugPrint('Detection error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentResult;
  }

  /// Clear current result
  void clearResult() {
    _currentResult = null;
    _error = null;
    notifyListeners();
  }

  /// Clear history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Remove history item
  void removeHistoryItem(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }
}

class DetectionHistory {
  final DiseaseResult result;
  final String imagePath;
  final DateTime timestamp;

  DetectionHistory({
    required this.result,
    required this.imagePath,
    required this.timestamp,
  });
}
