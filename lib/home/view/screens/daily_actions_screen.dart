// daily_actions_screen.dart - Show ML-powered daily recommendations
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/ml_api_service.dart';

class DailyActionsScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic> farmData;

  const DailyActionsScreen({
    super.key,
    required this.selectedDate,
    required this.farmData,
  });

  @override
  State<DailyActionsScreen> createState() => _DailyActionsScreenState();
}

class _DailyActionsScreenState extends State<DailyActionsScreen> {
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
          _error = 'ML API Server not available. Please start the server.';
          _isLoading = false;
        });
        return;
      }

      // Get comprehensive plan
      final plan = await MLApiService.getComprehensivePlan(
        farmData: widget.farmData,
        targetDate: DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      );

      if (plan == null || !plan['success']) {
        setState(() {
          _error = 'Failed to get recommendations';
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE74C3C);
      case 'high':
        return const Color(0xFFF39C12);
      case 'medium':
        return const Color(0xFF3498DB);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fertilizer':
        return Icons.grass;
      case 'irrigation':
        return Icons.water_drop;
      case 'weather':
        return Icons.cloud;
      case 'disease':
        return Icons.bug_report;
      case 'soil':
        return Icons.terrain;
      case 'harvest':
        return Icons.agriculture;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Plan - ${DateFormat('MMM dd, yyyy').format(widget.selectedDate)}',
        ),
        backgroundColor: const Color(0xFF27AE60),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : _buildPlanView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_error!.contains('API Server'))
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Start API Server',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Open terminal and run:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'cd engine/api\npython app.py',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanView() {
    final dailyPlan = _planData!['daily_plan'];
    final yieldForecast = _planData!['yield_forecast'];
    final cropStage = dailyPlan['crop_stage'];
    final actions = dailyPlan['actions'] as List;
    final alerts = dailyPlan['alerts'] as List;
    final daysToHarvest = dailyPlan['days_to_harvest'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Stage Card
          _buildStageCard(cropStage, daysToHarvest),
          const SizedBox(height: 16),

          // Alerts Section
          if (alerts.isNotEmpty) ...[
            _buildSectionTitle('🚨 Alerts & Warnings'),
            const SizedBox(height: 8),
            ...alerts.map((alert) => _buildAlertCard(alert)).toList(),
            const SizedBox(height: 16),
          ],

          // Today's Tasks
          _buildSectionTitle('📋 Today\'s Tasks'),
          const SizedBox(height: 8),
          ...actions.map((action) => _buildActionCard(action)).toList(),
          const SizedBox(height: 16),

          // Yield Forecast
          _buildYieldForecastCard(yieldForecast),
          const SizedBox(height: 16),

          // Model Info
          _buildModelInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStageCard(Map<String, dynamic> stage, int daysToHarvest) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['stage'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day ${stage['days']} since planting',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stage['description'],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            if (daysToHarvest > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$daysToHarvest days to harvest',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'medium';
    final type = alert['type'] ?? 'info';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _getSeverityColor(severity), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _getAlertIcon(type),
              color: _getSeverityColor(severity),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alert['message'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final priority = action['priority'] ?? 'medium';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action['task'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action['description'],
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  action['timing'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYieldForecastCard(Map<String, dynamic> forecast) {
    if (forecast['error'] != null) return const SizedBox.shrink();

    final economics = forecast['economics'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF27AE60),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Expected Yield & Profit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildYieldRow(
              'Total Yield',
              '${forecast['total_yield_tonnes']} tonnes (${forecast['total_yield_kg']} kg)',
            ),
            _buildYieldRow(
              'Per Hectare',
              '${forecast['yield_per_hectare']} tonnes/ha',
            ),
            _buildYieldRow('Confidence', '${forecast['confidence']}%'),
            const Divider(height: 24),
            _buildYieldRow(
              'Expected Income',
              '₹${economics['gross_income_low']} - ₹${economics['gross_income_high']}',
              valueColor: const Color(0xFF27AE60),
            ),
            _buildYieldRow('Production Cost', '₹${economics['total_cost']}'),
            _buildYieldRow(
              'Net Profit',
              '₹${economics['net_profit_low']} - ₹${economics['net_profit_high']}',
              valueColor: const Color(0xFF27AE60),
              bold: true,
            ),
            _buildYieldRow(
              'ROI',
              '${economics['roi_low']}% - ${economics['roi_high']}%',
              valueColor: const Color(0xFF27AE60),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYieldRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Powered by AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'XGBoost ML Model (R²=0.71) with NASA Climate Data',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
