// Simplified Farm Data Model - Only ML Model Required Fields
class FarmDataModel {
  final String userId;
  final FarmBasicsModel farmBasics;
  final SoilQualityModel soilQuality;
  final ClimateDataModel? climateData; // Auto-fetched from NASA API
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmDataModel({
    required this.userId,
    required this.farmBasics,
    required this.soilQuality,
    this.climateData,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'farmBasics': farmBasics.toJson(),
      'soilQuality': soilQuality.toJson(),
      'climateData': climateData?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FarmDataModel.fromJson(Map<String, dynamic> json) {
    return FarmDataModel(
      userId: json['userId'] ?? '',
      farmBasics: FarmBasicsModel.fromJson(json['farmBasics'] ?? {}),
      soilQuality: SoilQualityModel.fromJson(json['soilQuality'] ?? {}),
      climateData: json['climateData'] != null
          ? ClimateDataModel.fromJson(json['climateData'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

// Step 1: Farm & Crop Basics
class FarmBasicsModel {
  final double landSize; // in acres or cents
  final String landSizeUnit; // 'acres' or 'cents'
  final LocationModel location;
  final List<String> crops; // Multiple crops: Rice, Wheat, Maize, etc.

  FarmBasicsModel({
    required this.landSize,
    this.landSizeUnit = 'acres',
    required this.location,
    required this.crops,
  });

  // Convert to hectares for ML model
  double get landSizeInHectares {
    if (landSizeUnit == 'cents') {
      return landSize * 0.00404686; // 1 cent = 0.00404686 hectares
    } else {
      return landSize * 0.404686; // 1 acre = 0.404686 hectares
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'landSize': landSize,
      'landSizeUnit': landSizeUnit,
      'location': location.toJson(),
      'crops': crops,
    };
  }

  factory FarmBasicsModel.fromJson(Map<String, dynamic> json) {
    return FarmBasicsModel(
      landSize: (json['landSize'] ?? 0).toDouble(),
      landSizeUnit: json['landSizeUnit'] ?? 'acres',
      location: LocationModel.fromJson(json['location'] ?? {}),
      crops: json['crops'] != null ? List<String>.from(json['crops']) : [],
    );
  }
}

class LandDetailsModel {
  final double landSize; // in acres
  final String landSizeUnit; // acres, hectares
  final LocationModel location;
  final String? soilType;
  final String? irrigationType;
  final String? landTopography;

  LandDetailsModel({
    required this.landSize,
    this.landSizeUnit = 'acres',
    required this.location,
    this.soilType,
    this.irrigationType,
    this.landTopography,
  });

  Map<String, dynamic> toJson() {
    return {
      'landSize': landSize,
      'landSizeUnit': landSizeUnit,
      'location': location.toJson(),
      'soilType': soilType,
      'irrigationType': irrigationType,
      'landTopography': landTopography,
    };
  }

  factory LandDetailsModel.fromJson(Map<String, dynamic> json) {
    return LandDetailsModel(
      landSize: (json['landSize'] ?? 0).toDouble(),
      landSizeUnit: json['landSizeUnit'] ?? 'acres',
      location: LocationModel.fromJson(json['location'] ?? {}),
      soilType: json['soilType'],
      irrigationType: json['irrigationType'],
      landTopography: json['landTopography'],
    );
  }
}

class LocationModel {
  final double latitude;
  final double longitude;
  final String? state;
  final String? district;
  final String? plusCode; // Open Location Code for 4m x 4m precision

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.state,
    this.district,
    this.plusCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'district': district,
      'plusCode': plusCode,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      state: json['state'],
      district: json['district'],
      plusCode: json['plusCode'],
    );
  }
}

// Climate Data Model - Auto-fetched from NASA POWER API
class ClimateDataModel {
  final double tavgClimate; // 20-year average temperature
  final double tminClimate; // 20-year average minimum temp
  final double tmaxClimate; // 20-year average maximum temp
  final double prcpAnnualClimate; // 20-year average daily rainfall (mm)
  final DateTime fetchedAt;

  ClimateDataModel({
    required this.tavgClimate,
    required this.tminClimate,
    required this.tmaxClimate,
    required this.prcpAnnualClimate,
    required this.fetchedAt,
  });

  // Calculated field for ML model
  double get tempRangeClimate => tmaxClimate - tminClimate;

  Map<String, dynamic> toJson() {
    return {
      'tavgClimate': tavgClimate,
      'tminClimate': tminClimate,
      'tmaxClimate': tmaxClimate,
      'prcpAnnualClimate': prcpAnnualClimate,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  factory ClimateDataModel.fromJson(Map<String, dynamic> json) {
    return ClimateDataModel(
      tavgClimate: (json['tavgClimate'] ?? 0).toDouble(),
      tminClimate: (json['tminClimate'] ?? 0).toDouble(),
      tmaxClimate: (json['tmaxClimate'] ?? 0).toDouble(),
      prcpAnnualClimate: (json['prcpAnnualClimate'] ?? 0).toDouble(),
      fetchedAt: json['fetchedAt'] != null
          ? DateTime.parse(json['fetchedAt'])
          : DateTime.now(),
    );
  }
}

// Step 2: Simplified Soil Quality - Only 6 Essential Nutrients
class SoilQualityModel {
  final double? zinc; // Zn% - Required for ML
  final double? iron; // Fe% - Required for ML
  final double? copper; // Cu% - Required for ML
  final double? manganese; // Mn% - Required for ML
  final double? boron; // B% - Required for ML
  final double? sulfur; // S% - Required for ML
  final String dataSource; // 'manual', 'satellite', 'regional_default'
  final DateTime? fetchedAt;

  SoilQualityModel({
    this.zinc,
    this.iron,
    this.copper,
    this.manganese,
    this.boron,
    this.sulfur,
    this.dataSource = 'manual',
    this.fetchedAt,
  });

  // Check if all 6 essential nutrients are present
  bool get isComplete {
    return zinc != null &&
        iron != null &&
        copper != null &&
        manganese != null &&
        boron != null &&
        sulfur != null;
  }

  // Calculate nutrient index for ML model
  double get nutrientIndex {
    if (!isComplete) return 0.0;
    return (zinc! + iron! + copper!) / 3;
  }

  Map<String, dynamic> toJson() {
    return {
      'zinc': zinc,
      'iron': iron,
      'copper': copper,
      'manganese': manganese,
      'boron': boron,
      'sulfur': sulfur,
      'dataSource': dataSource,
      'fetchedAt': fetchedAt?.toIso8601String(),
    };
  }

  factory SoilQualityModel.fromJson(Map<String, dynamic> json) {
    return SoilQualityModel(
      zinc: json['zinc']?.toDouble(),
      iron: json['iron']?.toDouble(),
      copper: json['copper']?.toDouble(),
      manganese: json['manganese']?.toDouble(),
      boron: json['boron']?.toDouble(),
      sulfur: json['sulfur']?.toDouble(),
      dataSource: json['dataSource'] ?? 'manual',
      fetchedAt: json['fetchedAt'] != null
          ? DateTime.parse(json['fetchedAt'])
          : null,
    );
  }

  // Create from regional defaults
  factory SoilQualityModel.withDefaults(String? state) {
    // Default values based on common Indian soil conditions
    return SoilQualityModel(
      zinc: 75.0,
      iron: 85.0,
      copper: 80.0,
      manganese: 85.0,
      boron: 80.0,
      sulfur: 0.5,
      dataSource: 'regional_default',
      fetchedAt: DateTime.now(),
    );
  }
}

// Soil Test Center Model - Kept for reference
class SoilTestCenter {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // in km
  final String? phone;
  final String? timing;

  SoilTestCenter({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.phone,
    this.timing,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'phone': phone,
      'timing': timing,
    };
  }

  factory SoilTestCenter.fromJson(Map<String, dynamic> json) {
    return SoilTestCenter(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      phone: json['phone'],
      timing: json['timing'],
    );
  }
}

// Helper function to auto-detect season based on current month
String getSeasonFromMonth(int month) {
  if (month >= 6 && month <= 11) {
    return 'Kharif'; // June to November (Monsoon crops)
  } else if (month >= 12 || month <= 3) {
    return 'Rabi'; // December to March (Winter crops)
  } else {
    return 'Zaid'; // April to May (Summer crops)
  }
}

// Helper function to detect current season
String getCurrentSeason() {
  final now = DateTime.now();
  return getSeasonFromMonth(now.month);
}
