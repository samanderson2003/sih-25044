import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/india_crop_service.dart';
import 'crop_inputs_detail_screen.dart';

class IndianCropSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;

  const IndianCropSelectionScreen({
    super.key,
    required this.farmData,
  });

  @override
  State<IndianCropSelectionScreen> createState() =>
      _IndianCropSelectionScreenState();
}

class _IndianCropSelectionScreenState extends State<IndianCropSelectionScreen> {
  List<Map<String, dynamic>>? _crops;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIndianCrops();
  }

  Future<void> _loadIndianCrops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final crops = await IndiaCropService.getIndianCrops(
        soilType: widget.farmData['soilType'] ?? 'Loam',
        soilPh: widget.farmData['ph'] ?? 6.5,
        rainfallMm: widget.farmData['rainfallMm'] ?? 1200.0,
        region: 'South India',
      );

      if (mounted) {
        setState(() {
          _crops = crops;
          _isLoading = false;
          if (crops == null || crops.isEmpty) {
            _error = 'Could not fetch crops. Please try again.';
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
        title: const Text('🌾 Select Crop for India'),
        elevation: 0,
        backgroundColor: const Color(0xFF2D5016),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _crops != null && _crops!.isNotEmpty
                  ? _buildCropsList()
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
            'Analyzing farm conditions...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Text(
            'Finding best crops available in India',
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
            onPressed: _loadIndianCrops,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Text('No crops available'),
    );
  }

  Widget _buildCropsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📢 Select a crop to get detailed information about:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '✓ Officially available fertilizers in India\n✓ Approved pesticides and bioagents\n✓ Government subsidies and schemes\n✓ Expected yield improvements',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Top Crops for Your Farm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._crops!.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final crop = entry.value;
            final cropName = crop['crop_name'] ?? 'Unknown';
            final hindiName = crop['hindi_name'] ?? '';
            final suitability = crop['suitability_score'] ?? 0;
            final waterReq = crop['water_requirement'] ?? '';
            final season = crop['growing_season'] ?? '';
            final demand = crop['market_demand'] ?? '';
            final yield = crop['yield_potential'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CropInputsDetailScreen(
                        farmData: widget.farmData,
                        cropName: cropName,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with rank and suitability
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cropName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (hindiName.isNotEmpty)
                                  Text(
                                    hindiName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
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
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '⭐ $suitability/10',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      // Details grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.5,
                        children: [
                          _buildDetailItem('💧 Water', waterReq),
                          _buildDetailItem('⏱️ Season', season),
                          _buildDetailItem('📊 Yield', yield),
                          _buildDetailItem('🏪 Demand', demand),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CropInputsDetailScreen(
                                  farmData: widget.farmData,
                                  cropName: cropName,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'View Fertilizers & Pesticides',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
