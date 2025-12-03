import 'weather_model.dart';

class DailyAction {
  final DateTime date;
  final String cropId;
  final String cropStage;
  final Weather weather;
  final List<ActionRecommendation> recommendations;
  final List<String> warnings;

  DailyAction({
    required this.date,
    required this.cropId,
    required this.cropStage,
    required this.weather,
    required this.recommendations,
    required this.warnings,
  });
}

class ActionRecommendation {
  final String action;
  final String reason;
  final ActionType type;
  final String? timing; // e.g., "tomorrow morning", "after 48 hours"
  final ActionPriority priority;

  ActionRecommendation({
    required this.action,
    required this.reason,
    required this.type,
    this.timing,
    required this.priority,
  });
}

enum ActionType {
  irrigation,
  fertilization,
  pestControl,
  weedControl,
  harvesting,
  monitoring,
  other,
}

enum ActionPriority {
  critical, // Must do
  recommended, // Should do
  optional, // Can do
  avoid, // Don't do
}

extension ActionPriorityExtension on ActionPriority {
  String get emoji {
    switch (this) {
      case ActionPriority.critical:
        return '⚠️';
      case ActionPriority.recommended:
        return '🕒';
      case ActionPriority.optional:
        return 'ℹ️';
      case ActionPriority.avoid:
        return '🚫';
    }
  }
}
