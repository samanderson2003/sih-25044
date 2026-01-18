import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'sentinel_hub_service.dart';

/// Automated Farm Data Collection Service
/// Fetches ALL required data for crop yield prediction automatically
/// using GPS, Sentinel Hub, OpenWeather, and SoilGrids APIs
class AutoFarmDataService {
  final SentinelHubService _sentinelHub = SentinelHubService();

  // OpenWeather API - Replace with your key
  static String get _openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  /// Get comprehensive farm data automatically from user's location
  /// Returns all data needed for AgriAIInput model
  Future<Map<String, dynamic>> getCompleteFarmData({
    double? customLat,
    double? customLon,
  }) async {
    try {
      // 1. Get User Location (GPS or Custom)
      late double latitude;
      late double longitude;

      if (customLat != null && customLon != null) {
        latitude = customLat;
        longitude = customLon;
      } else {
        final position = await _getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      print('📍 Location: $latitude, $longitude');

      // 2. Get all data in parallel for speed
      final results = await Future.wait([
        _getDistrictFromLocation(latitude, longitude), // District
        _getWeatherData(latitude, longitude), // Temp, Rain
        _getSoilData(latitude, longitude), // pH, Soil Type, SOC
        _getSatelliteData(latitude, longitude), // NDVI, NDVI Anomaly, EVI, LST
      ]);

      final districtData = results[0];
      final weatherData = results[1];
      final soilData = results[2];
      final satelliteData = results[3];

      // 3. Combine all data
      return {
        // Location
        'district': districtData['district'],
        'latitude': latitude,
        'longitude': longitude,

        // Soil
        'soil_type': soilData['soil_type'],
        'ph': soilData['ph'],
        'soc': soilData['soc'],

        // Climate
        'rain_mm': weatherData['rain_mm'],
        'temp_c': weatherData['temp_c'],

        // Satellite Data
        'ndvi_max': satelliteData['ndvi_max'],
        'ndvi_anomaly': satelliteData['ndvi_anomaly'],
        'evi_max': satelliteData['evi_max'],
        'lst': satelliteData['lst'],
        'elevation': satelliteData['elevation'],
        'dry_wet_index': satelliteData['dry_wet_index'],

        // Metadata
        'auto_collected': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error collecting farm data: $e');
      rethrow;
    }
  }

  /// Get current GPS location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get district name from GPS coordinates using reverse geocoding
  Future<Map<String, dynamic>> _getDistrictFromLocation(
    double lat,
    double lon,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String? district = place.subAdministrativeArea ?? place.locality;

        // Map common district names to Odisha districts in your model
        final odishaDistricts = [
          'Mayurbhanj',
          'Keonjhar',
          'Ganjam',
          'Puri',
          'Bolangir',
          'Cuttack',
          'Jajpur',
          'Balasore',
          'Khordha',
          'Sambalpur',
        ];

        // Try to match to known districts
        String matchedDistrict = 'Mayurbhanj'; // Default
        if (district != null) {
          for (var d in odishaDistricts) {
            if (district.toLowerCase().contains(d.toLowerCase())) {
              matchedDistrict = d;
              break;
            }
          }
        }

        return {
          'district': matchedDistrict,
          'state': place.administrativeArea ?? 'Odisha',
          'raw_district': district,
        };
      }

      return {'district': 'Mayurbhanj', 'state': 'Odisha'};
    } catch (e) {
      print('⚠️ District detection failed, using default: $e');
      return {'district': 'Mayurbhanj', 'state': 'Odisha'};
    }
  }

