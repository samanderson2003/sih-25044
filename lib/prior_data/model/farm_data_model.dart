class FarmDataModel {
  final String userId;
  final LandDetailsModel landDetails;
  final SoilQualityModel soilQuality;
  final PastDataModel pastData;
  final CropDetailsModel cropDetails;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmDataModel({
    required this.userId,
    required this.landDetails,
    required this.soilQuality,
    required this.pastData,
    required this.cropDetails,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'landDetails': landDetails.toJson(),
      'soilQuality': soilQuality.toJson(),
      'pastData': pastData.toJson(),
      'cropDetails': cropDetails.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FarmDataModel.fromJson(Map<String, dynamic> json) {
    return FarmDataModel(
      userId: json['userId'] ?? '',
      landDetails: LandDetailsModel.fromJson(json['landDetails'] ?? {}),
      soilQuality: SoilQualityModel.fromJson(json['soilQuality'] ?? {}),
      pastData: PastDataModel.fromJson(json['pastData'] ?? {}),
      cropDetails: CropDetailsModel.fromJson(json['cropDetails'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
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
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final bool isManuallyMarked;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.isManuallyMarked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isManuallyMarked': isManuallyMarked,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      isManuallyMarked: json['isManuallyMarked'] ?? false,
    );
  }
}

class SoilQualityModel {
  final double? zinc; // Zn%
  final double? iron; // Fe%
  final double? copper; // Cu%
  final double? manganese; // Mn%
  final double? boron; // B%
  final double? sulfur; // S%
  final String? soilType;
  final double? ph;
  final double? organicCarbon;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final String dataSource; // manual, satellite, test_center
  final bool isAccurate; // false for satellite data
  final DateTime? testDate;
  final String? testCenterName;

  SoilQualityModel({
    this.zinc,
    this.iron,
    this.copper,
    this.manganese,
    this.boron,
    this.sulfur,
    this.soilType,
    this.ph,
    this.organicCarbon,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.dataSource = 'manual',
    this.isAccurate = true,
    this.testDate,
    this.testCenterName,
  });

  bool get isComplete {
    return zinc != null &&
        iron != null &&
        copper != null &&
        manganese != null &&
        boron != null &&
        sulfur != null &&
        soilType != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'zinc': zinc,
      'iron': iron,
      'copper': copper,
      'manganese': manganese,
      'boron': boron,
      'sulfur': sulfur,
      'soilType': soilType,
      'ph': ph,
      'organicCarbon': organicCarbon,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'dataSource': dataSource,
      'isAccurate': isAccurate,
      'testDate': testDate?.toIso8601String(),
      'testCenterName': testCenterName,
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
      soilType: json['soilType'],
      ph: json['ph']?.toDouble(),
      organicCarbon: json['organicCarbon']?.toDouble(),
      nitrogen: json['nitrogen']?.toDouble(),
      phosphorus: json['phosphorus']?.toDouble(),
      potassium: json['potassium']?.toDouble(),
      dataSource: json['dataSource'] ?? 'manual',
      isAccurate: json['isAccurate'] ?? true,
      testDate: json['testDate'] != null
          ? DateTime.parse(json['testDate'])
          : null,
      testCenterName: json['testCenterName'],
    );
  }
}

class PastDataModel {
  final List<CropHistoryModel> cropHistory;
  final double? averageYield; // tons per acre
  final List<String>? commonPests;
  final List<String>? commonDiseases;
  final String? fertilizersUsed;

  PastDataModel({
    this.cropHistory = const [],
    this.averageYield,
    this.commonPests,
    this.commonDiseases,
    this.fertilizersUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'cropHistory': cropHistory.map((e) => e.toJson()).toList(),
      'averageYield': averageYield,
      'commonPests': commonPests,
      'commonDiseases': commonDiseases,
      'fertilizersUsed': fertilizersUsed,
    };
  }

  factory PastDataModel.fromJson(Map<String, dynamic> json) {
    return PastDataModel(
      cropHistory:
          (json['cropHistory'] as List<dynamic>?)
              ?.map((e) => CropHistoryModel.fromJson(e))
              .toList() ??
          [],
      averageYield: json['averageYield']?.toDouble(),
      commonPests: (json['commonPests'] as List<dynamic>?)?.cast<String>(),
      commonDiseases: (json['commonDiseases'] as List<dynamic>?)
          ?.cast<String>(),
      fertilizersUsed: json['fertilizersUsed'],
    );
  }
}

class CropHistoryModel {
  final String cropName;
  final String season; // Kharif, Rabi, Zaid
  final int year;
  final double? yield; // tons
  final String? notes;

  CropHistoryModel({
    required this.cropName,
    required this.season,
    required this.year,
    this.yield,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'cropName': cropName,
      'season': season,
      'year': year,
      'yield': yield,
      'notes': notes,
    };
  }

  factory CropHistoryModel.fromJson(Map<String, dynamic> json) {
    return CropHistoryModel(
      cropName: json['cropName'] ?? '',
      season: json['season'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      yield: json['yield']?.toDouble(),
      notes: json['notes'],
    );
  }
}

class CropDetailsModel {
  final String currentCropName;
  final String season; // Kharif, Rabi, Zaid
  final DateTime sowingDate;
  final DateTime? expectedHarvestDate;
  final String? variety;
  final double? seedRate; // kg per acre

  CropDetailsModel({
    required this.currentCropName,
    required this.season,
    required this.sowingDate,
    this.expectedHarvestDate,
    this.variety,
    this.seedRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentCropName': currentCropName,
      'season': season,
      'sowingDate': sowingDate.toIso8601String(),
      'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
      'variety': variety,
      'seedRate': seedRate,
    };
  }

  factory CropDetailsModel.fromJson(Map<String, dynamic> json) {
    return CropDetailsModel(
      currentCropName: json['currentCropName'] ?? '',
      season: json['season'] ?? '',
      sowingDate: json['sowingDate'] != null
          ? DateTime.parse(json['sowingDate'])
          : DateTime.now(),
      expectedHarvestDate: json['expectedHarvestDate'] != null
          ? DateTime.parse(json['expectedHarvestDate'])
          : null,
      variety: json['variety'],
      seedRate: json['seedRate']?.toDouble(),
    );
  }
}

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
