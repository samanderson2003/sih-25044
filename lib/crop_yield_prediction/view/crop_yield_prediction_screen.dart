import 'package:flutter/material.dart';
import '../controller/crop_yield_controller.dart';
import '../model/crop_yield_model.dart';

class CropYieldPredictionScreen extends StatefulWidget {
  const CropYieldPredictionScreen({super.key});

  @override
  State<CropYieldPredictionScreen> createState() =>
      _CropYieldPredictionScreenState();
}

class _CropYieldPredictionScreenState extends State<CropYieldPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final CropYieldController _controller = CropYieldController();

  bool _isLoading = false;
  CropPredictionResponse? _predictionResult;

  // Form controllers with default values
  final TextEditingController _areaController = TextEditingController(
    text: '2.0',
  );
  final TextEditingController _tavgController = TextEditingController(
    text: '28.0',
  );
  final TextEditingController _tminController = TextEditingController(
    text: '24.0',
  );
  final TextEditingController _tmaxController = TextEditingController(
    text: '33.0',
  );
  final TextEditingController _prcpController = TextEditingController(
    text: '5.5',
  );
  final TextEditingController _znController = TextEditingController(
    text: '80.0',
  );
  final TextEditingController _feController = TextEditingController(
    text: '94.0',
  );
  final TextEditingController _cuController = TextEditingController(
    text: '90.0',
  );
  final TextEditingController _mnController = TextEditingController(
    text: '97.0',
  );
  final TextEditingController _bController = TextEditingController(
    text: '98.0',
  );
  final TextEditingController _sController = TextEditingController(text: '0.7');

  String _selectedCrop = 'Rice';
  String _selectedSeason = 'Kharif';
  int _selectedYear = 2020;

  final List<String> _crops = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane'];
  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];

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

  Future<void> _testConnection() async {
    try {
      final health = await _controller.checkApiHealth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ API Connected! Status: ${health['status']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connection Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
      final input = CropPredictionInput(
        area: double.parse(_areaController.text),
        tavgClimate: double.parse(_tavgController.text),
        tminClimate: double.parse(_tminController.text),
        tmaxClimate: double.parse(_tmaxController.text),
        prcpAnnualClimate: double.parse(_prcpController.text),
        znPercent: double.parse(_znController.text),
        fePercent: double.parse(_feController.text),
        cuPercent: double.parse(_cuController.text),
        mnPercent: double.parse(_mnController.text),
        bPercent: double.parse(_bController.text),
        sPercent: double.parse(_sController.text),
        crop: _selectedCrop,
        season: _selectedSeason,
        year: _selectedYear,
      );

      final result = await _controller.predictCropYield(input);

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
      floatingActionButton: _predictionResult == null
          ? FloatingActionButton.extended(
              onPressed: _testConnection,
              backgroundColor: const Color(0xFF2D5016),
              icon: const Icon(Icons.wifi, color: Colors.white),
              label: const Text(
                'Test API',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Default values are pre-filled for testing. Tap the WiFi icon to test API connection.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  : const Text(
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
                '${result.climate['temperature_avg']}°C',
              ),
              _buildResultRow(
                'Min Temperature',
                '${result.climate['temperature_min']}°C',
              ),
              _buildResultRow(
                'Max Temperature',
                '${result.climate['temperature_max']}°C',
              ),
              _buildResultRow(
                'Annual Rainfall',
                '${result.climate['annual_rainfall_mm'].toStringAsFixed(0)} mm',
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
      child: Text(
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
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2D5016)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2D5016)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
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
}
