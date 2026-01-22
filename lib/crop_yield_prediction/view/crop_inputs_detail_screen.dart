import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/india_crop_service.dart';

class CropInputsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;
  final String cropName;

  const CropInputsDetailScreen({
    super.key,
    required this.farmData,
    required this.cropName,
  });

  @override
  State<CropInputsDetailScreen> createState() =>
      _CropInputsDetailScreenState();
}

class _CropInputsDetailScreenState extends State<CropInputsDetailScreen> {
  Map<String, dynamic>? _inputs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInputs();
  }

  Future<void> _loadInputs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inputs = await IndiaCropService.getIndianInputsForCrop(
        cropName: widget.cropName,
        soilType: widget.farmData['soilType'] ?? 'Loam',
        soilPh: widget.farmData['ph'] ?? 6.5,
        currentYield: widget.farmData['currentYield'] ?? 4.5,
      );

      if (mounted) {
        setState(() {
          _inputs = inputs;
          _isLoading = false;
          if (inputs == null) {
            _error = 'Could not fetch inputs for this crop.';
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
        title: Text('🌾 ${widget.cropName} - Inputs & Management'),
        elevation: 0,
        backgroundColor: const Color(0xFF2D5016),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _inputs != null
                  ? _buildInputsView()
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
            'Fetching Indian fertilizers & pesticides...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Text(
            'Searching approved products database',
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
            onPressed: _loadInputs,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Text('No inputs available'),
    );
  }

  Widget _buildInputsView() {
    final fertilizers =
        _inputs?['recommended_fertilizers'] as Map<String, dynamic>? ?? {};
    final pesticides =
        _inputs?['pesticides'] as Map<String, dynamic>? ?? {};
    final yieldImprovements =
        _inputs?['expected_yield_improvement'] as Map<String, dynamic>? ?? {};
    final schemes =
        _inputs?['government_schemes_and_subsidies'] as Map<String, dynamic>? ??
            {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5016), Color(0xFF4a7c2c)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cropName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '✓ Officially available in India\n✓ Government approved products\n✓ Recommended for your farm',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Yield improvements
          if (yieldImprovements.isNotEmpty) ...[
            _buildSectionHeader('📈 Expected Improvements'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: yieldImprovements.entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text('${e.value}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Fertilizers section
          if (fertilizers.isNotEmpty) ...[
            _buildSectionHeader('🌿 Recommended Fertilizers'),
            const SizedBox(height: 12),
            _buildFertilizerSection(fertilizers),
            const SizedBox(height: 20),
          ],

          // Pesticides section
          if (pesticides.isNotEmpty) ...[
            _buildSectionHeader('🐛 Pest & Disease Management'),
            const SizedBox(height: 12),
            _buildPesticidesSection(pesticides),
            const SizedBox(height: 20),
          ],

          // Government schemes
          if (schemes.isNotEmpty) ...[
            _buildSectionHeader('🏛️ Government Support'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: schemes.entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${e.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Crop Selection'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFertilizerSection(Map<String, dynamic> fertilizers) {
    final standardProducts =
        (fertilizers['standard_products'] as List?) ?? [];
    final organicProducts = (fertilizers['organic_alternatives'] as List?) ?? [];
    final micronutrients =
        (fertilizers['micronutrient_boosters'] as List?) ?? [];

    return Column(
      children: [
        if (standardProducts.isNotEmpty) ...[
          _buildProductCategory('Standard Fertilizers', standardProducts),
          const SizedBox(height: 12),
        ],
        if (organicProducts.isNotEmpty) ...[
          _buildProductCategory('Organic Alternatives', organicProducts),
          const SizedBox(height: 12),
        ],
        if (micronutrients.isNotEmpty) ...[
          _buildProductCategory('Micronutrient Boosters', micronutrients),
        ],
      ],
    );
  }

  Widget _buildProductCategory(String title, List<dynamic> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...products.map((product) {
          final prod = product as Map<String, dynamic>;
          final productName = prod['product_name'] ?? 'Unknown';
          final composition = prod['composition'] ?? '';
          final dose = prod['dose_per_hectare'] ?? prod['dose'] ?? '';
          final cost = prod['cost_approx'] ?? prod['cost'] ?? '';
          final yield = prod['yield_increase_potential'] ?? '';
          final approved = prod['approved_by'] ?? '';
          final isOrganic = prod['certified_organic'] ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isOrganic)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Organic',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (composition.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Composition: $composition',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (dose.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Dose: $dose',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (cost.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Cost: $cost',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (yield.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Expected Improvement: $yield',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  if (approved.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('✓ $approved',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.green)),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPesticidesSection(Map<String, dynamic> pesticides) {
    final insecticides = (pesticides['insecticides'] as List?) ?? [];
    final fungicides = (pesticides['fungicides'] as List?) ?? [];
    final bioagents = (pesticides['organic_bioagents'] as List?) ?? [];

    return Column(
      children: [
        if (insecticides.isNotEmpty) ...[
          _buildPestCategory('🐛 Insecticides', insecticides),
          const SizedBox(height: 12),
        ],
        if (fungicides.isNotEmpty) ...[
          _buildPestCategory('🍂 Fungicides', fungicides),
          const SizedBox(height: 12),
        ],
        if (bioagents.isNotEmpty) ...[
          _buildPestCategory('🌿 Bio-Agents & Organic', bioagents),
        ],
      ],
    );
  }

  Widget _buildPestCategory(String title, List<dynamic> pests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...pests.map((pest) {
          final p = pest as Map<String, dynamic>;
          final pestName = p['pest_name'] ?? p['pest_type'] ?? 'Unknown';
          final productName = p['product_name'] ?? '';
          final tradeNames = p['trade_names'] as List? ?? [];
          final dose = p['dose'] ?? '';
          final frequency = p['application_frequency'] ?? '';
          final cost = p['cost_approx'] ?? p['cost'] ?? '';
          final registered = p['registered_with'] ?? '';
          final organic = p['organic_alternative'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pestName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (productName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Product: $productName',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (tradeNames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          'Trade Names: ${tradeNames.join(", ")}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (dose.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Dose: $dose',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (frequency.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Frequency: $frequency',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (cost.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('Cost: $cost',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (registered.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('✓ Registered: $registered',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.green)),
                    ),
                  if (organic.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🌱 Organic: $organic',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
