import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

/// Service to match crop varieties based on soil pH and texture from variety.xls
class VarietyMatcherService {
  static List<Map<String, dynamic>>? _varietyData;

  /// Load and parse variety.xls (CSV format)
  static Future<void> loadVarietyData() async {
    if (_varietyData != null) return; // Already loaded

    try {
      final csvString = await rootBundle.loadString(
        'lib/crop_yield_prediction/variety.xls',
      );

      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) return;

      // First row is header
      final headers = rows[0].map((e) => e.toString()).toList();

      _varietyData = [];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final Map<String, dynamic> entry = {};

        for (var j = 0; j < headers.length; j++) {
          if (j < row.length) {
            entry[headers[j]] = row[j];
          }
        }

        _varietyData!.add(entry);
      }

      print('✅ Loaded ${_varietyData!.length} variety records');
    } catch (e) {
      print('❌ Error loading variety data: $e');
      _varietyData = [];
    }
  }

  /// Find matching crop varieties based on soil pH and texture
  static Future<List<CropVarietyMatch>> findMatchingVarieties({
    required double soilPH,
    required String soilTexture,
    String? preferredCrop,
  }) async {
    await loadVarietyData();

    if (_varietyData == null || _varietyData!.isEmpty) {
      return [];
    }

    print(
      '🔍 Matching for: pH=$soilPH, texture=$soilTexture, crop=$preferredCrop',
    );

    final List<CropVarietyMatch> matches = [];
    int checkedCount = 0;
    int textureMatches = 0;
    int phMatches = 0;

    for (final entry in _varietyData!) {
      checkedCount++;

      // IMPORTANT: CSV stores pH multiplied by 10 (e.g., 65 = pH 6.5)
      final entryPHx10 = _parseDouble(entry['soil_pH']);
      final entryPH = entryPHx10 != null ? entryPHx10 / 10 : null;
      final entryTexture = entry['soil_texture']?.toString() ?? '';

      // Match soil texture exactly
      if (entryTexture != soilTexture) {
        if (checkedCount <= 3) {
          print(
            '   ❌ Row $checkedCount: texture mismatch ($entryTexture ≠ $soilTexture)',
          );
        }
        continue;
      }

      textureMatches++;

      // Match pH within ±0.5 range
      if (entryPH != null && (soilPH - entryPH).abs() <= 0.5) {
        phMatches++;

        final cropsJson = entry['crops']?.toString() ?? '';
        final varieties = _parseCropVarieties(cropsJson);

        // Filter by preferred crop if specified
        final filteredVarieties = preferredCrop != null
            ? varieties
                  .where(
                    (v) =>
                        v['crop']?.toString().toLowerCase().contains(
                          preferredCrop.toLowerCase(),
                        ) ??
                        false,
                  )
                  .toList()
            : varieties;

        if (filteredVarieties.isNotEmpty) {
          final district = entry['district']?.toString() ?? 'Unknown';
          print(
            '   ✅ Match found: $district (pH=${entryPH.toStringAsFixed(1)}, texture=$entryTexture, ${filteredVarieties.length} varieties)',
          );

          matches.add(
            CropVarietyMatch(
              district: district,
              soilPH: entryPH,
              soilTexture: entryTexture,
              elevation: _parseDouble(entry['elevation']) ?? 0,
              annualRainfall: _parseDouble(entry['annual_rainfall_mm']) ?? 0,
              meanTemp: (_parseDouble(entry['mean_temp_x10']) ?? 0) / 10,
              ndviMean: _parseDouble(entry['NDVI_mean']) ?? 0,
              soilOrganicCarbon:
                  _parseDouble(entry['soil_organic_carbon']) ?? 0,
              varieties: filteredVarieties,
            ),
          );
        } else if (preferredCrop != null) {
          print(
            '   ⚠️ Soil match but no $preferredCrop varieties in ${entry['district']}',
          );
        }
      } else if (entryPH != null && textureMatches <= 3) {
        print(
          '   ❌ pH mismatch: $entryPH (diff: ${(soilPH - entryPH).abs().toStringAsFixed(2)})',
        );
      }
    }

    print('📊 Matching summary: Checked $checkedCount records');
    print('   - Texture matches: $textureMatches');
    print('   - pH matches: $phMatches');
    print('   - Final matches with varieties: ${matches.length}');

    // Sort by closest pH match
    matches.sort((a, b) {
      final aDiff = (a.soilPH - soilPH).abs();
      final bDiff = (b.soilPH - soilPH).abs();
      return aDiff.compareTo(bDiff);
    });

    return matches;
  }

  /// Parse crop varieties from JSON string
  static List<Map<String, String>> _parseCropVarieties(String cropsJson) {
    try {
      // Format: [{variety=CR Dhan 215, crop=Rice}, {...}]
      final cleaned = cropsJson
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('{', '')
          .replaceAll('}', '');

      final items = cleaned.split(', ');
      final List<Map<String, String>> varieties = [];
      Map<String, String> current = {};

      for (final item in items) {
        if (item.contains('=')) {
          final parts = item.split('=');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();

            current[key] = value;

            // If we have both crop and variety, add to list
            if (current.containsKey('crop') && current.containsKey('variety')) {
              varieties.add(Map.from(current));
              current = {};
            }
          }
        }
      }

      return varieties;
    } catch (e) {
      print('⚠️ Error parsing varieties: $e');
      return [];
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Represents a matched crop variety from the database
class CropVarietyMatch {
  final String district;
  final double soilPH;
  final String soilTexture;
  final double elevation;
  final double annualRainfall;
  final double meanTemp;
  final double ndviMean;
  final double soilOrganicCarbon;
  final List<Map<String, String>> varieties;

  CropVarietyMatch({
    required this.district,
    required this.soilPH,
    required this.soilTexture,
    required this.elevation,
    required this.annualRainfall,
    required this.meanTemp,
    required this.ndviMean,
    required this.soilOrganicCarbon,
    required this.varieties,
  });

  /// Get all unique crops
  List<String> get crops {
    return varieties
        .map((v) => v['crop'] ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Get varieties for a specific crop
  List<String> getVarietiesForCrop(String crop) {
    return varieties
        .where((v) => v['crop']?.toLowerCase() == crop.toLowerCase())
        .map((v) => v['variety'] ?? '')
        .where((v) => v.isNotEmpty)
        .toList();
  }

  @override
  String toString() {
    return 'CropVarietyMatch(district: $district, pH: $soilPH, texture: $soilTexture, varieties: ${varieties.length})';
  }
}
