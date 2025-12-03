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
  final CropPredictionData? latestPrediction;
  final String? profileImage;
  final bool isFollowing;

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
    this.latestPrediction,
    this.profileImage,
    this.isFollowing = false,
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
      latestPrediction: json['latestPrediction'] != null
          ? CropPredictionData.fromJson(json['latestPrediction'])
          : null,
      profileImage: json['profileImage'],
      isFollowing: json['isFollowing'] ?? false,
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
      'latestPrediction': latestPrediction?.toJson(),
      'profileImage': profileImage,
      'isFollowing': isFollowing,
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
