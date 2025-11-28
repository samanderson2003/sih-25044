class CropPredictionInput {
  final double area;
  final double tavgClimate;
  final double tminClimate;
  final double tmaxClimate;
  final double prcpAnnualClimate;
  final double znPercent;
  final double fePercent;
  final double cuPercent;
  final double mnPercent;
  final double bPercent;
  final double sPercent;
  final String crop;
  final String season;
  final int year;

  CropPredictionInput({
    required this.area,
    required this.tavgClimate,
    required this.tminClimate,
    required this.tmaxClimate,
    required this.prcpAnnualClimate,
    required this.znPercent,
    required this.fePercent,
    required this.cuPercent,
    required this.mnPercent,
    required this.bPercent,
    required this.sPercent,
    required this.crop,
    required this.season,
    required this.year,
  });

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'tavg_climate': tavgClimate,
      'tmin_climate': tminClimate,
      'tmax_climate': tmaxClimate,
      'prcp_annual_climate': prcpAnnualClimate,
      'zn %': znPercent,
      'fe%': fePercent,
      'cu %': cuPercent,
      'mn %': mnPercent,
      'b %': bPercent,
      's %': sPercent,
      'crop': crop,
      'season': season,
      'year': year,
    };
  }
}

class YieldForecast {
  final double perHectareTonnes;
  final double totalExpectedTonnes;
  final double totalKg;
  final int confidenceLevel;
  final double modelR2;

  YieldForecast({
    required this.perHectareTonnes,
    required this.totalExpectedTonnes,
    required this.totalKg,
    required this.confidenceLevel,
    required this.modelR2,
  });

  factory YieldForecast.fromJson(Map<String, dynamic> json) {
    return YieldForecast(
      perHectareTonnes: json['per_hectare_tonnes'].toDouble(),
      totalExpectedTonnes: json['total_expected_tonnes'].toDouble(),
      totalKg: json['total_kg'].toDouble(),
      confidenceLevel: json['confidence_level'],
      modelR2: json['model_r2'].toDouble(),
    );
  }
}

class SoilStatus {
  final String zinc;
  final String iron;
  final String sulfur;

  SoilStatus({
    required this.zinc,
    required this.iron,
    required this.sulfur,
  });

  factory SoilStatus.fromJson(Map<String, dynamic> json) {
    return SoilStatus(
      zinc: json['zinc'],
      iron: json['iron'],
      sulfur: json['sulfur'],
    );
  }
}

class EconomicEstimate {
  final double expectedIncomeLow;
  final double expectedIncomeHigh;
  final double estimatedCosts;
  final double netProfitLow;
  final double netProfitHigh;
  final double roiLow;
  final double roiHigh;

  EconomicEstimate({
    required this.expectedIncomeLow,
    required this.expectedIncomeHigh,
    required this.estimatedCosts,
    required this.netProfitLow,
    required this.netProfitHigh,
    required this.roiLow,
    required this.roiHigh,
  });

  factory EconomicEstimate.fromJson(Map<String, dynamic> json) {
    return EconomicEstimate(
      expectedIncomeLow: json['expected_income_low'].toDouble(),
      expectedIncomeHigh: json['expected_income_high'].toDouble(),
      estimatedCosts: json['estimated_costs'].toDouble(),
      netProfitLow: json['net_profit_low'].toDouble(),
      netProfitHigh: json['net_profit_high'].toDouble(),
      roiLow: json['roi_low'].toDouble(),
      roiHigh: json['roi_high'].toDouble(),
    );
  }
}

class CropSuitability {
  final String rating;
  final int score;
  final List<String> factors;

  CropSuitability({
    required this.rating,
    required this.score,
    required this.factors,
  });

  factory CropSuitability.fromJson(Map<String, dynamic> json) {
    return CropSuitability(
      rating: json['rating'],
      score: json['score'],
      factors: List<String>.from(json['factors']),
    );
  }
}

class CropPredictionResponse {
  final String crop;
  final String season;
  final double farmAreaAcres;
  final double farmAreaHectares;
  final YieldForecast yieldForecast;
  final Map<String, dynamic> climate;
  final SoilStatus soilHealth;
  final String irrigationSuggestion;
  final String irrigationDetail;
  final List<String> fertilizerRecommendation;
  final CropSuitability cropSuitability;
  final List<String> highRiskAlerts;
  final List<String> mediumRiskAlerts;
  final EconomicEstimate economicEstimate;
  final List<String> additionalRecommendations;

  CropPredictionResponse({
    required this.crop,
    required this.season,
    required this.farmAreaAcres,
    required this.farmAreaHectares,
    required this.yieldForecast,
    required this.climate,
    required this.soilHealth,
    required this.irrigationSuggestion,
    required this.irrigationDetail,
    required this.fertilizerRecommendation,
    required this.cropSuitability,
    required this.highRiskAlerts,
    required this.mediumRiskAlerts,
    required this.economicEstimate,
    required this.additionalRecommendations,
  });

  factory CropPredictionResponse.fromJson(Map<String, dynamic> json) {
    return CropPredictionResponse(
      crop: json['crop'],
      season: json['season'],
      farmAreaAcres: json['farm_area_acres'].toDouble(),
      farmAreaHectares: json['farm_area_hectares'].toDouble(),
      yieldForecast: YieldForecast.fromJson(json['yield_forecast']),
      climate: json['climate'],
      soilHealth: SoilStatus.fromJson(json['soil_health']),
      irrigationSuggestion: json['irrigation_suggestion'],
      irrigationDetail: json['irrigation_detail'],
      fertilizerRecommendation:
          List<String>.from(json['fertilizer_recommendation']),
      cropSuitability: CropSuitability.fromJson(json['crop_suitability']),
      highRiskAlerts: List<String>.from(json['high_risk_alerts']),
      mediumRiskAlerts: List<String>.from(json['medium_risk_alerts']),
      economicEstimate: EconomicEstimate.fromJson(json['economic_estimate']),
      additionalRecommendations:
          List<String>.from(json['additional_recommendations']),
    );
  }
}
