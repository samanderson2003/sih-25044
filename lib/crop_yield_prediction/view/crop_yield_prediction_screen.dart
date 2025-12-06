import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/crop_yield_model.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../services/ml_api_service.dart';
import '../../widgets/translated_text.dart';
import '../../providers/language_provider.dart';
import '../../services/translation_service.dart';

class CropYieldPredictionScreen extends StatefulWidget {
  const CropYieldPredictionScreen({super.key});

  @override
  State<CropYieldPredictionScreen> createState() =>
      _CropYieldPredictionScreenState();
}

class _CropYieldPredictionScreenState extends State<CropYieldPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final FarmDataController _farmDataController = FarmDataController();

  bool _isLoading = false;
  CropPredictionResponse? _predictionResult;

  // Form controllers - will be filled from user's saved farm data
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _tavgController = TextEditingController();
  final TextEditingController _tminController = TextEditingController();
  final TextEditingController _tmaxController = TextEditingController();
  final TextEditingController _prcpController = TextEditingController();
  final TextEditingController _znController = TextEditingController();
  final TextEditingController _feController = TextEditingController();
  final TextEditingController _cuController = TextEditingController();
  final TextEditingController _mnController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  final TextEditingController _sController = TextEditingController();

  String _selectedCrop = 'Rice';
  String _selectedSeason = 'Kharif';
  int _selectedYear = 2020;

  final List<String> _crops = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane'];
  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];

  @override
  void initState() {
    super.initState();
    _loadFarmDataFromProfile();
  }

  Future<void> _loadFarmDataFromProfile() async {
    try {
      final farmData = await _farmDataController.getFarmData();

      if (farmData != null && mounted) {
        setState(() {
          // Farm basics
          _areaController.text = farmData.farmBasics.landSize.toString();

          // Set first crop if multiple crops exist
          if (farmData.farmBasics.crops.isNotEmpty) {
            final userCrop = farmData.farmBasics.crops.first;
            if (_crops.contains(userCrop)) {
              _selectedCrop = userCrop;
            }
          }

          // Climate data
          if (farmData.climateData != null) {
            _tavgController.text = farmData.climateData!.tavgClimate
                .toStringAsFixed(1);
            _tminController.text = farmData.climateData!.tminClimate
                .toStringAsFixed(1);
            _tmaxController.text = farmData.climateData!.tmaxClimate
                .toStringAsFixed(1);
            _prcpController.text = farmData.climateData!.prcpAnnualClimate
                .toStringAsFixed(1);
          }

          // Soil quality
          _znController.text = (farmData.soilQuality.zinc ?? 75.0)
              .toStringAsFixed(1);
          _feController.text = (farmData.soilQuality.iron ?? 85.0)
              .toStringAsFixed(1);
          _cuController.text = (farmData.soilQuality.copper ?? 80.0)
              .toStringAsFixed(1);
          _mnController.text = (farmData.soilQuality.manganese ?? 85.0)
              .toStringAsFixed(1);
          _bController.text = (farmData.soilQuality.boron ?? 80.0)
              .toStringAsFixed(1);
          _sController.text = (farmData.soilQuality.sulfur ?? 0.5)
              .toStringAsFixed(2);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Farm data loaded from your profile'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // No farm data - use defaults
        setState(() {
          _areaController.text = '2.0';
          _tavgController.text = '28.0';
          _tminController.text = '24.0';
          _tmaxController.text = '33.0';
          _prcpController.text = '5.5';
          _znController.text = '75.0';
          _feController.text = '85.0';
          _cuController.text = '80.0';
          _mnController.text = '85.0';
          _bController.text = '80.0';
          _sController.text = '0.5';
        });
      }
    } catch (e) {
      print('Error loading farm data: $e');
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _tavgController.dispose();
    _tminController.dispose();
    _tmaxController.dispose();
    _prcpController.dispose();
    _znController.dispose();
    _feController.dispose();
    _cuController.dispose();
    _mnController.dispose();
    _bController.dispose();
    _sController.dispose();
    super.dispose();
  }

  Future<void> _submitPrediction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      // Prepare farm data for ML API
      final farmData = {
        'location': {
          'latitude': 0.0, // Will be from user's saved location
          'longitude': 0.0,
        },
        'farm_area_acres': double.parse(_areaController.text),
        'crop_type': _selectedCrop.toLowerCase(),
        'season': _selectedSeason,
        'planting_date': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
        'climate': {
          'tavg': double.parse(_tavgController.text),
          'tmin': double.parse(_tminController.text),
          'tmax': double.parse(_tmaxController.text),
          'prcp': double.parse(_prcpController.text),
        },
        'soil': {
          'zn': double.parse(_znController.text),
          'fe': double.parse(_feController.text),
          'cu': double.parse(_cuController.text),
          'mn': double.parse(_mnController.text),
          'b': double.parse(_bController.text),
          's': double.parse(_sController.text),
        },
      };

      // Call ML API
      final response = await MLApiService.predictYield(farmData: farmData);

      if (response == null) {
        throw Exception('Failed to get prediction from ML API');
      }

      // Extract yield forecast data
      final yieldData = response['yield_forecast'] as Map<String, dynamic>;
      final economicData =
          response['economic_estimate'] as Map<String, dynamic>;

      // Convert ML API response to CropPredictionResponse format
      final result = CropPredictionResponse(
        crop: _selectedCrop,
        season: _selectedSeason,
        farmAreaAcres: double.parse(_areaController.text),
        farmAreaHectares: double.parse(_areaController.text) * 0.404686,
        yieldForecast: YieldForecast(
          perHectareTonnes: (yieldData['per_hectare_tonnes'] as num).toDouble(),
          totalExpectedTonnes: (yieldData['total_expected_tonnes'] as num)
              .toDouble(),
          totalKg: (yieldData['total_kg'] as num).toDouble(),
          confidenceLevel: yieldData['confidence_level'] as int,
          modelR2: 0.71, // From our XGBoost model
        ),
        climate: {
          'tavg': double.parse(_tavgController.text),
          'tmin': double.parse(_tminController.text),
          'tmax': double.parse(_tmaxController.text),
          'prcp': double.parse(_prcpController.text),
        },
        soilHealth: SoilStatus(
          zinc: _znController.text.isEmpty ? 'Normal' : 'Good',
          iron: _feController.text.isEmpty ? 'Normal' : 'Good',
          sulfur: _sController.text.isEmpty ? 'Normal' : 'Good',
        ),
        irrigationSuggestion: 'Moderate',
        irrigationDetail:
            'Based on current soil moisture and climate conditions',
        fertilizerRecommendation: ['NPK 10-26-26', 'Urea'],
        cropSuitability: CropSuitability(
          rating: 'Suitable',
          score: 85,
          factors: ['Good climate', 'Adequate soil nutrients'],
        ),
        highRiskAlerts: [],
        mediumRiskAlerts: [],
        economicEstimate: EconomicEstimate(
          expectedIncomeLow:
              (economicData['gross_income_low'] as num?)?.toDouble() ?? 0.0,
          expectedIncomeHigh:
              (economicData['gross_income_high'] as num?)?.toDouble() ?? 0.0,
          estimatedCosts:
              (economicData['total_cost'] as num?)?.toDouble() ?? 0.0,
          netProfitLow:
              (economicData['net_profit_low'] as num?)?.toDouble() ?? 0.0,
          netProfitHigh:
              (economicData['net_profit_high'] as num?)?.toDouble() ?? 0.0,
          roiLow: (economicData['roi_low'] as num?)?.toDouble() ?? 0.0,
          roiHigh: (economicData['roi_high'] as num?)?.toDouble() ?? 0.0,
        ),
        additionalRecommendations: [
          'Monitor soil moisture regularly',
          'Apply fertilizers as per soil test recommendations',
        ],
      );

      setState(() {
        _predictionResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: _predictionResult == null ? _buildInputForm() : _buildResultsView(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Banner
            const SizedBox(height: 20),

            _buildSectionTitle('Farm Details'),
            _buildTextField(
              controller: _areaController,
              label: 'Farm Area (acres)',
              hint: 'Enter area in acres',
              icon: Icons.landscape,
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Crop Type',
              value: _selectedCrop,
              items: _crops,
              onChanged: (value) => setState(() => _selectedCrop = value!),
              icon: Icons.eco,
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Season',
              value: _selectedSeason,
              items: _seasons,
              onChanged: (value) => setState(() => _selectedSeason = value!),
              icon: Icons.wb_sunny,
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Year',
              value: _selectedYear.toString(),
              items: List.generate(6, (index) => (2020 + index).toString()),
              onChanged: (value) =>
                  setState(() => _selectedYear = int.parse(value!)),
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Climate Data'),
            _buildTextField(
              controller: _tavgController,
              label: 'Average Temperature (°C)',
              hint: 'e.g., 28.0',
              icon: Icons.thermostat,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _tminController,
              label: 'Minimum Temperature (°C)',
              hint: 'e.g., 24.0',
              icon: Icons.thermostat_outlined,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _tmaxController,
              label: 'Maximum Temperature (°C)',
              hint: 'e.g., 33.0',
              icon: Icons.thermostat_outlined,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _prcpController,
              label: 'Daily Precipitation (mm)',
              hint: 'e.g., 5.5',
              icon: Icons.water_drop,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Soil Nutrients (%)'),
            _buildTextField(
              controller: _znController,
              label: 'Zinc (Zn %)',
              hint: 'e.g., 80',
              icon: Icons.science,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _feController,
              label: 'Iron (Fe %)',
              hint: 'e.g., 94',
              icon: Icons.science,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _cuController,
              label: 'Copper (Cu %)',
              hint: 'e.g., 90',
              icon: Icons.science,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _mnController,
              label: 'Manganese (Mn %)',
              hint: 'e.g., 97',
              icon: Icons.science,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _bController,
              label: 'Boron (B %)',
              hint: 'e.g., 98',
              icon: Icons.science,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _sController,
              label: 'Sulfur (S %)',
              hint: 'e.g., 0.7',
              icon: Icons.science,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitPrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const TranslatedText(
                      'Predict Yield',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final result = _predictionResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            color: const Color(0xFF2D5016),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    result.crop,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.season} Season • ${result.yieldForecast.confidenceLevel}% Confidence',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Yield Forecast
          _buildResultCard(
            title: '🌾 Yield Forecast',
            children: [
              _buildResultRow(
                'Per Hectare',
                '${result.yieldForecast.perHectareTonnes.toStringAsFixed(2)} tonnes',
              ),
              _buildResultRow(
                'Total Expected',
                '${result.yieldForecast.totalExpectedTonnes.toStringAsFixed(2)} tonnes',
              ),
              _buildResultRow(
                'Total Kg',
                '${result.yieldForecast.totalKg.toStringAsFixed(0)} kg',
              ),
              _buildResultRow(
                'Farm Area',
                '${result.farmAreaAcres.toStringAsFixed(2)} acres (${result.farmAreaHectares.toStringAsFixed(2)} ha)',
              ),
            ],
          ),

          // Economic Estimate
          _buildResultCard(
            title: '💰 Economic Estimate',
            children: [
              _buildResultRow(
                'Expected Income',
                '₹${result.economicEstimate.expectedIncomeLow.toStringAsFixed(0)} - ₹${result.economicEstimate.expectedIncomeHigh.toStringAsFixed(0)}',
              ),
              _buildResultRow(
                'Estimated Costs',
                '₹${result.economicEstimate.estimatedCosts.toStringAsFixed(0)}',
              ),
              _buildResultRow(
                'Net Profit',
                '₹${result.economicEstimate.netProfitLow.toStringAsFixed(0)} - ₹${result.economicEstimate.netProfitHigh.toStringAsFixed(0)}',
              ),
              _buildResultRow(
                'ROI',
                '${result.economicEstimate.roiLow.toStringAsFixed(1)}% - ${result.economicEstimate.roiHigh.toStringAsFixed(1)}%',
              ),
            ],
          ),

          // Crop Suitability
          _buildResultCard(
            title: '✓ Crop Suitability',
            children: [
              _buildResultRow('Rating', result.cropSuitability.rating),
              _buildResultRow('Score', '${result.cropSuitability.score}/100'),
              const SizedBox(height: 8),
              ...result.cropSuitability.factors.map(
                (factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(factor, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),

          // Soil Health
          _buildResultCard(
            title: '🧪 Soil Health',
            children: [
              _buildResultRow('Zinc', result.soilHealth.zinc),
              _buildResultRow('Iron', result.soilHealth.iron),
              _buildResultRow('Sulfur', result.soilHealth.sulfur),
            ],
          ),

          // Climate
          _buildResultCard(
            title: '🌡️ Climate',
            children: [
              _buildResultRow(
                'Avg Temperature',
                '${result.climate['tavg']?.toStringAsFixed(1) ?? 'N/A'}°C',
              ),
              _buildResultRow(
                'Min Temperature',
                '${result.climate['tmin']?.toStringAsFixed(1) ?? 'N/A'}°C',
              ),
              _buildResultRow(
                'Max Temperature',
                '${result.climate['tmax']?.toStringAsFixed(1) ?? 'N/A'}°C',
              ),
              _buildResultRow(
                'Annual Rainfall',
                '${result.climate['prcp']?.toStringAsFixed(0) ?? 'N/A'} mm',
              ),
            ],
          ),

          // Irrigation
          _buildResultCard(
            title: '💧 Irrigation Suggestion',
            children: [
              Text(
                result.irrigationSuggestion,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(result.irrigationDetail),
            ],
          ),

          // Fertilizer Recommendations
          if (result.fertilizerRecommendation.isNotEmpty)
            _buildResultCard(
              title: '🌱 Fertilizer Recommendations',
              children: result.fertilizerRecommendation
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $rec'),
                    ),
                  )
                  .toList(),
            ),

          // 10% Profit Recommendation Section
          _buildProfitRecommendationCard(result),

          // High Risk Alerts
          if (result.highRiskAlerts.isNotEmpty)
            _buildResultCard(
              title: '⚠️ High Risk Alerts',
              color: Colors.red.shade50,
              children: result.highRiskAlerts
                  .map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        alert,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                  .toList(),
            ),

          // Medium Risk Alerts
          if (result.mediumRiskAlerts.isNotEmpty)
            _buildResultCard(
              title: '⚡ Medium Risk Alerts',
              color: Colors.orange.shade50,
              children: result.mediumRiskAlerts
                  .map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        alert,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  )
                  .toList(),
            ),

          // Additional Recommendations
          if (result.additionalRecommendations.isNotEmpty)
            _buildResultCard(
              title: '📋 Additional Recommendations',
              children: result.additionalRecommendations
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $rec'),
                    ),
                  )
                  .toList(),
            ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              setState(() {
                _predictionResult = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('New Prediction', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TranslatedText(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D5016),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FutureBuilder<String>(
          future: languageProvider.isOdia
              ? TranslationService.translate(label, targetLanguage: 'or')
              : Future.value(label),
          builder: (context, labelSnapshot) {
            return FutureBuilder<String>(
              future: languageProvider.isOdia
                  ? TranslationService.translate(hint, targetLanguage: 'or')
                  : Future.value(hint),
              builder: (context, hintSnapshot) {
                return TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: labelSnapshot.data ?? label,
                    hintText: hintSnapshot.data ?? hint,
                    prefixIcon: Icon(icon, color: const Color(0xFF2D5016)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D5016),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter ${labelSnapshot.data ?? label}';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FutureBuilder<String>(
          future: languageProvider.isOdia
              ? TranslationService.translate(label, targetLanguage: 'or')
              : Future.value(label),
          builder: (context, snapshot) {
            return DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: snapshot.data ?? label,
                prefixIcon: Icon(icon, color: const Color(0xFF2D5016)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D5016),
                    width: 2,
                  ),
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: languageProvider.isOdia
                      ? FutureBuilder<String>(
                          future: TranslationService.translate(
                            item,
                            targetLanguage: 'or',
                          ),
                          builder: (context, itemSnapshot) {
                            return Text(itemSnapshot.data ?? item);
                          },
                        )
                      : Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            );
          },
        );
      },
    );
  }

  Widget _buildResultCard({
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitRecommendationCard(CropPredictionResponse result) {
    // Calculate 10% profit increase target
    final currentProfit =
        (result.economicEstimate.netProfitLow +
            result.economicEstimate.netProfitHigh) /
        2;
    final targetProfit = currentProfit * 1.10;
    final profitIncrease = targetProfit - currentProfit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '10% Profit Boost Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: +₹${profitIncrease.toStringAsFixed(0)} extra profit',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+10%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Content
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Recommendation',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Impact',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Pest Control Row
                _buildRecommendationTableRow(
                  icon: Icons.bug_report_rounded,
                  category: 'Pest Control',
                  recommendation: _getPestRecommendation(result.crop),
                  impact: '+3%',
                  impactColor: Colors.greenAccent,
                ),

                // Fertilizer Row
                _buildRecommendationTableRow(
                  icon: Icons.science_rounded,
                  category: 'Fertilizer',
                  recommendation: _getFertilizerRecommendation(result),
                  impact: '+4%',
                  impactColor: Colors.greenAccent,
                ),

                // Irrigation Row
                _buildRecommendationTableRow(
                  icon: Icons.water_drop_rounded,
                  category: 'Irrigation',
                  recommendation: _getIrrigationRecommendation(result),
                  impact: '+3%',
                  impactColor: Colors.greenAccent,
                ),
              ],
            ),
          ),

          // Summary Footer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Projected Profit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${currentProfit.toStringAsFixed(0)} → ₹${targetProfit.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTableRow({
    required IconData icon,
    required String category,
    required String recommendation,
    required String impact,
    required Color impactColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                recommendation,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: impactColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                impact,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: impactColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPestRecommendation(String crop) {
    final pestRecommendations = {
      'Rice': 'Neem oil spray + Trichoderma',
      'Wheat': 'Chlorpyrifos dust application',
      'Maize': 'Pheromone traps + Bio-pesticides',
      'Cotton': 'Bt spray + Yellow sticky traps',
      'Sugarcane': 'Trichogramma release + Light traps',
    };
    return pestRecommendations[crop] ?? 'Integrated Pest Management (IPM)';
  }

  String _getFertilizerRecommendation(CropPredictionResponse result) {
    if (result.fertilizerRecommendation.isNotEmpty) {
      return result.fertilizerRecommendation.take(2).join(' + ');
    }
    return 'NPK 10-26-26 + Micronutrients';
  }

  String _getIrrigationRecommendation(CropPredictionResponse result) {
    final irrigationType = result.irrigationSuggestion.toLowerCase();
    if (irrigationType.contains('high') || irrigationType.contains('heavy')) {
      return 'Drip irrigation every 3 days';
    } else if (irrigationType.contains('low') ||
        irrigationType.contains('minimal')) {
      return 'Sprinkler irrigation weekly';
    }
    return 'Drip/Sprinkler every 5 days';
  }
}
