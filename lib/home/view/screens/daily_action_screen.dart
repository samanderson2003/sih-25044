import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import '../../controller/home_controller.dart';
import '../../../services/ml_api_service.dart';
import '../../../prior_data/controller/farm_data_controller.dart';

class DailyActionScreen extends StatefulWidget {
  final DateTime date;

  const DailyActionScreen({super.key, required this.date});

  @override
  State<DailyActionScreen> createState() => _DailyActionScreenState();
}

class _DailyActionScreenState extends State<DailyActionScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _planData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if API is available
      final isHealthy = await MLApiService.checkHealth();
      if (!isHealthy) {
        setState(() {
          _error =
              'ML API Server not available. Please start the server:\n\ncd engine/api\npython app.py';
          _isLoading = false;
        });
        return;
      }

      // Get farm data
      final farmDataController = FarmDataController();
      final farmData = await farmDataController.getFarmData();

      if (farmData == null) {
        setState(() {
          _error = 'Please complete your farm profile first';
          _isLoading = false;
        });
        return;
      }

      // Prepare API request data
      final apiData = MLApiService.prepareFarmDataForAPI(
        farmBasics: farmData.farmBasics.toJson(),
        soilQuality: farmData.soilQuality.toJson(),
        climateData: farmData.climateData.toJson(),
        plantingDate: farmData.farmBasics.plantingDate,
      );

      // Get comprehensive plan
      final plan = await MLApiService.getComprehensivePlan(
        farmData: apiData,
        targetDate: DateFormat('yyyy-MM-dd').format(widget.date),
      );

      if (plan == null || !plan['success']) {
        setState(() {
          _error = 'Failed to get recommendations from ML model';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _planData = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF2D5016),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            DateFormat('EEEE, MMM d, y').format(widget.date),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading AI recommendations...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2D5016),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          DateFormat('EEEE, MMM d, y').format(date),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    controller.selectedCrop?.themeColor ??
                        const Color(0xFF3498DB),
                    (controller.selectedCrop?.themeColor ??
                            const Color(0xFF3498DB))
                        .withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Today\'s Weather',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeatherStat(
                        '${dailyAction.weather.temperature.toInt()}°C',
                        'Temperature',
                      ),
                      _buildWeatherStat(
                        '${dailyAction.weather.humidity.toInt()}%',
                        'Humidity',
                      ),
                      _buildWeatherStat(
                        '${dailyAction.weather.rainfallProbability.toInt()}%',
                        'Rain',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.grass, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Crop Stage: ${dailyAction.cropStage}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Warnings Section
            if (dailyAction.warnings.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Color(0xFFE74C3C)),
                    SizedBox(width: 8),
                    Text(
                      'Warnings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                  ],
                ),
              ),
              ...dailyAction.warnings.map(
                (warning) => Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFE74C3C),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recommendations Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.checklist, color: Color(0xFF27AE60)),
                  SizedBox(width: 8),
                  Text(
                    'Recommendations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                ],
              ),
            ),

            if (dailyAction.recommendations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No specific recommendations for today',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              )
            else
              ...dailyAction.recommendations.map(
                (recommendation) =>
                    _buildRecommendationCard(recommendation, controller),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    ActionRecommendation recommendation,
    HomeController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getPriorityColor(
                recommendation.priority,
              ).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  recommendation.priority.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.action,
                    style: TextStyle(
                      color: _getPriorityColor(recommendation.priority),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getActionTypeIcon(recommendation.type),
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getActionTypeLabel(recommendation.type),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                  ),
                ),
                if (recommendation.timing != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF3498DB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recommendation.timing!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3498DB),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.critical:
        return const Color(0xFFE74C3C);
      case ActionPriority.recommended:
        return const Color(0xFF3498DB);
      case ActionPriority.optional:
        return const Color(0xFF95A5A6);
      case ActionPriority.avoid:
        return const Color(0xFFE67E22);
    }
  }

  IconData _getActionTypeIcon(ActionType type) {
    switch (type) {
      case ActionType.irrigation:
        return Icons.water_drop;
      case ActionType.fertilization:
        return Icons.science;
      case ActionType.pestControl:
        return Icons.bug_report;
      case ActionType.weedControl:
        return Icons.grass;
      case ActionType.harvesting:
        return Icons.agriculture;
      case ActionType.monitoring:
        return Icons.visibility;
      case ActionType.other:
        return Icons.more_horiz;
    }
  }

  String _getActionTypeLabel(ActionType type) {
    switch (type) {
      case ActionType.irrigation:
        return 'Irrigation';
      case ActionType.fertilization:
        return 'Fertilization';
      case ActionType.pestControl:
        return 'Pest Control';
      case ActionType.weedControl:
        return 'Weed Control';
      case ActionType.harvesting:
        return 'Harvesting';
      case ActionType.monitoring:
        return 'Monitoring';
      case ActionType.other:
        return 'Other';
    }
  }
}
