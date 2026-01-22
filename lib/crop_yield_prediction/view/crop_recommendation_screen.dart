import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../services/ml_api_service.dart';

class CropRecommendationScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;

  const CropRecommendationScreen({
    super.key,
    required this.farmData,
  });

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  Map<String, dynamic>? _recommendations;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final soilNutrients = {
        'zinc': widget.farmData['zinc'] ?? 0.8,
        'iron': widget.farmData['iron'] ?? 0.9,
        'copper': widget.farmData['copper'] ?? 0.6,
        'manganese': widget.farmData['manganese'] ?? 0.85,
        'boron': widget.farmData['boron'] ?? 0.5,
      };

      final recommendations =
          await MLApiService.getComprehensiveRecommendations(
        district: widget.farmData['district'] ?? 'Region',
        soilType: widget.farmData['soilType'] ?? 'Loam',
        soilPh: widget.farmData['ph'] ?? 6.5,
        rainfallMm: widget.farmData['rainfallMm'] ?? 1200.0,
        currentYield: widget.farmData['currentYield'] ?? 4.5,
        currentCrop: widget.farmData['currentCrop'] ?? 'Rice',
        areaHectares: widget.farmData['areaHectares'] ?? 1.0,
        soilOrganic: widget.farmData['soilOrganic'] ?? 0.5,
        soilNutrients: soilNutrients,
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
          if (recommendations == null) {
            _error = 'Could not generate recommendation. Please try again.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌾 AI Crop Guide: Increase Yield by 10%'),
        elevation: 0,
        backgroundColor: const Color(0xFF2D5016),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _recommendations != null
                  ? _buildRecommendationView()
                  : _buildNoDataState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/loading.json',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 20),
          const Text(
            'Analyzing your farm data...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Text(
            'Using AI to find the best crop',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadRecommendations,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Text('No recommendation available'),
    );
  }

  Widget _buildRecommendationView() {
    final yieldAnalysis =
        _recommendations?['yield_analysis'] as Map<String, dynamic>? ?? {};
    final bestCrops =
        (_recommendations?['best_crop_alternatives'] as List?) ?? [];
    final managementPlan = _recommendations?['recommended_management_plan']
        as Map<String, dynamic>? ??
        {};
    final economicAnalysis =
        _recommendations?['economic_analysis'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yield Analysis
          _buildYieldAnalysisSection(yieldAnalysis),
          const SizedBox(height: 20),

          // Best Crops
          _buildBestCropsSection(bestCrops),
          const SizedBox(height: 20),

          // Management Strategies
          _buildManagementStrategiesCard(managementPlan),
          const SizedBox(height: 20),

          // Economic Analysis
          if (economicAnalysis.isNotEmpty)
            _buildEconomicAnalysisCard(economicAnalysis),
        ],
      ),
    );
  }

  Widget _buildYieldAnalysisSection(Map<String, dynamic> yieldAnalysis) {
    final currentYield =
        (yieldAnalysis['current_yield'] as num?)?.toDouble() ?? 0.0;
    final targetYield =
        (yieldAnalysis['target_yield_10pct'] as num?)?.toDouble() ?? 0.0;
    final potentialYield =
        (yieldAnalysis['potential_yield'] as num?)?.toDouble() ?? 0.0;
    final improvement = targetYield > 0
        ? (((targetYield - currentYield) / currentYield) * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Yield Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildYieldCard('Current', currentYield.toStringAsFixed(1),
                  Colors.blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildYieldCard(
                  'Target (+10%)', targetYield.toStringAsFixed(1), Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildYieldCard('Potential', potentialYield.toStringAsFixed(1),
                  Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            border: Border.all(color: Colors.amber),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Potential improvement: $improvement%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYieldCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('tons/ha',
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBestCropsSection(List<dynamic> bestCrops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🌾 Best Crop Alternatives',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...bestCrops.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final crop = entry.value as Map<String, dynamic>;
          final cropName = crop['crop_name'] ?? 'Unknown';
          final suitability = crop['suitability_score'] ?? 0;
          final yieldExp = crop['expected_yield'] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cropName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '⭐ $suitability/10',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Expected Yield: $yieldExp tons/ha'),
                  if (crop['profitability'] != null)
                    Text('Profitability: ${crop['profitability']}'),
                  if (crop['success_probability'] != null)
                    Text('Success Rate: ${crop['success_probability']}%'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildManagementStrategiesCard(Map<String, dynamic> managementPlan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🌱 Management Strategies',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildStrategyContent(managementPlan),
      ],
    );
  }

  Widget _buildStrategyContent(Map<String, dynamic> managementPlan) {
    final strategies = [
      ('Fertilizer', managementPlan['fertilizer_strategy'] as Map<String, dynamic>? ?? {}),
      ('Irrigation', managementPlan['irrigation_strategy'] as Map<String, dynamic>? ?? {}),
      ('Pest Control', managementPlan['pest_control_strategy'] as Map<String, dynamic>? ?? {}),
    ];

    return Column(
      children: strategies
          .where((s) => (s.$2).isNotEmpty)
          .expand((s) => _buildStrategyOption(s.$1, s.$2))
          .toList(),
    );
  }

  List<Widget> _buildStrategyOption(String title, Map<String, dynamic> strategy) {
    final standardOption =
        strategy['standard_option'] as Map<String, dynamic>? ?? {};
    final organicOption = strategy['organic_option'] as Map<String, dynamic>? ?? {};

    return [
      const SizedBox(height: 12),
      Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          border: Border.all(color: Colors.amber),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✓ Standard Option',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const SizedBox(height: 8),
            ...standardOption.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${e.key}: ${e.value}'),
            )),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌱 Organic Option',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            ...organicOption.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${e.key}: ${e.value}'),
            )),
          ],
        ),
      ),
    ];
  }

  Widget _buildEconomicAnalysisCard(Map<String, dynamic> economicAnalysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        border: Border.all(color: Colors.purple),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Economic Analysis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...economicAnalysis.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key),
                Text(
                  '${e.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
