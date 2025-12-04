import 'package:flutter/material.dart';
import '../model/crop_model.dart';
import '../model/weather_model.dart';
import '../model/daily_action_model.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../prior_data/controller/climate_service.dart';

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

  // Load user's farm data from profile
  Future<void> _loadUserFarmData() async {
    _isLoadingCrops = true;
    notifyListeners();

    try {
      final farmData = await _farmDataController.getFarmData();

      if (farmData != null) {
        // Store user location
        _userLatitude = farmData.farmBasics.location.latitude;
        _userLongitude = farmData.farmBasics.location.longitude;
        _userState = farmData.farmBasics.location.state;

        // Load weather based on user's location
        await _loadWeatherForLocation(
          _userLatitude!,
          _userLongitude!,
          _userState,
        );

        // Load crops based on user's selected crops
        _loadUserCrops(farmData.farmBasics.crops);
      } else {
        // No farm data - load defaults
        _loadDefaultCrops();
        _loadWeather();
      }
    } catch (e) {
      print('Error loading farm data: $e');
      _loadDefaultCrops();
      _loadWeather();
    }

    _isLoadingCrops = false;
    notifyListeners();
  }

  // Load crops based on user's profile
  void _loadUserCrops(List<String> userCropNames) {
    _crops.clear();

    // Map user crop names to crop objects
    for (final cropName in userCropNames) {
      Crop? crop;
      switch (cropName.toLowerCase()) {
        case 'rice':
          crop = _createRiceCrop();
          break;
        case 'wheat':
          crop = _createWheatCrop();
          break;
        case 'maize':
          crop = _createMaizeCrop();
          break;
        case 'cotton':
          crop = _createCottonCrop();
          break;
      }
      if (crop != null) {
        _crops.add(crop);
      }
    }

    // If no valid crops found, add default
    if (_crops.isEmpty) {
      _loadDefaultCrops();
    }

    // Select first crop by default
    if (_crops.isNotEmpty) {
      _selectedCrop = _crops[0];
    }
  }

  // Load default crops (fallback)
  void _loadDefaultCrops() {
    _crops = [
      _createRiceCrop(),
      _createWheatCrop(),
      _createMaizeCrop(),
      _createCottonCrop(),
    ];

    // Select first crop by default
    if (_crops.isNotEmpty) {
      _selectedCrop = _crops[0];
    }
  }

  // Load weather data for user's location
  Future<void> _loadWeatherForLocation(
    double latitude,
    double longitude,
    String? state,
  ) async {
    _isLoadingWeather = true;
    notifyListeners();

    try {
      // Get climate data from NASA POWER API
      final climateData = await _climateService.getClimateDataWithFallback(
        latitude: latitude,
        longitude: longitude,
        state: state,
      );

      // Use climate data for current weather estimate
      _currentWeather = Weather(
        temperature: climateData.tavgClimate,
        humidity: 73.0, // TODO: Get from weather API
        rainfallProbability: climateData.prcpAnnualClimate > 5 ? 90.0 : 30.0,
        condition: climateData.prcpAnnualClimate > 5
            ? 'Rainy'
            : 'Partly Cloudy',
        windSpeed: 12.5,
        timestamp: DateTime.now(),
        location: state ?? 'Your Location',
      );

      // Generate alerts based on weather
      _generateWeatherAlerts();
    } catch (e) {
      print('Error loading weather for location: $e');
      _loadWeather(); // Fallback
    }

    _isLoadingWeather = false;
    notifyListeners();
  }

  // Fallback weather loader
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

  // Select a crop
  void selectCrop(Crop crop) {
    _selectedCrop = crop;
    notifyListeners();
  }

  // Select a date
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Select a month
  void selectMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  // Get suitability for a specific month
  SeasonSuitability? getSuitabilityForMonth(int month) {
    if (_selectedCrop == null) return null;
    return _selectedCrop!.monthSuitability[month];
  }

  // Get weekly tasks for selected month
  List<WeeklyTask> getWeeklyTasksForMonth(int month) {
    if (_selectedCrop == null) return [];
    return _selectedCrop!.monthlyTasks[month] ?? [];
  }

  // Get daily action plan
  DailyAction? getDailyActionForDate(DateTime date) {
    if (_selectedCrop == null || _currentWeather == null) return null;

    // Determine crop stage based on month
    final month = date.month;
    String cropStage = _getCropStage(month);

    // Generate recommendations based on weather
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

    // Irrigation recommendations based on rainfall
    if (_currentWeather!.rainfallProbability > 70) {
      recommendations.add(
        ActionRecommendation(
          action: 'Don\'t irrigate today',
          reason:
              'High rainfall probability (${_currentWeather!.rainfallProbability.toInt()}%)',
          type: ActionType.irrigation,
          priority: ActionPriority.avoid,
        ),
      );

      recommendations.add(
        ActionRecommendation(
          action: 'Irrigation recommended tomorrow morning',
          reason: 'Post-rainfall irrigation schedule',
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
          timing: 'early morning or evening',
          priority: ActionPriority.critical,
        ),
      );
    }

    // Fertilization recommendations
    if (_currentWeather!.rainfallProbability > 50) {
      recommendations.add(
        ActionRecommendation(
          action: 'Delay fertilizer application',
          reason: 'Heavy rainfall may wash away nutrients',
          type: ActionType.fertilization,
          timing: 'after 48 hours of rainfall',
          priority: ActionPriority.recommended,
        ),
      );
    }

    // Pest control based on humidity
    if (_currentWeather!.humidity > 80) {
      recommendations.add(
        ActionRecommendation(
          action: 'Monitor for pest activity',
          reason: 'High humidity increases pest risk',
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

    if (_currentWeather!.humidity > 75) {
      warnings.add(
        'High fungal risk due to humidity — check for leaf spot symptoms',
      );
    }

    if (_currentWeather!.temperature > 35) {
      warnings.add('Heat stress possible — ensure adequate irrigation');
    }

    if (_currentWeather!.windSpeed > 25) {
      warnings.add('Strong winds — avoid spraying operations');
    }

    return warnings;
  }

  // Refresh weather data
  Future<void> refreshWeather() async {
    await _loadWeather();
  }

  // Sample crop creation methods
  Crop _createRiceCrop() {
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
            tasks: ['Seed selection', 'Land irrigation', 'Soil preparation'],
          ),
          WeeklyTask(
            week: 2,
            stage: 'Germination',
            tasks: ['Nitrogen fertilizer application', 'Weed control'],
          ),
          WeeklyTask(
            week: 3,
            stage: 'Early Growth',
            tasks: ['Monitor water levels', 'First weeding'],
          ),
          WeeklyTask(
            week: 4,
            stage: 'Growth',
            tasks: ['Irrigation if no rainfall', 'Pest monitoring'],
          ),
        ],
        7: [
          WeeklyTask(
            week: 1,
            stage: 'Vegetative',
            tasks: ['Apply urea fertilizer', 'Maintain water depth'],
          ),
          WeeklyTask(
            week: 2,
            stage: 'Tillering',
            tasks: ['Weed management', 'Check for pests'],
          ),
          WeeklyTask(
            week: 3,
            stage: 'Growth',
            tasks: ['Ensure proper drainage', 'Monitor plant health'],
          ),
          WeeklyTask(
            week: 4,
            stage: 'Pest Alert',
            tasks: ['Spray advisory based on weather', 'Leaf folder control'],
          ),
        ],
      },
    );
  }

  Crop _createWheatCrop() {
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
    );
  }

  Crop _createMaizeCrop() {
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
    );
  }

  Crop _createCottonCrop() {
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
    );
  }
}
