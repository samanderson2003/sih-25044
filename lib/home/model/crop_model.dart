import 'package:flutter/material.dart';

class Crop {
  final String id;
  final String name;
  final String icon;
  final Color themeColor;
  final Map<int, SeasonSuitability>
  monthSuitability; // month (1-12) -> suitability
  final Map<int, List<WeeklyTask>> monthlyTasks; // month -> weekly tasks
  final List<CropStage> lifecycleStages; // NEW: Day-wise lifecycle stages

  Crop({
    required this.id,
    required this.name,
    required this.icon,
    required this.themeColor,
    required this.monthSuitability,
    required this.monthlyTasks,
    this.lifecycleStages = const [], // Default to empty
  });
}

// NEW CLASS: Defines specific actions based on days after planting
class CropStage {
  final int daysAfterPlanting; // e.g., 1, 5, 15
  final String stageName; // e.g., "Germination"
  final String actionTitle; // e.g., "Apply First Fertilizer"
  final String description; // e.g., "Apply NPK..."
  final IconData icon;

  CropStage({
    required this.daysAfterPlanting,
    required this.stageName,
    required this.actionTitle,
    required this.description,
    this.icon = Icons.grass,
  });
}

enum SeasonSuitability {
  highCompatibility, // Peak season (Red)
  normal, // Moderate season (Green)
  notRecommended, // Not ideal (Yellow)
}

extension SeasonSuitabilityExtension on SeasonSuitability {
  Color get color {
    switch (this) {
      case SeasonSuitability.highCompatibility:
        return const Color(0xFFE74C3C); // Red
      case SeasonSuitability.normal:
        return const Color(0xFF27AE60); // Green
      case SeasonSuitability.notRecommended:
        return const Color(0xFFF39C12); // Yellow
    }
  }

  String get label {
    switch (this) {
      case SeasonSuitability.highCompatibility:
        return 'Peak Season';
      case SeasonSuitability.normal:
        return 'Moderate';
      case SeasonSuitability.notRecommended:
        return 'Not Ideal';
    }
  }
}

class WeeklyTask {
  final int week; // 1-4
  final String stage;
  final List<String> tasks;

  WeeklyTask({required this.week, required this.stage, required this.tasks});
}

// import 'package:flutter/material.dart';
//
// class Crop {
//   final String id;
//   final String name;
//   final String icon;
//   final Color themeColor;
//   final Map<int, SeasonSuitability>
//   monthSuitability; // month (1-12) -> suitability
//   final Map<int, List<WeeklyTask>> monthlyTasks; // month -> weekly tasks
//
//   Crop({
//     required this.id,
//     required this.name,
//     required this.icon,
//     required this.themeColor,
//     required this.monthSuitability,
//     required this.monthlyTasks,
//   });
// }
//
// enum SeasonSuitability {
//   highCompatibility, // Peak season (Red)
//   normal, // Moderate season (Green)
//   notRecommended, // Not ideal (Yellow)
// }
//
// extension SeasonSuitabilityExtension on SeasonSuitability {
//   Color get color {
//     switch (this) {
//       case SeasonSuitability.highCompatibility:
//         return const Color(0xFFE74C3C); // Red
//       case SeasonSuitability.normal:
//         return const Color(0xFF27AE60); // Green
//       case SeasonSuitability.notRecommended:
//         return const Color(0xFFF39C12); // Yellow
//     }
//   }
//
//   String get label {
//     switch (this) {
//       case SeasonSuitability.highCompatibility:
//         return 'Peak Season';
//       case SeasonSuitability.normal:
//         return 'Moderate';
//       case SeasonSuitability.notRecommended:
//         return 'Not Ideal';
//     }
//   }
// }
//
// class WeeklyTask {
//   final int week; // 1-4
//   final String stage;
//   final List<String> tasks;
//
//   WeeklyTask({required this.week, required this.stage, required this.tasks});
// }
