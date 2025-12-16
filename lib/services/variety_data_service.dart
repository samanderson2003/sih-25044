import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class VarietyDataService {
  Map<String, List<Map<String, dynamic>>>? _cachedData;

  /// Load and parse variety.xls data
  Future<Map<String, List<Map<String, dynamic>>>> loadVarietyData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      final String csvData = await rootBundle.loadString('lib/crop_yield_prediction/variety.xls');
      final List<String> lines = csvData.split('\n');
      
      if (lines.isEmpty) throw Exception('Empty variety data file');

      // Parse header
      final headers = lines[0].split(',');
      
      // Parse data rows
      Map<String, List<Map<String, dynamic>>> districtData = {};
      
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        final Map<String, dynamic> row = _parseRow(lines[i], headers);
        if (row.isEmpty) continue;
        
        final String district = row['district'] ?? 'Unknown';
        
        if (!districtData.containsKey(district)) {
          districtData[district] = [];
        }
        
        districtData[district]!.add(row);
      }
      
      _cachedData = districtData;
      print('✅ Loaded variety data for ${districtData.keys.length} districts');
      return districtData;
    } catch (e) {
      print('❌ Failed to load variety data: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseRow(String line, List<String> headers) {
    try {
      // Handle complex parsing for crops field which contains JSON-like array
      final Map<String, dynamic> row = {};
      
      // Split by comma but be careful with the crops field
      int cropStart = line.indexOf('"[{');
      int cropEnd = line.indexOf('}]"');
      
      if (cropStart != -1 && cropEnd != -1) {
        // Extract parts
        final beforeCrops = line.substring(0, cropStart);
        final cropsStr = line.substring(cropStart + 1, cropEnd + 2); // Include quotes
        final afterCrops = line.substring(cropEnd + 3);
        
        // Parse before crops
        final beforeParts = beforeCrops.split(',');
        
        // Parse after crops
        final afterParts = afterCrops.split(',');
        
        // Map data
        int idx = 0;
        for (int i = 0; i < headers.length; i++) {
          final header = headers[i].trim();
          
          if (header == 'crops') {
            row[header] = _parseCrops(cropsStr);
          } else if (idx < beforeParts.length) {
            row[header] = _parseValue(beforeParts[idx].trim(), header);
            idx++;
          } else if (idx - beforeParts.length < afterParts.length) {
            row[header] = _parseValue(afterParts[idx - beforeParts.length].trim(), header);
            idx++;
          }
        }
      } else {
        // Simple row without complex crops field
        final parts = line.split(',');
        for (int i = 0; i < headers.length && i < parts.length; i++) {
          row[headers[i].trim()] = _parseValue(parts[i].trim(), headers[i].trim());
        }
      }
      
      return row;
    } catch (e) {
      print('❌ Failed to parse row: $e');
      return {};
    }
  }

  dynamic _parseValue(String value, String header) {
    value = value.replaceAll('"', '').trim();
    
    if (value.isEmpty) return null;
    
    // Try to parse as number
    final num? numValue = num.tryParse(value);
    if (numValue != null) return numValue;
    
    return value;
  }

  List<Map<String, String>> _parseCrops(String cropsStr) {
    try {
      // Remove quotes and parse the array-like structure
      String cleaned = cropsStr.replaceAll('"', '').replaceAll('[{', '[{"').replaceAll('=', '":"').replaceAll('}, {', '"}, {"').replaceAll(', ', '", "').replaceAll('}]', '"}]');
      
      // Manual parsing for safety
      List<Map<String, String>> crops = [];
      
      // Extract crop objects
      final cropMatches = RegExp(r'\{([^}]+)\}').allMatches(cropsStr);
      
      for (final match in cropMatches) {
        final cropStr = match.group(1) ?? '';
        final Map<String, String> crop = {};
        
        // Extract variety and crop name
        final varietyMatch = RegExp(r'variety=([^,}]+)').firstMatch(cropStr);
        final cropMatch = RegExp(r'crop=([^,}]+)').firstMatch(cropStr);
        
        if (varietyMatch != null) {
          crop['variety'] = varietyMatch.group(1)!.trim();
        }
        if (cropMatch != null) {
          crop['crop'] = cropMatch.group(1)!.trim();
        }
        
        if (crop.isNotEmpty) {
          crops.add(crop);
        }
      }
      
      return crops;
    } catch (e) {
      print('❌ Failed to parse crops: $e');
      return [];
    }
  }

  /// Get variety data for specific district and crop
  Future<Map<String, dynamic>?> getVarietyData({
    required String district,
    required String crop,
    String? variety,
  }) async {
    final data = await loadVarietyData();
    
    if (!data.containsKey(district)) {
      print('⚠️ District not found: $district');
      return null;
    }
    
    final districtRows = data[district]!;
    
    // Find matching crop/variety
    for (final row in districtRows) {
      final crops = row['crops'] as List<Map<String, String>>?;
      if (crops == null) continue;
      
      for (final cropData in crops) {
        final match = cropData['crop']?.toLowerCase() == crop.toLowerCase();
        final varietyMatch = variety == null || cropData['variety'] == variety;
        
        if (match && varietyMatch) {
          return {
            'ndvi': row['NDVI_mean'],
            'rainfall': row['annual_rainfall_mm'],
            'elevation': row['elevation'],
            'mean_temp': row['mean_temp_x10'] != null ? (row['mean_temp_x10'] as num) / 10 : null,
            'soil_organic_carbon': row['soil_organic_carbon'],
            'soil_ph': row['soil_pH'],
            'soil_texture': row['soil_texture'],
            'district': district,
            'variety': cropData['variety'],
            'crop': cropData['crop'],
          };
        }
      }
    }
    
    print('⚠️ No variety data found for $crop ($variety) in $district');
    return null;
  }

  /// Get all available varieties for a crop in a district
  Future<List<String>> getAvailableVarieties({
    required String district,
    required String crop,
  }) async {
    final data = await loadVarietyData();
    
    if (!data.containsKey(district)) return [];
    
    final districtRows = data[district]!;
    final Set<String> varieties = {};
    
    for (final row in districtRows) {
      final crops = row['crops'] as List<Map<String, String>>?;
      if (crops == null) continue;
      
      for (final cropData in crops) {
        if (cropData['crop']?.toLowerCase() == crop.toLowerCase()) {
          final variety = cropData['variety'];
          if (variety != null && variety.isNotEmpty) {
            varieties.add(variety);
          }
        }
      }
    }
    
    return varieties.toList();
  }
}
