import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/farm_data_model.dart';

class ClimateService {
  // NASA POWER API - Free, no API key required
  static const String _baseUrl =
      'https://power.larc.nasa.gov/api/temporal/climatology/point';

  /// Fetch 20-year climate averages from NASA POWER API
  /// This is the SAME data source used in your ML model training!
  Future<ClimateDataModel?> getClimateData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Parameters required by ML model:
      // T2M = Temperature at 2 Meters (°C)
      // T2M_MIN = Minimum Temperature at 2 Meters (°C)
      // T2M_MAX = Maximum Temperature at 2 Meters (°C)
      // PRECTOTCORR = Precipitation Corrected (mm/day)

      final url = Uri.parse(
        '$_baseUrl?'
        'parameters=T2M,T2M_MIN,T2M_MAX,PRECTOTCORR&'
        'community=AG&'
        'longitude=$longitude&'
        'latitude=$latitude&'
        'format=JSON',
      );

      print('🌍 Fetching climate data from NASA POWER API...');
      print('   Location: $latitude, $longitude');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('NASA API request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract climatology data (20-year averages)
        final params = data['properties']['parameter'];

        // Get annual averages
        final tavg = params['T2M']?['ANN']?.toDouble() ?? 0.0;
        final tmin = params['T2M_MIN']?['ANN']?.toDouble() ?? 0.0;
        final tmax = params['T2M_MAX']?['ANN']?.toDouble() ?? 0.0;
        final prcp = params['PRECTOTCORR']?['ANN']?.toDouble() ?? 0.0;

        print('✅ Climate data fetched successfully!');
        print('   Avg Temp: $tavg°C');
        print('   Min Temp: $tmin°C');
        print('   Max Temp: $tmax°C');
        print('   Daily Rainfall: ${prcp}mm');

        return ClimateDataModel(
          tavgClimate: tavg,
          tminClimate: tmin,
          tmaxClimate: tmax,
          prcpAnnualClimate: prcp,
          fetchedAt: DateTime.now(),
        );
      } else {
        print('❌ NASA API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching climate data: $e');
      return null;
    }
  }

  /// Get climate data with fallback to defaults
  Future<ClimateDataModel> getClimateDataWithFallback({
    required double latitude,
    required double longitude,
    String? state,
  }) async {
    final data = await getClimateData(latitude: latitude, longitude: longitude);

    if (data != null) {
      return data;
    }

    // Fallback to regional defaults based on state (approximate Indian climate)
    print('⚠️ Using fallback climate data for India');
    return ClimateDataModel(
      tavgClimate: 26.0, // Average for India
      tminClimate: 22.0,
      tmaxClimate: 32.0,
      prcpAnnualClimate: 3.5, // ~1275mm/year
      fetchedAt: DateTime.now(),
    );
  }
}
