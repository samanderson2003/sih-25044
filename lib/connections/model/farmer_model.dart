import 'package:cloud_firestore/cloud_firestore.dart';

class ManualAlert {
  final String message;
  final String type; // 'Crop', 'Livestock', 'General'
  final double radius;
  final DateTime timestamp;
  final String? imageUrl;
  final String? disease;
  final double? confidence;

  ManualAlert({
    required this.message,
    required this.type,
    required this.radius,
    required this.timestamp,
    this.imageUrl,
    this.disease,
    this.confidence,
  });

  factory ManualAlert.fromMap(Map<String, dynamic> map) {
    return ManualAlert(
      message: map['message'] ?? '',
      type: map['type'] ?? 'General',
      radius: (map['radius'] as num?)?.toDouble() ?? 500.0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      disease: map['disease'],
      confidence: (map['confidence'] as num?)?.toDouble(),
    );
  }
}

class FarmerProfile {
  final String id;
  final String name;
  final String phoneNumber;
  final bool phoneVisible;
  final double latitude;
  final double longitude;
  final bool exactLocationVisible;
  final String village;
  final String district;
  final String currentCrop;
  final String soilHealthStatus;
  final String irrigationMethod;
  final List<String> riskAlerts;
  final List<ManualAlert> structuredAlerts; // New structured alerts
  final CropPredictionData? latestPrediction;
  final String? profileImage;
  final bool isFollowing;

  // Livestock data
  final int livestockCount;

  // Satellite-based crop health monitoring
  final bool? stressDetected;
  final String? healthStatus; // 'healthy', 'moderate', 'stressed', 'unknown'
  final String?
  stressType; // 'disease_or_pest', 'water_stress', 'early_stress', 'none', 'unknown'
  final double? confidence;
  final double? ndviMean;
  final double? ndreMean;
  final double? ndwiMean;
  final double? saviMean;
  final List<String>? healthIndicators;
  final List<String>? recommendations;
  final String? disclaimer;

  // Computed properties for filtering
  bool get hasCrop => currentCrop.isNotEmpty && currentCrop != 'Not Specified';
  bool get hasLivestock => livestockCount > 0;
  bool get hasRiskAlerts => riskAlerts.isNotEmpty || structuredAlerts.isNotEmpty;

  FarmerProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.phoneVisible = false,
    required this.latitude,
    required this.longitude,
    this.exactLocationVisible = true,
    required this.village,
    required this.district,
    required this.currentCrop,
    required this.soilHealthStatus,
    required this.irrigationMethod,
    this.riskAlerts = const [],
    this.structuredAlerts = const [],
    this.latestPrediction,
    this.profileImage,
    this.isFollowing = false,
    this.livestockCount = 0,
    this.stressDetected,
    this.healthStatus,
    this.stressType,
    this.confidence,
    this.ndviMean,
    this.ndreMean,
    this.ndwiMean,
    this.saviMean,
    this.healthIndicators,
    this.recommendations,
    this.disclaimer,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      phoneVisible: json['phoneVisible'] ?? false,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      exactLocationVisible: json['exactLocationVisible'] ?? true,
      village: json['village'] ?? '',
      district: json['district'] ?? '',
      currentCrop: json['currentCrop'] ?? '',
      soilHealthStatus: json['soilHealthStatus'] ?? '',
      irrigationMethod: json['irrigationMethod'] ?? '',
      riskAlerts: List<String>.from(json['riskAlerts'] ?? []),
      structuredAlerts: json['structuredAlerts'] != null
          ? (json['structuredAlerts'] as List)
              .map((e) => ManualAlert.fromMap(e as Map<String, dynamic>))
              .toList()
          : [],
      latestPrediction: json['latestPrediction'] != null
          ? CropPredictionData.fromJson(json['latestPrediction'])
          : null,
      profileImage: json['profileImage'],
      isFollowing: json['isFollowing'] ?? false,
      livestockCount: json['livestockCount'] ?? 0,
      stressDetected: json['stressDetected'],
      healthStatus: json['healthStatus'],
      stressType: json['stressType'],
      confidence: json['confidence']?.toDouble(),
      ndviMean: json['ndviMean']?.toDouble(),
      ndreMean: json['ndreMean']?.toDouble(),
      ndwiMean: json['ndwiMean']?.toDouble(),
      saviMean: json['saviMean']?.toDouble(),
      healthIndicators: json['healthIndicators'] != null
          ? List<String>.from(json['healthIndicators'])
          : null,
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : null,
      disclaimer: json['disclaimer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'phoneVisible': phoneVisible,
      'latitude': latitude,
      'longitude': longitude,
      'exactLocationVisible': exactLocationVisible,
      'village': village,
      'district': district,
      'currentCrop': currentCrop,
      'soilHealthStatus': soilHealthStatus,
      'irrigationMethod': irrigationMethod,
      'riskAlerts': riskAlerts,
      'structuredAlerts': structuredAlerts.map((e) => {
        'message': e.message,
        'type': e.type,
        'radius': e.radius,
        'timestamp': Timestamp.fromDate(e.timestamp),
        'imageUrl': e.imageUrl,
        'disease': e.disease,
        'confidence': e.confidence,
      }).toList(),
      'latestPrediction': latestPrediction?.toJson(),
      'profileImage': profileImage,
      'isFollowing': isFollowing,
      'livestockCount': livestockCount,
      'stressDetected': stressDetected,
      'healthStatus': healthStatus,
      'stressType': stressType,
      'confidence': confidence,
      'ndviMean': ndviMean,
      'ndreMean': ndreMean,
      'ndwiMean': ndwiMean,
      'saviMean': saviMean,
      'healthIndicators': healthIndicators,
      'recommendations': recommendations,
      'disclaimer': disclaimer,
    };
  }
}

class CropPredictionData {
  final double estimatedYield;
  final String growthPhase;
  final String weatherRisk;
  final DateTime predictionDate;

  CropPredictionData({
    required this.estimatedYield,
    required this.growthPhase,
    required this.weatherRisk,
    required this.predictionDate,
  });

  factory CropPredictionData.fromJson(Map<String, dynamic> json) {
    return CropPredictionData(
      estimatedYield: (json['estimatedYield'] ?? 0.0).toDouble(),
      growthPhase: json['growthPhase'] ?? '',
      weatherRisk: json['weatherRisk'] ?? '',
      predictionDate: DateTime.parse(
        json['predictionDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimatedYield': estimatedYield,
      'growthPhase': growthPhase,
      'weatherRisk': weatherRisk,
      'predictionDate': predictionDate.toIso8601String(),
    };
  }
}
