// New Crop Yield Model - Based on Neural Network GEE API
// Matches the FastAPI endpoints in app.py and predict.py

/// Input model for the new ML prediction system
class AgriAIInput {
  // Mandatory Fields
  final String district; // e.g., "Mayurbhanj"
  final String soilType; // e.g., "Clay Loam"
  final double rainMm; // e.g., 1600.0
  final double tempC; // e.g., 27.0
  final double ph; // e.g., 5.0
  final double areaAcres; // e.g., 2.5

  // Advanced / Simulation Fields
  final double soc; // Soil Organic Carbon (default: 0.5)
  final double ndviMax; // General Greenness (default: 0.6)
  final double ndviAnomaly; // CRITICAL: Set to -0.25 to trigger Pest Alert
  final double eviMax; // Enhanced Vegetation Index (default: 4000.0)
  final double lst; // Land Surface Temperature (default: 30.0)
  final double elevation; // Elevation in meters (default: 100.0)
  final double dryWetIndex; // Dry-Wet Day Index (default: 10.0)

  AgriAIInput({
    required this.district,
    required this.soilType,
    required this.rainMm,
    required this.tempC,
    required this.ph,
    required this.areaAcres,
    this.soc = 0.5,
    this.ndviMax = 0.6,
    this.ndviAnomaly = 0.0,
    this.eviMax = 4000.0,
    this.lst = 30.0,
    this.elevation = 100.0,
    this.dryWetIndex = 10.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'district': district,
      'soil_type': soilType,
      'rain_mm': rainMm,
      'temp_c': tempC,
      'ph': ph,
      'area_acres': areaAcres,
      'soc': soc,
      'ndvi_max': ndviMax,
      'ndvi_anomaly': ndviAnomaly,
      'evi_max': eviMax,
      'lst': lst,
      'elevation': elevation,
      'dry_wet_index': dryWetIndex,
    };
  }
}

/// Farm profile summary from API response
class FarmProfile {
  final String district;
  final String area;
  final String condition; // "Normal" or "Simulated Pest Attack"

  FarmProfile({
    required this.district,
    required this.area,
    required this.condition,
  });

  factory FarmProfile.fromJson(Map<String, dynamic> json) {
    return FarmProfile(
      district: json['district'] ?? '',
      area: json['area'] ?? '',
      condition: json['condition'] ?? 'Normal',
    );
  }
}

/// Yield forecast analysis
class YieldAnalysis {
  final double currentYieldTonsHa;
  final double potentialYieldTonsHa;
  final String yieldIncreasePercentage; // e.g., "33.5%"
  final String condition; // "Action Required" or "Optimal"

  YieldAnalysis({
    required this.currentYieldTonsHa,
    required this.potentialYieldTonsHa,
    required this.yieldIncreasePercentage,
    required this.condition,
  });

  factory YieldAnalysis.fromJson(Map<String, dynamic> json) {
    return YieldAnalysis(
      currentYieldTonsHa: (json['current_yield_tons_ha'] ?? 0.0).toDouble(),
      potentialYieldTonsHa: (json['potential_yield_tons_ha'] ?? 0.0).toDouble(),
      yieldIncreasePercentage: json['yield_increase_potential'] ?? '0.0%',
      condition: json['condition'] ?? 'Optimal',
    );
  }
}

/// Advisory action details
class AdvisoryActionDetails {
  final String chemical;
  final String commercialProduct;
  final String organicAlternative;

  AdvisoryActionDetails({
    required this.chemical,
    required this.commercialProduct,
    required this.organicAlternative,
  });

  factory AdvisoryActionDetails.fromJson(Map<String, dynamic> json) {
    return AdvisoryActionDetails(
      chemical: json['Chemical'] ?? '',
      commercialProduct: json['Commercial_Product'] ?? '',
      organicAlternative: json['Organic_Alternative'] ?? '',
    );
  }
}

/// Optimization action item
class OptimizationAction {
  final String problem;
  final String action;
  final AdvisoryActionDetails details;
  final String impact; // e.g., "+15% Yield"

  OptimizationAction({
    required this.problem,
    required this.action,
    required this.details,
    required this.impact,
  });

  factory OptimizationAction.fromJson(Map<String, dynamic> json) {
    return OptimizationAction(
      problem: json['problem'] ?? '',
      action: json['action'] ?? '',
      details: AdvisoryActionDetails.fromJson(json['details'] ?? {}),
      impact: json['impact'] ?? '',
    );
  }

  bool get isNoProblem => problem == 'None';
}

/// Crop recommendation with variety info
class CropRecommendation {
  final String variety;
  final String type; // e.g., "High Yield", "Flood Tolerant"
  final double predictedYield; // Tons per hectare
  final double matchScore; // 0.0 to 1.0
  final String status; // "✅ Good Match" or "⚠️ Low Rain Risk"
  final double totalProductionTons; // Total production for farm size
  final double estimatedRevenueInr; // Estimated revenue in INR

  CropRecommendation({
    required this.variety,
    required this.type,
    required this.predictedYield,
    required this.matchScore,
    required this.status,
    required this.totalProductionTons,
    required this.estimatedRevenueInr,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      variety: json['variety'] ?? '',
      type: json['type'] ?? 'Standard',
      predictedYield: (json['predicted_yield'] ?? 0.0).toDouble(),
      matchScore: (json['match_score'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      totalProductionTons: (json['total_production_tons'] ?? 0.0).toDouble(),
      estimatedRevenueInr: (json['estimated_revenue_inr'] ?? 0.0).toDouble(),
    );
  }

  bool get isGoodMatch => status.contains('✅');
}

/// Complete API Response
class AgriAIResponse {
  final String status;
  final FarmProfile farmProfile;
  final YieldAnalysis yieldForecast;
  final List<OptimizationAction> advisoryPlan;
  final List<CropRecommendation> crops;

  AgriAIResponse({
    required this.status,
    required this.farmProfile,
    required this.yieldForecast,
    required this.advisoryPlan,
    required this.crops,
  });

  factory AgriAIResponse.fromJson(Map<String, dynamic> json) {
    return AgriAIResponse(
      status: json['status'] ?? 'unknown',
      farmProfile: FarmProfile.fromJson(json['farm_profile'] ?? {}),
      yieldForecast: YieldAnalysis.fromJson(json['yield_forecast'] ?? {}),
      advisoryPlan:
          (json['advisory_plan'] as List?)
              ?.map((item) => OptimizationAction.fromJson(item))
              .toList() ??
          [],
      crops:
          (json['crops'] as List?)
              ?.map((item) => CropRecommendation.fromJson(item))
              .toList() ??
          [],
    );
  }

  bool get hasOptimizationActions =>
      advisoryPlan.isNotEmpty && !advisoryPlan.first.isNoProblem;

  bool get isSuccess => status == 'success';
}
