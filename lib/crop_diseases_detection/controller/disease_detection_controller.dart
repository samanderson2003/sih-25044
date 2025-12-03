import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/disease_result.dart';

class DiseaseDetectionController extends ChangeNotifier {
  static const String _baseUrl =
      'http://localhost:8000'; // Change for production

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
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Get available models
  Future<Map<String, dynamic>?> getAvailableModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/models'));
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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add model selection if specified
      if (modelKey != null) {
        request.fields['model'] = modelKey;
      }

      // Send request
      var streamedResponse = await request.send();
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