  /// Get weather data from OpenWeather API
  Future<Map<String, dynamic>> _getWeatherData(double lat, double lon) async {
    try {
      // Get current weather
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric';

      final currentResponse = await http.get(Uri.parse(currentUrl));

      if (currentResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);

        // Get annual rainfall estimate (use last 30 days * 12 as approximation)
        final tempC = (currentData['main']['temp'] ?? 27.0).toDouble();

        // Get historical data for rainfall estimation
        // For now, use regional average for Odisha (1400mm annual)
        // In production, use OpenWeather OneCall API for historical data
        final annualRainMm = await _estimateAnnualRainfall(lat, lon);

        return {
          'temp_c': tempC,
          'rain_mm': annualRainMm,
          'humidity': (currentData['main']['humidity'] ?? 70.0).toDouble(),
          'wind_speed':
              (currentData['wind']['speed'] ?? 10.0).toDouble() *
              3.6, // m/s to km/h
        };
      }

      // Fallback to regional averages for Odisha
      return _getRegionalAverages(lat, lon);
    } catch (e) {
      print('⚠️ Weather API failed, using regional averages: $e');
      return _getRegionalAverages(lat, lon);
    }
  }

  /// Estimate annual rainfall from OpenWeather or use regional data
  Future<double> _estimateAnnualRainfall(double lat, double lon) async {
    // Odisha regional rainfall averages (mm/year)
    // Coastal: 1400-1600, Interior: 1200-1400, Western: 1000-1200
    if (lat > 20.5) {
      return 1500.0; // Northern Odisha (Mayurbhanj, Keonjhar)
    } else if (lon < 84.5) {
      return 1200.0; // Western Odisha (Bolangir, Sambalpur)
    } else {
      return 1400.0; // Coastal Odisha (Puri, Ganjam, Cuttack)
    }
  }

  /// Get regional climate averages for Odisha
  Map<String, dynamic> _getRegionalAverages(double lat, double lon) {
    return {
      'temp_c': 27.0,
      'rain_mm': 1400.0,
      'humidity': 70.0,
      'wind_speed': 12.0,
    };
  }

  /// Get soil data from SoilGrids API (ISRIC World Soil Information)
  Future<Map<String, dynamic>> _getSoilData(double lat, double lon) async {
    try {
      // SoilGrids API - Free and accurate
      final soilGridsUrl =
          'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$lon&lat=$lat&property=phh2o&property=soc&property=clay&property=sand&property=silt&depth=0-5cm&value=mean';

      final response = await http.get(Uri.parse(soilGridsUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract pH (phh2o in H2O, scaled by 10)
        final phData = data['properties']?['layers']?.firstWhere(
          (l) => l['name'] == 'phh2o',
          orElse: () => null,
        );
        final ph = phData != null
            ? ((phData['depths'][0]['values']['mean'] as num?)?.toDouble() ?? 65.0) / 10.0
            : 6.5;

        // Extract SOC (Soil Organic Carbon, in g/kg, divide by 10 for %)
        final socData = data['properties']?['layers']?.firstWhere(
          (l) => l['name'] == 'soc',
          orElse: () => null,
        );
        final soc = socData != null
            ? ((socData['depths'][0]['values']['mean'] as num?)?.toDouble() ?? 5.0) / 10.0
            : 0.5;

        // Extract soil texture (clay, sand, silt percentages)
        final clayData = data['properties']?['layers']?.firstWhere(
          (l) => l['name'] == 'clay',
          orElse: () => null,
        );
        final sandData = data['properties']?['layers']?.firstWhere(
          (l) => l['name'] == 'sand',
          orElse: () => null,
        );

        final clay = clayData != null
            ? (clayData['depths'][0]['values']['mean'] as num?)?.toDouble() ?? 25.0
            : 25.0;
        final sand = sandData != null
            ? (sandData['depths'][0]['values']['mean'] as num?)?.toDouble() ?? 40.0
            : 40.0;

        // Determine soil type from texture
        final soilType = _determineSoilType(clay, sand);

        return {
          'ph': ph,
          'soc': soc,
          'soil_type': soilType,
          'clay_percent': clay,
          'sand_percent': sand,
        };
      }

      // Fallback to regional defaults
      return _getRegionalSoilDefaults(lat, lon);
    } catch (e) {
      print('⚠️ SoilGrids API failed, using regional defaults: $e');
      return _getRegionalSoilDefaults(lat, lon);
    }
  }

  /// Determine soil type from clay and sand percentages
  String _determineSoilType(double clay, double sand) {
    if (clay >= 40) {
      return 'Clay';
    } else if (clay >= 27 && clay < 40) {
      if (sand >= 45) {
        return 'Sandy Clay';
      } else {
        return 'Clay Loam';
      }
    } else if (clay >= 20 && clay < 27) {
      if (sand >= 45) {
        return 'Sandy Clay Loam';
      } else {
        return 'Loam';
      }
    } else if (clay >= 7 && clay < 20) {
      if (sand >= 52) {
        return 'Sandy Loam';
      } else {
        return 'Silt Loam';
      }
    } else {
      return 'Sandy Loam';
    }
  }

  /// Get regional soil defaults for Odisha
  Map<String, dynamic> _getRegionalSoilDefaults(double lat, double lon) {
    // Odisha soil type patterns
    // Coastal: Sandy Clay, Interior: Clay Loam, Uplands: Sandy Loam
    String soilType;
    if (lon > 85.0) {
      soilType = 'Sandy Clay'; // Coastal
    } else if (lat > 20.5) {
      soilType = 'Sandy Loam'; // Uplands (Mayurbhanj, Keonjhar)
    } else {
      soilType = 'Clay Loam'; // Interior
    }

    return {
      'ph': 6.5,
      'soc': 0.5,
      'soil_type': soilType,
      'clay_percent': 25.0,
      'sand_percent': 40.0,
    };
  }

  /// Get satellite data from Sentinel Hub
  Future<Map<String, dynamic>> _getSatelliteData(double lat, double lon) async {
    try {
      final healthData = await _sentinelHub.analyzeVegetationHealth(
        latitude: lat,
        longitude: lon,
        bufferKm: 0.5,
      );

      // Extract NDVI and calculate anomaly
      final ndviMean = (healthData['ndvi_mean'] ?? 0.6).toDouble();

      // Calculate NDVI Anomaly (compare to healthy baseline)
      // Healthy NDVI for crops: 0.6-0.9
      // Anomaly = current - expected
      final healthyBaseline = 0.75;
      final ndviAnomaly = ndviMean - healthyBaseline;

      // Estimate EVI from NDVI (simplified formula)
      final evi = (ndviMean * 6000).toDouble(); // Scale to 0-6000 range

      // Get LST (Land Surface Temperature) from satellite data
      // For now, use temp from weather + 5°C (surfaces are typically warmer)
      final lst = 30.0; // Will be enhanced with actual LST from Sentinel

      // Get elevation (approximate from lat/lon)
      final elevation = await _getElevation(lat, lon);

      return {
        'ndvi_max': ndviMean,
        'ndvi_anomaly': ndviAnomaly,
        'evi_max': evi,
        'lst': lst,
        'elevation': elevation,
        'dry_wet_index': 10.0, // Will be calculated from rainfall patterns
        'stress_detected': healthData['stress_detected'] ?? false,
        'health_status': healthData['health_status'] ?? 'unknown',
      };
    } catch (e) {
      print('⚠️ Satellite data collection failed, using defaults: $e');
      return {
        'ndvi_max': 0.6,
        'ndvi_anomaly': 0.0,
        'evi_max': 4000.0,
        'lst': 30.0,
        'elevation': 100.0,
        'dry_wet_index': 10.0,
        'stress_detected': false,
        'health_status': 'unknown',
      };
    }
  }

  /// Get elevation from Open Elevation API (free)
  Future<double> _getElevation(double lat, double lon) async {
    try {
      final url =
          'https://api.open-elevation.com/api/v1/lookup?locations=$lat,$lon';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'][0]['elevation'] ?? 100.0).toDouble();
      }

      return 100.0; // Default elevation
    } catch (e) {
      return 100.0; // Default on error
    }
  }

  /// Quick check if auto-collection is possible
  Future<bool> canAutoCollectData() async {
    try {
      // Check location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled;
    } catch (e) {
      return false;
    }
  }
}
