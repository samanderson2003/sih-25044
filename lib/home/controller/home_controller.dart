import 'package:flutter/material.dart';
import '../model/crop_model.dart';
import '../model/weather_model.dart';
import '../model/daily_action_model.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../prior_data/controller/climate_service.dart';
import '../service/crop_lifecycle_service.dart';

class HomeController extends ChangeNotifier {
  final FarmDataController _farmDataController = FarmDataController();
  final ClimateService _climateService = ClimateService();

  // Selected crop
  Crop? _selectedCrop;
  Crop? get selectedCrop => _selectedCrop;

  // Available crops
  List<Crop> _crops = [];
  List<Crop> get crops => _crops;

  // User location from profile
  double? _userLatitude;
  double? _userLongitude;
  String? _userState;

  // Current weather
  Weather? _currentWeather;
  Weather? get currentWeather => _currentWeather;

  // Weather alerts
  List<WeatherAlert> _alerts = [];
  List<WeatherAlert> get alerts => _alerts;

  // Selected date
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Selected month
  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  // Loading states
  bool _isLoadingWeather = false;
  bool _isLoadingCrops = false;

  bool get isLoadingWeather => _isLoadingWeather;
  bool get isLoadingCrops => _isLoadingCrops;

  HomeController() {
    _initializeData();
  }

  void _initializeData() {
    _loadUserFarmData();
  }

