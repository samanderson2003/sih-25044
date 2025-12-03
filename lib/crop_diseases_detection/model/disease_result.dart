import 'package:flutter/material.dart';

class DiseaseResult {
  final String model;
  final int predictedIndex;
  final String predictedClass;
  final double confidence;
  final List<String> classes;
  final List<double> probabilities;
  final List<TopPrediction> topPredictions;

  DiseaseResult({
    required this.model,
    required this.predictedIndex,
    required this.predictedClass,
    required this.confidence,
    required this.classes,
    required this.probabilities,
    required this.topPredictions,
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      model: json['model'] as String,
      predictedIndex: json['predicted_index'] as int,
      predictedClass: json['predicted_class'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      classes: List<String>.from(json['classes'] as List),
      probabilities: (json['probabilities'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      topPredictions: (json['top'] as List)
          .map((e) => TopPrediction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isHealthy =>
      predictedClass.toLowerCase().contains('healthy') ||
      predictedClass.toLowerCase().contains('normal');

  String get severityLevel {
    if (confidence < 0.5) return 'Uncertain';
    if (isHealthy) return 'Healthy';
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  Color getSeverityColor() {
    switch (severityLevel) {
      case 'Healthy':
        return const Color(0xFF4CAF50);
      case 'High':
        return const Color(0xFFE53935);
      case 'Medium':
        return const Color(0xFFFB8C00);
      case 'Low':
        return const Color(0xFFFDD835);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

class TopPrediction {
  final String className;
  final double probability;

  TopPrediction({required this.className, required this.probability});

  factory TopPrediction.fromJson(Map<String, dynamic> json) {
    return TopPrediction(
      className: json['class'] as String,
      probability: (json['prob'] as num).toDouble(),
    );
  }
}
