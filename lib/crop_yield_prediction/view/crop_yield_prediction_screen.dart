import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/crop_yield_model.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../services/ml_api_service.dart';
import '../../services/openai_service.dart';
import '../../services/variety_data_service.dart';
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
  final OpenAIService _openAIService = OpenAIService();
  final VarietyDataService _varietyService = VarietyDataService();

  bool _isLoading = false;
  bool _isGeneratingRecommendations = false;
  CropPredictionResponse? _predictionResult;
  Map<String, dynamic>? _dynamicRecommendations; // LLM-generated recommendations
  String _selectedTab = 'Fertilizer'; // Tab state: Fertilizer, Irrigation, Pest

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
  String _selectedVariety = 'IR-64'; // Add variety selection
  String _selectedSeason = 'Kharif';
  int _selectedYear = 2020;

  final List<String> _crops = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane'];
  final Map<String, List<String>> _cropVarieties = {
    'Rice': ['IR-64', 'CR Dhan 215', 'CR Dhan 604', 'Swarna', 'MTU-1010'],
    'Wheat': ['HD-2967', 'PBW-343', 'DBW-17', 'Lok-1'],
    'Maize': ['Kaveri-50', 'DHM-117', 'Vivek QPM-9'],
    'Cotton': ['JK-1947 BT', 'Suraj', 'MECH-162'],
    'Sugarcane': ['CO-86032', 'CO-238', 'CO-419'],
  };
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
      // Prepare farm data in FastAPI format (use alias names with special characters)
      final farmData = {
        'area': double.parse(_areaController.text),
        'tavg_climate': double.parse(_tavgController.text),
        'tmin_climate': double.parse(_tminController.text),
        'tmax_climate': double.parse(_tmaxController.text),
        'prcp_annual_climate': double.parse(_prcpController.text),
        'zn %': double.parse(_znController.text), // Use alias format
        'fe%': double.parse(_feController.text),
        'cu %': double.parse(_cuController.text),
        'mn %': double.parse(_mnController.text),
        'b %': double.parse(_bController.text),
        's %': double.parse(_sController.text),
        'crop': _selectedCrop,
        'season': _selectedSeason,
        'year': _selectedYear,
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
        _isGeneratingRecommendations = true; // Start LLM processing
      });

      // 🚀 GENERATE DYNAMIC RECOMMENDATIONS USING OpenAI + Excel Data
      try {
        print('🤖 Generating dynamic recommendations with LLM...');
        
        // Get variety data from Excel
        final varietyData = await _varietyService.getVarietyData(
          district: 'Jajpur', // TODO: Get from user location or form
          crop: _selectedCrop,
          variety: _selectedVariety,
        );

        // Prepare ML prediction data
        final mlPrediction = {
          'crop': _selectedCrop,
          'yield_forecast': yieldData['per_hectare_tonnes'],
          'confidence_level': result.yieldForecast.confidenceLevel,
          'min_income': economicData['min_income'],
          'max_income': economicData['max_income'],
        };

        // Call OpenAI to generate context-aware recommendations
        final recommendations = await _openAIService.generateDynamicRecommendations(
          mlPrediction: mlPrediction,
          varietyData: varietyData ?? {},
          farmData: farmData,
          selectedVariety: _selectedVariety,
          district: 'Jajpur', // TODO: Get from user location
        );

        setState(() {
          _dynamicRecommendations = recommendations;
          _isGeneratingRecommendations = false;
        });

        print('✅ Dynamic recommendations generated successfully!');
      } catch (llmError) {
        print('⚠️ LLM Error (using fallback): $llmError');
        setState(() {
          _isGeneratingRecommendations = false;
          // Keep static recommendations as fallback
        });
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _isGeneratingRecommendations = false;
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
    final yieldPercentage = (result.yieldForecast.perHectareTonnes / 3.0).clamp(0.0, 1.0); // Assuming 3 tons is max
    final regionalAverage = 1.8;
    final yourYield = result.yieldForecast.perHectareTonnes;
    final aboveAverage = ((yourYield - regionalAverage) / regionalAverage * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===========================
          // SECTION 1: YIELD PREDICTION SUMMARY
          // ===========================
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.agriculture, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const TranslatedText(
                  '🌾 CROP YIELD PREDICTION',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Crop and Variety
                _buildInfoRow('Your Crop:', '${result.crop} ($_selectedVariety)', Icons.grass),
                _buildInfoRow('Land Area:', '${result.farmAreaAcres.toStringAsFixed(1)} Acres', Icons.landscape),
                _buildInfoRow('Expected Harvest:', '${_getHarvestMonth()}', Icons.calendar_today),
                
                const SizedBox(height: 24),
                
                // Expected Yield Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const TranslatedText(
                        'Expected Yield',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: yieldPercentage,
                          minHeight: 20,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            yieldPercentage > 0.7 ? Colors.green : yieldPercentage > 0.5 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(yieldPercentage * 100).toInt()}%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Total Yield
                      Text(
                        '🌾 ${result.yieldForecast.totalExpectedTonnes.toStringAsFixed(1)} Tons',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(${result.yieldForecast.perHectareTonnes.toStringAsFixed(1)} Tons per Acre)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Comparison
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const TranslatedText(
                            '📊 Regional Average: ',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            '$regionalAverage Tons/Acre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (aboveAverage > 0)
                        Text(
                          '✅ You\'re $aboveAverage% Above Average!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                          ),
                        )
                      else
                        Text(
                          '⚠️ ${aboveAverage.abs()}% Below Average',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Confidence Level
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const TranslatedText(
                      'Confidence Level: ',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    ...List.generate(5, (index) {
                      final filled = index < (result.yieldForecast.confidenceLevel / 20).floor();
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: Colors.yellowAccent,
                        size: 24,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '(${result.yieldForecast.confidenceLevel >= 80 ? 'High' : result.yieldForecast.confidenceLevel >= 60 ? 'Medium' : 'Low'})',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===========================
          // SECTION 2: FACTORS AFFECTING YIELD
          // ===========================
          _buildFactorsCard(result),

          const SizedBox(height: 24),

          // ===========================
          // SECTION 3: SMART RECOMMENDATIONS (TABS)
          // ===========================
          const TranslatedText(
            '📋 SMART RECOMMENDATIONS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Three-Tab Category Bar
          Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  label: '🌱\nFertilizer',
                  isSelected: _selectedTab == 'Fertilizer',
                  onTap: () => setState(() => _selectedTab = 'Fertilizer'),
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabButton(
                  label: '💧\nIrrigation',
                  isSelected: _selectedTab == 'Irrigation',
                  onTap: () => setState(() => _selectedTab = 'Irrigation'),
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabButton(
                  label: '🦟\nPest\nControl',
                  isSelected: _selectedTab == 'Pest',
                  onTap: () => setState(() => _selectedTab = 'Pest'),
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Display selected tab content
          if (_selectedTab == 'Fertilizer')
            _buildFertilizerSection(result)
          else if (_selectedTab == 'Irrigation')
            _buildIrrigationSection(result)
          else if (_selectedTab == 'Pest')
            _buildPestControlSection(result),

          const SizedBox(height: 24),

          // New Prediction Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _predictionResult = null;
                _selectedTab = 'Fertilizer';
              });
            },
            icon: const Icon(Icons.refresh, size: 28),
            label: const TranslatedText('NEW PREDICTION', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TranslatedText(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          Text(
            value, // Value is often dynamic/numeric
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getHarvestMonth() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final currentMonth = DateTime.now().month;
    final harvestMonth = (currentMonth + 3) % 12; // Assuming 3 months growing season
    return '${months[harvestMonth]} ${DateTime.now().year}';
  }

  Widget _buildFactorsCard(CropPredictionResponse result) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            '📈 WHAT\'S HELPING YOUR YIELD',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFactorItem('Good Soil Health (NPK Balanced)', true),
          _buildFactorItem('Favorable Weather Conditions', true),
          _buildFactorItem('Adequate Water Availability', true),
          _buildFactorItem('Optimal Planting Time', true),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          
          const TranslatedText(
            '⚠️ WATCH OUT FOR',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          
          ...result.mediumRiskAlerts.map((alert) => _buildFactorItem(alert, false)).toList(),
          if (result.mediumRiskAlerts.isEmpty) ...[
            _buildFactorItem('Pest Risk: Medium (Monitor closely)', false),
            _buildFactorItem('Disease Risk: Low', false),
          ],
        ],
      ),
    );
  }

  Widget _buildFactorItem(String text, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.check_circle : Icons.warning,
            color: isPositive ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TranslatedText(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
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
          future: TranslationService.translate(
            label,
            targetLanguage: languageProvider.currentLanguage.code,
          ),
          builder: (context, labelSnapshot) {
            return FutureBuilder<String>(
              future: TranslationService.translate(
                hint,
                targetLanguage: languageProvider.currentLanguage.code,
              ),
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
          future: TranslationService.translate(
            label,
            targetLanguage: languageProvider.currentLanguage.code,
          ),
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
                  child: FutureBuilder<String>(
                    future: TranslationService.translate(
                      item,
                      targetLanguage: languageProvider.currentLanguage.code,
                    ),
                    builder: (context, itemSnapshot) {
                      return Text(itemSnapshot.data ?? item);
                    },
                  ),
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
                      const TranslatedText(
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
                        child: TranslatedText(
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
                        child: TranslatedText(
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
                        child: TranslatedText(
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
                    TranslatedText(
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

  // ===========================
  // TAB BUTTON BUILDER
  // ===========================
  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Center(
          child: TranslatedText(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // FERTILIZER SECTION
  // ===========================
  Widget _buildFertilizerSection(CropPredictionResponse result) {
    // 🚀 Check if we have dynamic recommendations from LLM
    if (_isGeneratingRecommendations) {
      return _buildLoadingRecommendations('Generating personalized fertilizer schedule...');
    }

    final fertilizerStages = _dynamicRecommendations?['fertilizer_stages'] as List?;
    
    // Use LLM data if available, otherwise fall back to static data
    if (fertilizerStages != null && fertilizerStages.isNotEmpty) {
      return _buildDynamicFertilizerSection(fertilizerStages);
    }
    
    // Fallback to static data
    return _buildStaticFertilizerSection(result);
  }

  Widget _buildLoadingRecommendations(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text(
            '🤖 AI is analyzing your farm data, weather, soil conditions, and variety to create the best recommendations...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFertilizerSection(List fertilizerStages) {
    // Calculate total cost from LLM data
    double totalCost = 0;
    for (final stage in fertilizerStages) {
      final products = stage['products'] as List? ?? [];
      for (final product in products) {
        final priceStr = product['price']?.toString().replaceAll(RegExp(r'[₹,]'), '') ?? '0';
        totalCost += double.tryParse(priceStr) ?? 0;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grass, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌱 AI-GENERATED SCHEDULE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      'Personalized for your farm',
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Weather Advisory from LLM
          if (_dynamicRecommendations?['weather_advisory'] != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dynamicRecommendations!['weather_advisory'],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          
          // Total Cost Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost Estimate:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹${totalCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Dynamic Timeline
          _buildTimeline(),
          
          const SizedBox(height: 24),
          
          // Dynamic Fertilizer Stages from LLM
          ...fertilizerStages.map((stage) {
            return Column(
              children: [
                _buildDynamicFertilizerStage(stage),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
          
          // Variety-Specific Tips from LLM
          if (_dynamicRecommendations?['variety_specific_tips'] != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Tips for $_selectedVariety Variety',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_dynamicRecommendations!['variety_specific_tips'] as List).map((tip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Set Reminders Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📅 Reminders feature coming soon!')),
                );
              },
              icon: const Icon(Icons.notifications_active, size: 28),
              label: const TranslatedText('SET REMINDERS 🔔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFertilizerStage(Map<String, dynamic> stage) {
    final isHighPriority = stage['importance'] == 'HIGH';
    final day = stage['day'];
    final stageName = stage['stage'];
    final products = stage['products'] as List? ?? [];
    final tips = stage['tips'] as List? ?? [];
    final applicationDate = stage['application_date'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHighPriority
              ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
              : [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighPriority ? const Color(0xFF2E7D32) : Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isHighPriority ? const Color(0xFF2E7D32) : Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Day $day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stageName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (applicationDate.isNotEmpty)
                      Text(
                        applicationDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (isHighPriority)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'HIGH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Products
          if (products.isNotEmpty) ...[
            const Text(
              '📦 Products:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...products.map((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${product['name']} - ${product['qty']}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      product['price'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],
          
          // Tips
          if (tips.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            ...tips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStaticFertilizerSection(CropPredictionResponse result) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grass, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '🌱 FERTILIZER SCHEDULE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Total Cost Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost Estimate:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹4,500',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Visual Timeline
          _buildTimeline(),
          const SizedBox(height: 24),
          
          // Basal Dose (Day 0)
          _buildFertilizerStage(
            day: 'Day 0',
            stage: 'BASAL (Before Planting)',
            icon: Icons.agriculture,
            products: [
              {'name': 'DAP', 'qty': '50 kg', 'price': '₹1,400', 'brand': 'IFFCO'},
              {'name': 'Potash', 'qty': '25 kg', 'price': '₹750', 'brand': 'IFFCO'},
            ],
            tips: ['📍 Apply evenly before flooding', '⏰ Best Time: Morning'],
            importance: 'HIGH',
          ),
          
          const SizedBox(height: 16),
          
          // First Top Dressing (Day 21)
          _buildFertilizerStage(
            day: 'Day 21',
            stage: 'FIRST TOP DRESSING',
            icon: Icons.eco,
            products: [
              {'name': 'Urea', 'qty': '30 kg/acre', 'price': '₹600', 'brand': 'IFFCO'},
            ],
            tips: ['⏰ Best Time: 6-8 AM', '⚠️ Don\'t apply if heavy rain', '💧 Maintain 2-3 inch water'],
            importance: 'HIGH',
          ),
          
          const SizedBox(height: 16),
          
          // Second Top Dressing (Day 45)
          _buildFertilizerStage(
            day: 'Day 45',
            stage: 'SECOND TOP DRESSING',
            icon: Icons.spa,
            products: [
              {'name': 'Urea', 'qty': '30 kg/acre', 'price': '₹600', 'brand': 'IFFCO'},
              {'name': 'Potash', 'qty': '15 kg/acre', 'price': '₹450', 'brand': 'Coromandel'},
            ],
            tips: ['⏰ Best Time: Morning', '🌾 During active tillering'],
            importance: 'MEDIUM',
          ),
          
          const SizedBox(height: 16),
          
          // Third Top Dressing (Day 65)
          _buildFertilizerStage(
            day: 'Day 65',
            stage: 'THIRD TOP DRESSING',
            icon: Icons.energy_savings_leaf,
            products: [
              {'name': 'Urea', 'qty': '20 kg/acre', 'price': '₹400', 'brand': 'IFFCO'},
            ],
            tips: ['🌸 During panicle initiation', '💡 This boosts grain filling'],
            importance: 'MEDIUM',
          ),
          
          const SizedBox(height: 24),
          
          // Set Reminders Button
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement reminder functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminders will be set for all fertilizer applications!')),
              );
            },
            icon: const Icon(Icons.notifications_active, size: 24),
            label: const Text('SET REMINDERS 🔔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'FERTILIZER APPLICATION TIMELINE',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimelinePoint('Day 0', '🌱\nPlanting', true),
              _buildTimelineLine(),
              _buildTimelinePoint('Day 21', '💊\n1st Top', true),
              _buildTimelineLine(),
              _buildTimelinePoint('Day 45', '💊\n2nd Top', false),
              _buildTimelineLine(),
              _buildTimelinePoint('Day 65', '💊\n3rd Top', false),
              _buildTimelineLine(),
              _buildTimelinePoint('Day 120', '🌾\nHarvest', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePoint(String day, String label, bool isImportant) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isImportant ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isImportant
                ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8)]
                : [],
          ),
          child: Center(
            child: Text(
              label.split('\n')[0],
              style: TextStyle(
                fontSize: 20,
                color: isImportant ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.split('\n')[1],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isImportant ? const Color(0xFF2E7D32) : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade300, Colors.green.shade100],
          ),
        ),
      ),
    );
  }

  Widget _buildFertilizerStage({
    required String day,
    required String stage,
    required IconData icon,
    required List<Map<String, String>> products,
    required List<String> tips,
    required String importance,
  }) {
    final isHighPriority = importance == 'HIGH';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHighPriority
              ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
              : [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighPriority ? const Color(0xFF2E7D32) : Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isHighPriority ? const Color(0xFF2E7D32) : Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: isHighPriority ? const Color(0xFF2E7D32) : Colors.blue.shade700, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHighPriority ? const Color(0xFF2E7D32) : Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Products
          ...products.map((product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product['brand']} ${product['name']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product['qty']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Text(
                  product['price']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          
          // Tips
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // ===========================
  // IRRIGATION SECTION - DYNAMIC
  // ===========================
  Widget _buildDynamicIrrigationSection(List irrigationStages) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💧 AI-GENERATED IRRIGATION',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      Text(
                        'Weather-adjusted plan',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Dynamic Irrigation Stages from LLM
            ...irrigationStages.map((stage) {
              final isCritical = stage['critical'] == true;
              final stageName = stage['stage'] ?? '';
              final waterLevel = stage['waterLevel'] ?? '';
              final frequency = stage['frequency'] ?? '';
              final products = stage['products'] as List? ?? [];
              final tips = stage['tips'] as List? ?? [];
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCritical ? Colors.orange.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCritical ? Colors.orange.shade300 : Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isCritical)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CRITICAL',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (isCritical) const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stageName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.water, size: 18, color: Colors.blue),
                                  const SizedBox(width: 6),
                                  Text(waterLevel, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule, size: 18, color: Colors.blue),
                                  const SizedBox(width: 6),
                                  Text(frequency, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (products.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('💧 Recommended Equipment:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...products.map((product) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(product['name'] ?? '', style: const TextStyle(fontSize: 13))),
                                Text(product['price'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                          )).toList(),
                        ],
                        
                        if (tips.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...tips.map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 ', style: TextStyle(fontSize: 14)),
                                Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                              ],
                            ),
                          )).toList(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
            
            // Weather Saving Tips
            if (_dynamicRecommendations?['weather_advisory'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.wb_sunny, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Weather-Based Tips:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dynamicRecommendations!['weather_advisory'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // PEST CONTROL SECTION - DYNAMIC
  // ===========================
  Widget _buildDynamicPestControlSection(List pestControl) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bug_report, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🦟 AI PEST MANAGEMENT',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        'Proactive protection plan',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Dynamic Pest Control Stages from LLM
            ...pestControl.map((pest) {
              final pestName = pest['pest'] ?? '';
              final riskLevel = pest['risk_level'] ?? 'MEDIUM';
              final timing = pest['timing'] ?? '';
              final preventive = pest['preventive'] as List? ?? [];
              final treatment = pest['treatment'] as List? ?? [];
              final monitoring = pest['monitoring'] ?? '';
              
              final Color riskColor = riskLevel == 'HIGH' 
                  ? Colors.red 
                  : riskLevel == 'LOW' 
                      ? Colors.green 
                      : Colors.orange;
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: riskLevel == 'HIGH' ? Colors.red.shade50 : riskLevel == 'LOW' ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskLevel == 'HIGH' ? Colors.red.shade300 : riskLevel == 'LOW' ? Colors.green.shade300 : Colors.orange.shade300, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: riskColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                riskLevel,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pestName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    timing,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (preventive.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('🛡️ Preventive Measures:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...preventive.map((measure) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(measure, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          )).toList(),
                        ],
                        
                        if (treatment.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('💊 Treatment Options:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...treatment.map((prod) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  prod['type'] == 'Organic' ? Icons.eco : Icons.science,
                                  color: prod['type'] == 'Organic' ? Colors.green : Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${prod['name']} - ${prod['dosage']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  prod['price'] ?? '',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                        
                        if (monitoring.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility, size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    monitoring,
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
            
            // Organic Alternatives Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('🌿 Prefer Organic Methods First', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Always try organic/biological controls before using chemical pesticides. Better for soil health and environment!',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // IRRIGATION SECTION
  // ===========================
  Widget _buildIrrigationSection(CropPredictionResponse result) {
    // 🚀 Check if we have dynamic recommendations from LLM
    if (_isGeneratingRecommendations) {
      return _buildLoadingRecommendations('Generating smart irrigation schedule...');
    }

    final irrigationStages = _dynamicRecommendations?['irrigation_stages'] as List?;
    
    // Use LLM data if available, otherwise fall back to static data
    if (irrigationStages != null && irrigationStages.isNotEmpty) {
      return _buildDynamicIrrigationSection(irrigationStages);
    }
    
    // Fallback to static data
    return _buildStaticIrrigationSection(result);
  }

  Widget _buildStaticIrrigationSection(CropPredictionResponse result) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\ud83d\udca7 Growth-Stage Irrigation Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            
            // Seedling Stage
            _buildIrrigationStage(
              stage: 'Seedling Stage (Day 1-20)',
              waterLevel: '2-3 inches',
              frequency: 'Every 3-4 days',
              critical: true,
              products: [
                {'name': 'Jain Drip Kit (1 acre)', 'price': '\u20b928,000'},
                {'name': 'Kirloskar 1HP Pump', 'price': '\u20b912,000'},
              ],
              tips: ['Keep soil moist', 'Avoid waterlogging'],
            ),
            
            const SizedBox(height: 16),
            
            // Tillering Stage
            _buildIrrigationStage(
              stage: 'Tillering Stage (Day 21-45)',
              waterLevel: '2 inches',
              frequency: 'Every 5-7 days',
              critical: false,
              products: [
                {'name': 'Premier Sprinkler Set', 'price': '\u20b918,000'},
              ],
              tips: ['Maintain consistent moisture', 'Reduce frequency in rainfall'],
            ),
            
            const SizedBox(height: 16),
            
            // Flowering Stage
            _buildIrrigationStage(
              stage: 'Flowering Stage (Day 60-80)',
              waterLevel: '3-4 inches',
              frequency: 'Every 4-5 days',
              critical: true,
              products: [
                {'name': 'Netafim Drip System', 'price': '\u20b932,000'},
              ],
              tips: ['CRITICAL PERIOD', 'Don\'t let it dry'],
            ),
            
            const SizedBox(height: 16),
            
            // Grain Filling Stage
            _buildIrrigationStage(
              stage: 'Grain Filling (Day 80-100)',
              waterLevel: '2 inches',
              frequency: 'Every 5-6 days',
              critical: false,
              products: [
                {'name': 'CRI Pump 2HP', 'price': '\u20b916,000'},
              ],
              tips: ['Reduce gradually', 'Monitor moisture levels'],
            ),
            
            const SizedBox(height: 16),
            
            // Maturity Stage
            _buildIrrigationStage(
              stage: 'Maturity (Day 100-120)',
              waterLevel: 'Reduce gradually',
              frequency: 'As needed',
              critical: false,
              products: [],
              tips: ['Drain field before harvest', 'Stop 10 days before harvest'],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            
            // Water Saving Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\ud83d\udca1 Water-Saving Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('\u2022 Use drip irrigation for 40% water savings'),
                  Text('\u2022 Irrigate early morning or evening'),
                  Text('\u2022 Check soil moisture before watering'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIrrigationStage({
    required String stage,
    required String waterLevel,
    required String frequency,
    required bool critical,
    required List<Map<String, String>> products,
    required List<String> tips,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: critical ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: critical ? Colors.orange.shade300 : Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                critical ? Icons.warning_rounded : Icons.water_drop,
                color: critical ? Colors.orange : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stage,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Water Level:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(waterLevel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Frequency:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(frequency, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          
          // Products
          if (products.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Recommended Products:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.blue, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(product['name']!, style: const TextStyle(fontSize: 13)),
                  ),
                  Text(product['price']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
          ],
          
          // Tips
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u2022 ',
                  style: TextStyle(color: critical ? Colors.orange : Colors.blue, fontSize: 16),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: critical ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // ===========================
  // PEST CONTROL SECTION
  // ===========================
  Widget _buildPestControlSection(CropPredictionResponse result) {
    // 🚀 Check if we have dynamic recommendations from LLM
    if (_isGeneratingRecommendations) {
      return _buildLoadingRecommendations('Generating pest control strategies...');
    }

    final pestControl = _dynamicRecommendations?['pest_control'] as List?;
    
    // Use LLM data if available, otherwise fall back to static data
    if (pestControl != null && pestControl.isNotEmpty) {
      return _buildDynamicPestControlSection(pestControl);
    }
    
    // Fallback to static data
    return _buildStaticPestControlSection(result);
  }

  Widget _buildStaticPestControlSection(CropPredictionResponse result) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\ud83e\udd9f Pest Management Timeline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 16),
            
            // Week 1-2: Preventive Setup
            _buildPestControlStage(
              week: 'Week 1-2',
              stage: 'Preventive Setup',
              products: [
                {'name': 'Pheromone Traps (10 pcs)', 'price': '\u20b9600'},
                {'name': 'Light Trap Solar', 'price': '\u20b93,200'},
                {'name': 'Yellow Sticky Traps (30 pcs)', 'price': '\u20b9450'},
              ],
              tips: ['Install before pests appear', 'Place at field boundaries'],
            ),
            
            const SizedBox(height: 16),
            
            // Week 3 (Day 21): Organic Spray
            _buildPestControlStage(
              week: 'Week 3 (Day 21)',
              stage: 'Organic Protection',
              products: [
                {'name': 'IFFCO Neem Gold 5L', 'price': '\u20b92,200'},
                {'name': 'Biostadt Trichoguard 5kg', 'price': '\u20b91,750'},
              ],
              tips: ['Spray in evening', 'Mix 5ml neem oil per liter'],
            ),
            
            const SizedBox(height: 16),
            
            // Week 5 (Day 35): Chemical if needed
            _buildPestControlStage(
              week: 'Week 5 (Day 35)',
              stage: 'Chemical Control (If Needed)',
              products: [
                {'name': 'Bayer Confidor 100ml', 'price': '\u20b9850'},
                {'name': 'UPL Saaf 100gm', 'price': '\u20b9420'},
              ],
              tips: ['Use only if organic fails', 'Follow label instructions'],
            ),
            
            const SizedBox(height: 16),
            
            // Week 7+ (Day 50+): Monitoring
            _buildPestControlStage(
              week: 'Week 7+',
              stage: 'Continuous Monitoring',
              products: [
                {'name': 'Bio Neem Cake 50kg', 'price': '\u20b92,400'},
              ],
              tips: ['Check traps daily', 'Spray only when needed'],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            
            // Organic Alternatives
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\ud83c\udf3f Best Organic Alternatives:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('\u2022 Neem oil spray (5ml/liter) - Safe & effective'),
                  Text('\u2022 Trichoderma soil application - Prevents fungal diseases'),
                  Text('\u2022 Bird perches - Natural pest control'),
                  Text('\u2022 Rotate crops annually - Breaks pest cycle'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPestControlStage({
    required String week,
    required String stage,
    required List<Map<String, String>> products,
    required List<String> tips,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(week, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stage,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Products
          const Text('Products:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...products.map((product) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product['name']!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  product['price']!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          )).toList(),
          
          // Tips
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('\u2022 ', style: TextStyle(color: Colors.orange, fontSize: 16)),
                Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
