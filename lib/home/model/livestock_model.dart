import 'package:flutter/material.dart';

class Livestock {
  final String id;
  final String name;
  final String icon;
  final Color themeColor;
  final List<LivestockStage> lifecycleStages;

  Livestock({
    required this.id,
    required this.name,
    required this.icon,
    required this.themeColor,
    required this.lifecycleStages,
  });
}

class LivestockStage {
  final int ageInMonths; // e.g., 1, 6, 12
  final String stageName; // e.g., "Calf", "Heifer"
  final String actionTitle; // e.g., "Vaccination"
  final String description; // e.g., "FMD Vaccination..."
  final dynamic icon;

  LivestockStage({
    required this.ageInMonths,
    required this.stageName,
    required this.actionTitle,
    required this.description,
    this.icon = Icons.pets,
  });

  IconData get iconData {
    if (icon is IconData) return icon as IconData;
    if (icon is String) {
      switch (icon.toLowerCase()) {
        case 'vaccine':
          return Icons.vaccines;
        case 'medical':
          return Icons.medical_services;
        case 'feed':
          return Icons.grass;
        case 'water':
          return Icons.water_drop;
        default:
          return Icons.pets;
      }
    }
    return Icons.pets;
  }
}