  Future<void> _loadUserFarmData() async {
    _isLoadingCrops = true;
    notifyListeners();

    try {
      final farmData = await _farmDataController.getFarmData();

      if (farmData != null) {
        _userLatitude = farmData.farmBasics.location.latitude;
        _userLongitude = farmData.farmBasics.location.longitude;
        _userState = farmData.farmBasics.location.state;

        await _loadWeatherForLocation(
          _userLatitude!,
          _userLongitude!,
          _userState,
        );

        // Load first crop (blocks loading), then load rest in background
        _loadUserCropsProgressive(farmData.farmBasics.crops);
      } else {
        await _loadDefaultCrops();
        _loadWeather();
        _isLoadingCrops = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading farm data: $e');
      await _loadDefaultCrops();
      _loadWeather();
      _isLoadingCrops = false;
      notifyListeners();
    }
  }

  void _loadUserCropsProgressive(List<String> userCropNames) async {
    _crops.clear();

    if (userCropNames.isEmpty) {
      await _loadDefaultCrops();
      _isLoadingCrops = false;
      notifyListeners();
      return;
    }

    // Load FIRST crop and show immediately
    final firstCropName = userCropNames[0];
    final firstCrop = await _createCropByName(firstCropName);
    if (firstCrop != null) {
      _crops.add(firstCrop);
      _selectedCrop = firstCrop;

      // Stop loading state after first crop is ready
      _isLoadingCrops = false;
      notifyListeners(); // Show first crop immediately and hide loading

      // Load remaining crops in background (don't await)
      _loadRemainingCropsInBackground(userCropNames);
    } else {
      // First crop failed, try defaults
      await _loadDefaultCrops();
      _isLoadingCrops = false;
      notifyListeners();
    }
  }

  void _loadRemainingCropsInBackground(List<String> userCropNames) async {
    // Load crops 2, 3, 4... without blocking UI
    for (int i = 1; i < userCropNames.length; i++) {
      final cropName = userCropNames[i];
      final crop = await _createCropByName(cropName);
      if (crop != null) {
        _crops.add(crop);
        notifyListeners(); // Update UI as each crop loads
      }
    }
  }

  Future<Crop?> _createCropByName(String cropName) async {
    switch (cropName.toLowerCase()) {
      case 'rice':
        return await _createRiceCrop();
      case 'wheat':
        return await _createWheatCrop();
      case 'maize':
        return await _createMaizeCrop();
      case 'cotton':
        return await _createCottonCrop();
      case 'finger millet / ragi':
      case 'finger millet':
      case 'ragi':
        return await _createRagiCrop();
      case 'pulses':
        return await _createPulsesCrop();
      default:
        return null;
    }
  }

  Future<void> _loadDefaultCrops() async {
    _crops = [
      await _createRiceCrop(),
      await _createWheatCrop(),
      await _createMaizeCrop(),
      await _createCottonCrop(),
    ];
    if (_crops.isNotEmpty) {
      _selectedCrop = _crops[0];
    }
  }

  Future<void> _loadWeatherForLocation(
    double latitude,
    double longitude,
    String? state,
  ) async {
    _isLoadingWeather = true;
    notifyListeners();
    try {
      final climateData = await _climateService.getClimateDataWithFallback(
        latitude: latitude,
        longitude: longitude,
        state: state,
      );
      _currentWeather = Weather(
        temperature: climateData.tavgClimate,
        humidity: 73.0,
        rainfallProbability: climateData.prcpAnnualClimate > 5 ? 90.0 : 30.0,
        condition: climateData.prcpAnnualClimate > 5
            ? 'Rainy'
            : 'Partly Cloudy',
        windSpeed: 12.5,
        timestamp: DateTime.now(),
        location: state ?? 'Your Location',
      );
      _generateWeatherAlerts();
    } catch (e) {
      _loadWeather();
    }
    _isLoadingWeather = false;
    notifyListeners();
  }

  Future<void> _loadWeather() async {
    _isLoadingWeather = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _currentWeather = Weather(
      temperature: 28.0,
      humidity: 73.0,
      rainfallProbability: 90.0,
      condition: 'Rainy',
      windSpeed: 12.5,
      timestamp: DateTime.now(),
      location: 'Current Location',
    );
    _generateWeatherAlerts();
    _isLoadingWeather = false;
    notifyListeners();
  }

  void _generateWeatherAlerts() {
    _alerts.clear();
    if (_currentWeather == null) return;
    if (_currentWeather!.rainfallProbability > 70) {
      _alerts.add(
        WeatherAlert(
          title: 'Heavy Rainfall Expected',
          message: 'Avoid irrigation and field activities',
          severity: AlertSeverity.high,
          timestamp: DateTime.now(),
        ),
      );
    }
    if (_currentWeather!.humidity > 80) {
      _alerts.add(
        WeatherAlert(
          title: 'High Humidity Alert',
          message: 'Increased risk of fungal diseases',
          severity: AlertSeverity.medium,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void selectCrop(Crop crop) {
    _selectedCrop = crop;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void selectMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  SeasonSuitability? getSuitabilityForMonth(int month) {
    if (_selectedCrop == null) return null;
    return _selectedCrop!.monthSuitability[month];
  }

  List<WeeklyTask> getWeeklyTasksForMonth(int month) {
    if (_selectedCrop == null) return [];
    return _selectedCrop!.monthlyTasks[month] ?? [];
  }

  DailyAction? getDailyActionForDate(DateTime date) {
    if (_selectedCrop == null || _currentWeather == null) return null;
    final month = date.month;
    String cropStage = _getCropStage(month);
    final recommendations = _generateRecommendations(date, cropStage);
    final warnings = _generateWarnings();

    return DailyAction(
      date: date,
      cropId: _selectedCrop!.id,
      cropStage: cropStage,
      weather: _currentWeather!,
      recommendations: recommendations,
      warnings: warnings,
    );
  }

  String _getCropStage(int month) {
    if (_selectedCrop == null) return 'Unknown';
    if (_selectedCrop!.id == 'rice') {
      if (month >= 6 && month <= 7) return 'Sowing & Germination';
      if (month >= 8 && month <= 9) return 'Vegetative Growth';
      if (month >= 10 && month <= 12) return 'Flowering & Maturity';
    }
    final suitability = getSuitabilityForMonth(month);
    return suitability == SeasonSuitability.highCompatibility
        ? 'Growth Stage'
        : 'Maintenance Stage';
  }

  List<ActionRecommendation> _generateRecommendations(
    DateTime date,
    String stage,
  ) {
    List<ActionRecommendation> recommendations = [];
    if (_currentWeather == null) return recommendations;

    if (_currentWeather!.rainfallProbability > 70) {
      recommendations.add(
        ActionRecommendation(
          action: 'Don\'t irrigate today',
          reason: 'High rainfall probability',
          type: ActionType.irrigation,
          priority: ActionPriority.avoid,
        ),
      );
      recommendations.add(
        ActionRecommendation(
          action: 'Irrigation recommended tomorrow',
          reason: 'Post-rainfall schedule',
          type: ActionType.irrigation,
          timing: 'tomorrow morning',
          priority: ActionPriority.recommended,
        ),
      );
    } else if (_currentWeather!.rainfallProbability < 30 &&
        _currentWeather!.temperature > 30) {
      recommendations.add(
        ActionRecommendation(
          action: 'Irrigate the field',
          reason: 'Low rainfall and high temperature',
          type: ActionType.irrigation,
          timing: 'early morning',
          priority: ActionPriority.critical,
        ),
      );
    }
    if (_currentWeather!.rainfallProbability > 50) {
      recommendations.add(
        ActionRecommendation(
          action: 'Delay fertilizer',
          reason: 'Heavy rainfall may wash nutrients',
          type: ActionType.fertilization,
          timing: 'after 48 hours',
          priority: ActionPriority.recommended,
        ),
      );
    }
    if (_currentWeather!.humidity > 80) {
      recommendations.add(
        ActionRecommendation(
          action: 'Monitor for pests',
          reason: 'High humidity risk',
          type: ActionType.pestControl,
          priority: ActionPriority.recommended,
        ),
      );
    }
    return recommendations;
  }

  List<String> _generateWarnings() {
    List<String> warnings = [];
    if (_currentWeather == null) return warnings;
    if (_currentWeather!.humidity > 75)
      warnings.add('High fungal risk due to humidity');
    if (_currentWeather!.temperature > 35) warnings.add('Heat stress possible');
    if (_currentWeather!.windSpeed > 25)
      warnings.add('Strong winds — avoid spraying');
    return warnings;
  }

  Future<void> refreshWeather() async {
    await _loadWeather();
  }

  // Helper method to generate lifecycle with AI or fallback to static data
  Future<List<CropStage>> _getLifecycleStages({
    required String cropName,
    required List<CropStage> fallbackStages,
  }) async {
    try {
      // Try to generate AI-powered lifecycle
      final generatedStages = await CropLifecycleService.getCachedLifecycle(
        cropName: cropName,
        soilType: _userState,
        climate: _userState,
        location: _userState,
      );

      if (generatedStages != null && generatedStages.length >= 8) {
        debugPrint('✅ Using AI-generated lifecycle for $cropName');
        return generatedStages;
      } else if (generatedStages != null && generatedStages.isNotEmpty) {
        debugPrint(
          '⚠️ AI generated only ${generatedStages.length} stages (expected 8), using fallback',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to generate AI lifecycle: $e');
    }

    // Fallback to static data
    debugPrint('📋 Using static lifecycle for $cropName');
    return fallbackStages;
  }

  // --- CROP CREATION METHODS UPDATED WITH DAY-WISE DATA ---

  Future<Crop> _createRiceCrop() async {
    // Static fallback stages
    final fallbackStages = [
      CropStage(
        daysAfterPlanting: -15,
        stageName: 'Land Preparation',
        actionTitle: 'Plow and Level Field',
        description:
            'Plow field to 15-20 cm depth using tractor. Level properly for uniform water distribution. Apply 10-12 tonnes/hectare of well-decomposed FYM (Farmyard Manure) or 5 tonnes/ha of compost.',
        icon: 'agriculture',
      ),
      CropStage(
        daysAfterPlanting: -3,
        stageName: 'Seed Selection & Treatment',
        actionTitle: 'Treat Seeds',
        description:
            'Select certified seeds with 85% germination, 35-40 kg/ha seed rate. Treat with Carbendazim @ 2g/kg seed or Trichoderma viride @ 4g/kg for organic method.',
        icon: 'science',
      ),
      CropStage(
        daysAfterPlanting: 1,
        stageName: 'Sowing/Transplanting',
        actionTitle: 'Transplant Seedlings',
        description:
            'Transplant 21-25 day old seedlings at 20×15 cm spacing. Use 2-3 seedlings per hill. Maintain 5 cm water depth during transplanting.',
        icon: 'water_drop',
      ),
      CropStage(
        daysAfterPlanting: 15,
        stageName: 'Irrigation Management',
        actionTitle: 'Maintain Water Level',
        description:
            'Maintain 5-7 cm standing water depth. Apply 50-60 mm irrigation when depleted. Total water requirement: 1200-1500 mm. Drain 10 days before harvest.',
        icon: 'water_drop',
      ),
      CropStage(
        daysAfterPlanting: 30,
        stageName: 'Intercultural Operations',
        actionTitle: 'Weeding & Fertilization',
        description:
            'Apply 60 kg/ha Urea (27 kg N/ha) at 20-25 DAS. Second dose 60 kg/ha at 40-45 DAS. Spray Pretilachlor @ 500g/ha for weeds. Apply 50 kg/ha Potash.',
        icon: 'eco',
      ),
      CropStage(
        daysAfterPlanting: 60,
        stageName: 'Plant Protection',
        actionTitle: 'Pest & Disease Control',
        description:
            'Use 8 pheromone traps/ha for monitoring. Spray Chlorantraniliprole @ 0.4 ml/liter or Cartap Hydrochloride @ 2g/liter. For blast, apply Tricyclazole @ 0.6g/liter.',
        icon: 'pest_control',
      ),
      CropStage(
        daysAfterPlanting: 100,
        stageName: 'Harvesting',
        actionTitle: 'Harvest Mature Crop',
        description:
            'Harvest at 80-85% grain maturity and 20-25% moisture. Expected yield: 5-6 tonnes/ha. Use combine harvester or sickle. Leave 15 cm stubble.',
        icon: 'agriculture',
      ),
      CropStage(
        daysAfterPlanting: 105,
        stageName: 'Post-Harvest Processing',
        actionTitle: 'Threshing & Storage',
        description:
            'Thresh within 24-48 hours. Sun-dry to 12-14% moisture (2-3 days). Store in 50-60 kg gunny bags. Fumigate with Aluminium Phosphide @ 2 tablets/tonne.',
        icon: 'verified',
      ),
    ];

    // Get AI-generated or fallback lifecycle
    final lifecycleStages = await _getLifecycleStages(
      cropName: 'Rice',
      fallbackStages: fallbackStages,
    );

    return Crop(
      id: 'rice',
      name: 'Rice',
      icon: '🌾',
      themeColor: const Color(0xFF4CAF50),
      monthSuitability: {
        1: SeasonSuitability.notRecommended,
        2: SeasonSuitability.notRecommended,
        3: SeasonSuitability.notRecommended,
        4: SeasonSuitability.notRecommended,
        5: SeasonSuitability.notRecommended,
        6: SeasonSuitability.highCompatibility,
        7: SeasonSuitability.highCompatibility,
        8: SeasonSuitability.highCompatibility,
        9: SeasonSuitability.highCompatibility,
        10: SeasonSuitability.highCompatibility,
        11: SeasonSuitability.normal,
        12: SeasonSuitability.normal,
      },
      monthlyTasks: {
        6: [
          WeeklyTask(
            week: 1,
            stage: 'Sowing',
            tasks: ['Seed selection', 'Land irrigation'],
          ),
          WeeklyTask(
            week: 2,
            stage: 'Germination',
            tasks: ['Nitrogen fertilizer', 'Weed control'],
          ),
          WeeklyTask(
            week: 3,
            stage: 'Early Growth',
            tasks: ['Monitor water levels'],
          ),
          WeeklyTask(
            week: 4,
            stage: 'Growth',
            tasks: ['Irrigation', 'Pest monitoring'],
          ),
        ],
      },
      // Dynamic or fallback lifecycle
      lifecycleStages: lifecycleStages,
    );
  }

  Future<Crop> _createWheatCrop() async {
    final fallbackStages = [
      CropStage(
        daysAfterPlanting: 1,
        stageName: 'Sowing',
        actionTitle: 'Sowing',
        description: 'Sow seeds 4-5cm deep in rows.',
        icon: 'grass',
      ),
      CropStage(
        daysAfterPlanting: 21,
        stageName: 'CRI Stage',
        actionTitle: 'First Irrigation',
        description: 'Critical Crown Root Initiation irrigation.',
        icon: 'water_drop',
      ),
      CropStage(
        daysAfterPlanting: 45,
        stageName: 'Tillering',
        actionTitle: 'Nitrogen Application',
        description: 'Apply remaining dose of Urea.',
        icon: 'science',
      ),
    ];

    final lifecycleStages = await _getLifecycleStages(
      cropName: 'Wheat',
      fallbackStages: fallbackStages,
    );

    return Crop(
      id: 'wheat',
      name: 'Wheat',
      icon: '🌾',
      themeColor: const Color(0xFFFF9800),
      monthSuitability: {
        1: SeasonSuitability.highCompatibility,
        2: SeasonSuitability.highCompatibility,
        3: SeasonSuitability.normal,
        4: SeasonSuitability.notRecommended,
        5: SeasonSuitability.notRecommended,
        6: SeasonSuitability.notRecommended,
        7: SeasonSuitability.notRecommended,
        8: SeasonSuitability.notRecommended,
        9: SeasonSuitability.notRecommended,
        10: SeasonSuitability.notRecommended,
        11: SeasonSuitability.normal,
        12: SeasonSuitability.highCompatibility,
      },
      monthlyTasks: {},
      lifecycleStages: lifecycleStages,
    );
  }

  Future<Crop> _createMaizeCrop() async {
    final fallbackStages = [
      CropStage(
        daysAfterPlanting: 1,
        stageName: 'Sowing',
        actionTitle: 'Planting',
        description: 'Plant on ridges. Apply basal fertilizer.',
        icon: 'agriculture',
      ),
      CropStage(
        daysAfterPlanting: 15,
        stageName: 'Seedling',
        actionTitle: 'Weeding',
        description: 'Keep field weed-free during early growth.',
        icon: 'grass',
      ),
    ];

    final lifecycleStages = await _getLifecycleStages(
      cropName: 'Maize',
      fallbackStages: fallbackStages,
    );

    return Crop(
      id: 'maize',
      name: 'Maize',
      icon: '🌽',
      themeColor: const Color(0xFFFFEB3B),
      monthSuitability: {
        1: SeasonSuitability.notRecommended,
        2: SeasonSuitability.normal,
        3: SeasonSuitability.highCompatibility,
        4: SeasonSuitability.highCompatibility,
        5: SeasonSuitability.highCompatibility,
        6: SeasonSuitability.highCompatibility,
        7: SeasonSuitability.normal,
        8: SeasonSuitability.notRecommended,
        9: SeasonSuitability.notRecommended,
        10: SeasonSuitability.notRecommended,
        11: SeasonSuitability.notRecommended,
        12: SeasonSuitability.notRecommended,
      },
      monthlyTasks: {},
      lifecycleStages: lifecycleStages,
    );
  }

  Future<Crop> _createCottonCrop() async {
    final fallbackStages = [
      CropStage(
        daysAfterPlanting: -10,
        stageName: 'Land Preparation',
        actionTitle: 'Prepare Field',
        description:
            'Plow to 20-25 cm depth. Form ridges at 60-90 cm spacing. Apply 8-10 tonnes/ha FYM or 4-5 tonnes/ha vermicompost. Level properly for drainage.',
        icon: 'agriculture',
      ),
      CropStage(
        daysAfterPlanting: -2,
        stageName: 'Seed Selection & Treatment',
        actionTitle: 'Treat Seeds',
        description:
            'Use certified Bt-cotton seeds, 1.5-2 kg/ha seed rate. Treat with Imidacloprid @ 7 ml/kg and Carbendazim @ 2g/kg. Ensure 70% germination.',
        icon: 'science',
      ),
      CropStage(
        daysAfterPlanting: 1,
        stageName: 'Sowing/Transplanting',
        actionTitle: 'Seed Sowing',
        description:
            'Dibble seeds at 3-4 cm depth. Spacing: 90×60 cm (Hybrid) or 60×30 cm (varieties). Sow 2-3 seeds per hill. Maintain 70% soil moisture.',
        icon: 'grass',
      ),
      CropStage(
        daysAfterPlanting: 30,
        stageName: 'Irrigation Management',
        actionTitle: 'Critical Irrigation',
        description:
            'Apply 60-70 mm irrigation at square formation, flowering, and boll development. Provide 6-8 irrigations (450-600 mm total). Use drip @ 4 liters/hr.',
        icon: 'water_drop',
      ),
      CropStage(
        daysAfterPlanting: 45,
        stageName: 'Intercultural Operations',
        actionTitle: 'Top Dressing & Weeding',
        description:
            'Apply 65 kg/ha Urea (30 kg N/ha) at square stage. Apply 25 kg/ha MOP (Muriate of Potash) at flowering. Spray Pendimethalin @ 3.3 liters/ha for weeds.',
        icon: 'eco',
      ),
      CropStage(
        daysAfterPlanting: 80,
        stageName: 'Plant Protection',
        actionTitle: 'Bollworm Control',
        description:
            'Install 12 pheromone traps/ha. Spray Emamectin Benzoate @ 0.5g/liter or Spinosad @ 0.3 ml/liter for bollworms. For whitefly, use Acetamiprid @ 0.3g/liter.',
        icon: 'pest_control',
      ),
      CropStage(
        daysAfterPlanting: 150,
        stageName: 'Harvesting',
        actionTitle: 'Pick Cotton Bolls',
        description:
            'Pick when 60% bolls burst open. Do 3-4 pickings at 15-day intervals. Expected yield: 20-25 quintals/ha. Avoid moisture contamination.',
        icon: 'agriculture',
      ),
      CropStage(
        daysAfterPlanting: 155,
        stageName: 'Post-Harvest Processing',
        actionTitle: 'Ginning & Storage',
        description:
            'Gin within 48 hours (30-32% ginning outturn). Sun-dry to 8-10% moisture. Grade as per quality. Store in moisture-proof bags at <65% RH.',
        icon: 'verified',
      ),
    ];

    final lifecycleStages = await _getLifecycleStages(
      cropName: 'Cotton',
      fallbackStages: fallbackStages,
    );

    return Crop(
      id: 'cotton',
      name: 'Cotton',
      icon: '☁️',
      themeColor: const Color(0xFF9C27B0),
      monthSuitability: {
        1: SeasonSuitability.notRecommended,
        2: SeasonSuitability.notRecommended,
        3: SeasonSuitability.notRecommended,
        4: SeasonSuitability.normal,
        5: SeasonSuitability.highCompatibility,
        6: SeasonSuitability.highCompatibility,
        7: SeasonSuitability.highCompatibility,
        8: SeasonSuitability.highCompatibility,
        9: SeasonSuitability.normal,
        10: SeasonSuitability.notRecommended,
        11: SeasonSuitability.notRecommended,
        12: SeasonSuitability.notRecommended,
      },
      monthlyTasks: {},
      lifecycleStages: lifecycleStages,
    );
  }

  Future<Crop> _createRagiCrop() async {
    final fallbackStages = [
      CropStage(
        daysAfterPlanting: 1,
        stageName: 'Sowing',
        actionTitle: 'Seed Sowing',
        description: 'Broadcast or drill sowing.',
        icon: 'grass',
      ),
      CropStage(
        daysAfterPlanting: 20,
        stageName: 'Tillering',
        actionTitle: 'Weeding',
        description: 'First weeding and thinning.',
        icon: 'grass',
      ),
      CropStage(
        daysAfterPlanting: 60,
        stageName: 'Flowering',
        actionTitle: 'Fertilizer Application',
        description: 'Apply top dressing.',
        icon: 'science',
      ),
      CropStage(
        daysAfterPlanting: 100,
        stageName: 'Maturity',
        actionTitle: 'Harvest',
        description: 'Harvest when grains are hard.',
        icon: 'local_florist',
      ),
    ];

    final lifecycleStages = await _getLifecycleStages(
      cropName: 'Ragi',
      fallbackStages: fallbackStages,
    );

    return Crop(
      id: 'ragi',
      name: 'Ragi',
      icon: '🌾',
      themeColor: const Color(0xFF8D6E63),
      monthSuitability: {
        1: SeasonSuitability.notRecommended,
        2: SeasonSuitability.notRecommended,
        3: SeasonSuitability.notRecommended,
        4: SeasonSuitability.normal,
        5: SeasonSuitability.highCompatibility,
        6: SeasonSuitability.highCompatibility,
        7: SeasonSuitability.highCompatibility,
        8: SeasonSuitability.normal,
        9: SeasonSuitability.notRecommended,
        10: SeasonSuitability.notRecommended,
        11: SeasonSuitability.notRecommended,
        12: SeasonSuitability.notRecommended,
      },
      monthlyTasks: {},
      lifecycleStages: lifecycleStages,
    );
  }

  Future<Crop> _createPulsesCrop() async {
    final fallbackStages = [
      CropStage(
        daysAfterPlanting: 1,
        stageName: 'Sowing',
        actionTitle: 'Seed Sowing',
        description: 'Sow seeds at proper depth.',
        icon: 'grass',
      ),
      CropStage(
        daysAfterPlanting: 25,
        stageName: 'Vegetative',
        actionTitle: 'Weeding',
        description: 'Remove weeds around plants.',
        icon: 'grass',
      ),
      CropStage(
        daysAfterPlanting: 50,
        stageName: 'Flowering',
        actionTitle: 'Pest Management',
        description: 'Monitor for pod borers.',
        icon: 'pest_control',
      ),
      CropStage(
        daysAfterPlanting: 80,
        stageName: 'Maturity',
        actionTitle: 'Harvest',
        description: 'Harvest when pods are dry.',
        icon: 'agriculture',
      ),
    ];

    final lifecycleStages = await _getLifecycleStages(
      cropName: 'Pulses',
      fallbackStages: fallbackStages,
    );

    return Crop(
      id: 'pulses',
      name: 'Pulses',
      icon: '🫘',
      themeColor: const Color(0xFF6D4C41),
      monthSuitability: {
        1: SeasonSuitability.notRecommended,
        2: SeasonSuitability.notRecommended,
        3: SeasonSuitability.notRecommended,
        4: SeasonSuitability.notRecommended,
        5: SeasonSuitability.notRecommended,
        6: SeasonSuitability.highCompatibility,
        7: SeasonSuitability.highCompatibility,
        8: SeasonSuitability.normal,
        9: SeasonSuitability.notRecommended,
        10: SeasonSuitability.highCompatibility,
        11: SeasonSuitability.normal,
        12: SeasonSuitability.notRecommended,
      },
      monthlyTasks: {},
      lifecycleStages: lifecycleStages,
    );
  }
}

// import 'package:flutter/material.dart';
// import '../model/crop_model.dart';
// import '../model/weather_model.dart';
// import '../model/daily_action_model.dart';
// import '../../prior_data/controller/farm_data_controller.dart';
// import '../../prior_data/controller/climate_service.dart';
//
// class HomeController extends ChangeNotifier {
//   final FarmDataController _farmDataController = FarmDataController();
//   final ClimateService _climateService = ClimateService();
//
//   // Selected crop
//   Crop? _selectedCrop;
//   Crop? get selectedCrop => _selectedCrop;
//
//   // Available crops
//   List<Crop> _crops = [];
//   List<Crop> get crops => _crops;
//
//   // User location from profile
//   double? _userLatitude;
//   double? _userLongitude;
//   String? _userState;
//
//   // Current weather
//   Weather? _currentWeather;
//   Weather? get currentWeather => _currentWeather;
//
//   // Weather alerts
//   List<WeatherAlert> _alerts = [];
//   List<WeatherAlert> get alerts => _alerts;
//
//   // Selected date
//   DateTime _selectedDate = DateTime.now();
//   DateTime get selectedDate => _selectedDate;
//
//   // Selected month
//   int _selectedMonth = DateTime.now().month;
//   int get selectedMonth => _selectedMonth;
//
//   // Loading states
//   bool _isLoadingWeather = false;
//   bool _isLoadingCrops = false;
//
//   bool get isLoadingWeather => _isLoadingWeather;
//   bool get isLoadingCrops => _isLoadingCrops;
//
//   HomeController() {
//     _initializeData();
//   }
//
//   void _initializeData() {
//     _loadUserFarmData();
//   }
//
//   // Load user's farm data from profile
//   Future<void> _loadUserFarmData() async {
//     _isLoadingCrops = true;
//     notifyListeners();
//
//     try {
//       final farmData = await _farmDataController.getFarmData();
//
//       if (farmData != null) {
//         // Store user location
//         _userLatitude = farmData.farmBasics.location.latitude;
//         _userLongitude = farmData.farmBasics.location.longitude;
//         _userState = farmData.farmBasics.location.state;
//
//         // Load weather based on user's location
//         await _loadWeatherForLocation(
//           _userLatitude!,
//           _userLongitude!,
//           _userState,
//         );
//
//         // Load crops based on user's selected crops
//         _loadUserCrops(farmData.farmBasics.crops);
//       } else {
//         // No farm data - load defaults
//         _loadDefaultCrops();
//         _loadWeather();
//       }
//     } catch (e) {
//       print('Error loading farm data: $e');
//       _loadDefaultCrops();
//       _loadWeather();
//     }
//
//     _isLoadingCrops = false;
//     notifyListeners();
//   }
//
//   // Load crops based on user's profile
//   void _loadUserCrops(List<String> userCropNames) {
//     _crops.clear();
//
//     // Map user crop names to crop objects
//     for (final cropName in userCropNames) {
//       Crop? crop;
//       switch (cropName.toLowerCase()) {
//         case 'rice':
//           crop = _createRiceCrop();
//           break;
//         case 'wheat':
//           crop = _createWheatCrop();
//           break;
//         case 'maize':
//           crop = _createMaizeCrop();
//           break;
//         case 'cotton':
//           crop = _createCottonCrop();
//           break;
//       }
//       if (crop != null) {
//         _crops.add(crop);
//       }
//     }
//
//     // If no valid crops found, add default
//     if (_crops.isEmpty) {
//       _loadDefaultCrops();
//     }
//
//     // Select first crop by default
//     if (_crops.isNotEmpty) {
//       _selectedCrop = _crops[0];
//     }
//   }
//
//   // Load default crops (fallback)
//   void _loadDefaultCrops() {
//     _crops = [
//       _createRiceCrop(),
//       _createWheatCrop(),
//       _createMaizeCrop(),
//       _createCottonCrop(),
//     ];
//
//     // Select first crop by default
//     if (_crops.isNotEmpty) {
//       _selectedCrop = _crops[0];
//     }
//   }
//
//   // Load weather data for user's location
//   Future<void> _loadWeatherForLocation(
//     double latitude,
//     double longitude,
//     String? state,
//   ) async {
//     _isLoadingWeather = true;
//     notifyListeners();
//
//     try {
//       // Get climate data from NASA POWER API
//       final climateData = await _climateService.getClimateDataWithFallback(
//         latitude: latitude,
//         longitude: longitude,
//         state: state,
//       );
//
//       // Use climate data for current weather estimate
//       _currentWeather = Weather(
//         temperature: climateData.tavgClimate,
//         humidity: 73.0, // TODO: Get from weather API
//         rainfallProbability: climateData.prcpAnnualClimate > 5 ? 90.0 : 30.0,
//         condition: climateData.prcpAnnualClimate > 5
//             ? 'Rainy'
//             : 'Partly Cloudy',
//         windSpeed: 12.5,
//         timestamp: DateTime.now(),
//         location: state ?? 'Your Location',
//       );
//
//       // Generate alerts based on weather
//       _generateWeatherAlerts();
//     } catch (e) {
//       print('Error loading weather for location: $e');
//       _loadWeather(); // Fallback
//     }
//
//     _isLoadingWeather = false;
//     notifyListeners();
//   }
//
//   // Fallback weather loader
//   Future<void> _loadWeather() async {
//     _isLoadingWeather = true;
//     notifyListeners();
//
//     await Future.delayed(const Duration(milliseconds: 500));
//
//     _currentWeather = Weather(
//       temperature: 28.0,
//       humidity: 73.0,
//       rainfallProbability: 90.0,
//       condition: 'Rainy',
//       windSpeed: 12.5,
//       timestamp: DateTime.now(),
//       location: 'Current Location',
//     );
//
//     _generateWeatherAlerts();
//
//     _isLoadingWeather = false;
//     notifyListeners();
//   }
//
//   void _generateWeatherAlerts() {
//     _alerts.clear();
//
//     if (_currentWeather == null) return;
//
//     if (_currentWeather!.rainfallProbability > 70) {
//       _alerts.add(
//         WeatherAlert(
//           title: 'Heavy Rainfall Expected',
//           message: 'Avoid irrigation and field activities',
//           severity: AlertSeverity.high,
//           timestamp: DateTime.now(),
//         ),
//       );
//     }
//
//     if (_currentWeather!.humidity > 80) {
//       _alerts.add(
//         WeatherAlert(
//           title: 'High Humidity Alert',
//           message: 'Increased risk of fungal diseases',
//           severity: AlertSeverity.medium,
//           timestamp: DateTime.now(),
//         ),
//       );
//     }
//   }
//
//   // Select a crop
//   void selectCrop(Crop crop) {
//     _selectedCrop = crop;
//     notifyListeners();
//   }
//
//   // Select a date
//   void selectDate(DateTime date) {
//     _selectedDate = date;
//     notifyListeners();
//   }
//
//   // Select a month
//   void selectMonth(int month) {
//     _selectedMonth = month;
//     notifyListeners();
//   }
//
//   // Get suitability for a specific month
//   SeasonSuitability? getSuitabilityForMonth(int month) {
//     if (_selectedCrop == null) return null;
//     return _selectedCrop!.monthSuitability[month];
//   }
//
//   // Get weekly tasks for selected month
//   List<WeeklyTask> getWeeklyTasksForMonth(int month) {
//     if (_selectedCrop == null) return [];
//     return _selectedCrop!.monthlyTasks[month] ?? [];
//   }
//
//   // Get daily action plan
//   DailyAction? getDailyActionForDate(DateTime date) {
//     if (_selectedCrop == null || _currentWeather == null) return null;
//
//     // Determine crop stage based on month
//     final month = date.month;
//     String cropStage = _getCropStage(month);
//
//     // Generate recommendations based on weather
//     final recommendations = _generateRecommendations(date, cropStage);
//     final warnings = _generateWarnings();
//
//     return DailyAction(
//       date: date,
//       cropId: _selectedCrop!.id,
//       cropStage: cropStage,
//       weather: _currentWeather!,
//       recommendations: recommendations,
//       warnings: warnings,
//     );
//   }
//
//   String _getCropStage(int month) {
//     if (_selectedCrop == null) return 'Unknown';
//
//     if (_selectedCrop!.id == 'rice') {
//       if (month >= 6 && month <= 7) return 'Sowing & Germination';
//       if (month >= 8 && month <= 9) return 'Vegetative Growth';
//       if (month >= 10 && month <= 12) return 'Flowering & Maturity';
//     }
//
//     final suitability = getSuitabilityForMonth(month);
//     return suitability == SeasonSuitability.highCompatibility
//         ? 'Growth Stage'
//         : 'Maintenance Stage';
//   }
//
//   List<ActionRecommendation> _generateRecommendations(
//     DateTime date,
//     String stage,
//   ) {
//     List<ActionRecommendation> recommendations = [];
//
//     if (_currentWeather == null) return recommendations;
//
//     // Irrigation recommendations based on rainfall
//     if (_currentWeather!.rainfallProbability > 70) {
//       recommendations.add(
//         ActionRecommendation(
//           action: 'Don\'t irrigate today',
//           reason:
//               'High rainfall probability (${_currentWeather!.rainfallProbability.toInt()}%)',
//           type: ActionType.irrigation,
//           priority: ActionPriority.avoid,
//         ),
//       );
//
//       recommendations.add(
//         ActionRecommendation(
//           action: 'Irrigation recommended tomorrow morning',
//           reason: 'Post-rainfall irrigation schedule',
//           type: ActionType.irrigation,
//           timing: 'tomorrow morning',
//           priority: ActionPriority.recommended,
//         ),
//       );
//     } else if (_currentWeather!.rainfallProbability < 30 &&
//         _currentWeather!.temperature > 30) {
//       recommendations.add(
//         ActionRecommendation(
//           action: 'Irrigate the field',
//           reason: 'Low rainfall and high temperature',
//           type: ActionType.irrigation,
//           timing: 'early morning or evening',
//           priority: ActionPriority.critical,
//         ),
//       );
//     }
//
//     // Fertilization recommendations
//     if (_currentWeather!.rainfallProbability > 50) {
//       recommendations.add(
//         ActionRecommendation(
//           action: 'Delay fertilizer application',
//           reason: 'Heavy rainfall may wash away nutrients',
//           type: ActionType.fertilization,
//           timing: 'after 48 hours of rainfall',
//           priority: ActionPriority.recommended,
//         ),
//       );
//     }
//
//     // Pest control based on humidity
//     if (_currentWeather!.humidity > 80) {
//       recommendations.add(
//         ActionRecommendation(
//           action: 'Monitor for pest activity',
//           reason: 'High humidity increases pest risk',
//           type: ActionType.pestControl,
//           priority: ActionPriority.recommended,
//         ),
//       );
//     }
//
//     return recommendations;
//   }
//
//   List<String> _generateWarnings() {
//     List<String> warnings = [];
//
//     if (_currentWeather == null) return warnings;
//
//     if (_currentWeather!.humidity > 75) {
//       warnings.add(
//         'High fungal risk due to humidity — check for leaf spot symptoms',
//       );
//     }
//
//     if (_currentWeather!.temperature > 35) {
//       warnings.add('Heat stress possible — ensure adequate irrigation');
//     }
//
//     if (_currentWeather!.windSpeed > 25) {
//       warnings.add('Strong winds — avoid spraying operations');
//     }
//
//     return warnings;
//   }
//
//   // Refresh weather data
//   Future<void> refreshWeather() async {
//     await _loadWeather();
//   }
//
//   // Sample crop creation methods
//   Crop _createRiceCrop() {
//     return Crop(
//       id: 'rice',
//       name: 'Rice',
//       icon: '🌾',
//       themeColor: const Color(0xFF4CAF50),
//       monthSuitability: {
//         1: SeasonSuitability.notRecommended,
//         2: SeasonSuitability.notRecommended,
//         3: SeasonSuitability.notRecommended,
//         4: SeasonSuitability.notRecommended,
//         5: SeasonSuitability.notRecommended,
//         6: SeasonSuitability.highCompatibility,
//         7: SeasonSuitability.highCompatibility,
//         8: SeasonSuitability.highCompatibility,
//         9: SeasonSuitability.highCompatibility,
//         10: SeasonSuitability.highCompatibility,
//         11: SeasonSuitability.normal,
//         12: SeasonSuitability.normal,
//       },
//       monthlyTasks: {
//         6: [
//           WeeklyTask(
//             week: 1,
//             stage: 'Sowing',
//             tasks: ['Seed selection', 'Land irrigation', 'Soil preparation'],
//           ),
//           WeeklyTask(
//             week: 2,
//             stage: 'Germination',
//             tasks: ['Nitrogen fertilizer application', 'Weed control'],
//           ),
//           WeeklyTask(
//             week: 3,
//             stage: 'Early Growth',
//             tasks: ['Monitor water levels', 'First weeding'],
//           ),
//           WeeklyTask(
//             week: 4,
//             stage: 'Growth',
//             tasks: ['Irrigation if no rainfall', 'Pest monitoring'],
//           ),
//         ],
//         7: [
//           WeeklyTask(
//             week: 1,
//             stage: 'Vegetative',
//             tasks: ['Apply urea fertilizer', 'Maintain water depth'],
//           ),
//           WeeklyTask(
//             week: 2,
//             stage: 'Tillering',
//             tasks: ['Weed management', 'Check for pests'],
//           ),
//           WeeklyTask(
//             week: 3,
//             stage: 'Growth',
//             tasks: ['Ensure proper drainage', 'Monitor plant health'],
//           ),
//           WeeklyTask(
//             week: 4,
//             stage: 'Pest Alert',
//             tasks: ['Spray advisory based on weather', 'Leaf folder control'],
//           ),
//         ],
//       },
//     );
//   }
//
//   Crop _createWheatCrop() {
//     return Crop(
//       id: 'wheat',
//       name: 'Wheat',
//       icon: '🌾',
//       themeColor: const Color(0xFFFF9800),
//       monthSuitability: {
//         1: SeasonSuitability.highCompatibility,
//         2: SeasonSuitability.highCompatibility,
//         3: SeasonSuitability.normal,
//         4: SeasonSuitability.notRecommended,
//         5: SeasonSuitability.notRecommended,
//         6: SeasonSuitability.notRecommended,
//         7: SeasonSuitability.notRecommended,
//         8: SeasonSuitability.notRecommended,
//         9: SeasonSuitability.notRecommended,
//         10: SeasonSuitability.notRecommended,
//         11: SeasonSuitability.normal,
//         12: SeasonSuitability.highCompatibility,
//       },
//       monthlyTasks: {},
//     );
//   }
//
//   Crop _createMaizeCrop() {
//     return Crop(
//       id: 'maize',
//       name: 'Maize',
//       icon: '🌽',
//       themeColor: const Color(0xFFFFEB3B),
//       monthSuitability: {
//         1: SeasonSuitability.notRecommended,
//         2: SeasonSuitability.normal,
//         3: SeasonSuitability.highCompatibility,
//         4: SeasonSuitability.highCompatibility,
//         5: SeasonSuitability.highCompatibility,
//         6: SeasonSuitability.highCompatibility,
//         7: SeasonSuitability.normal,
//         8: SeasonSuitability.notRecommended,
//         9: SeasonSuitability.notRecommended,
//         10: SeasonSuitability.notRecommended,
//         11: SeasonSuitability.notRecommended,
//         12: SeasonSuitability.notRecommended,
//       },
//       monthlyTasks: {},
//     );
//   }
//
//   Crop _createCottonCrop() {
//     return Crop(
//       id: 'cotton',
//       name: 'Cotton',
//       icon: '☁️',
//       themeColor: const Color(0xFF9C27B0),
//       monthSuitability: {
//         1: SeasonSuitability.notRecommended,
//         2: SeasonSuitability.notRecommended,
//         3: SeasonSuitability.notRecommended,
//         4: SeasonSuitability.normal,
//         5: SeasonSuitability.highCompatibility,
//         6: SeasonSuitability.highCompatibility,
//         7: SeasonSuitability.highCompatibility,
//         8: SeasonSuitability.highCompatibility,
//         9: SeasonSuitability.normal,
//         10: SeasonSuitability.notRecommended,
//         11: SeasonSuitability.notRecommended,
//         12: SeasonSuitability.notRecommended,
//       },
//       monthlyTasks: {},
//     );
//   }
// }
