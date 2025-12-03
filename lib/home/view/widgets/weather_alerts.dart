import 'package:flutter/material.dart';
import '../../model/weather_model.dart';

class WeatherAlerts extends StatelessWidget {
  final List<WeatherAlert> alerts;

  const WeatherAlerts({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSeverityColor(alerts.first.severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSeverityColor(alerts.first.severity),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerts
            .map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getSeverityIcon(alert.severity),
                      color: _getSeverityColor(alert.severity),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(
                              color: _getSeverityColor(alert.severity),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert.message,
                            style: TextStyle(
                              color: _getSeverityColor(
                                alert.severity,
                              ).withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return const Color(0xFF3498DB);
      case AlertSeverity.medium:
        return const Color(0xFFF39C12);
      case AlertSeverity.high:
        return const Color(0xFFE74C3C);
      case AlertSeverity.critical:
        return const Color(0xFFC0392B);
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Icons.info_outline;
      case AlertSeverity.medium:
        return Icons.warning_amber_outlined;
      case AlertSeverity.high:
        return Icons.error_outline;
      case AlertSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }
}
