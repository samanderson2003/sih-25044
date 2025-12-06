// Farm Plot Visualization Models
import 'package:flutter/material.dart';
import 'dart:math';

enum FarmShape { square, rectangle }

class FarmPlotModel {
  final String id;
  final String userId;
  final double landSize; // in acres
  final String landSizeUnit; // 'acres' or 'cents'
  final FarmShape shape;
  final List<String> availableCrops; // From prior data collection
  final List<GridCellModel> gridCells;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmPlotModel({
    required this.id,
    required this.userId,
    required this.landSize,
    this.landSizeUnit = 'acres',
    required this.shape,
    required this.availableCrops,
    required this.gridCells,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate grid dimensions based on shape and land size
  static GridDimensions calculateGridDimensions(
    double landSize,
    FarmShape shape,
  ) {
    // Each grid cell represents approximately 0.125 acres (0.05 hectares)
    // This gives a good visual representation
    const cellSize = 0.125;
    int totalCells = (landSize / cellSize).ceil();

    // Ensure minimum 4 cells for visibility
    if (totalCells < 4) totalCells = 4;

    int rows, cols;

    if (shape == FarmShape.square) {
      // Make it as square as possible
      rows = sqrt(totalCells.toDouble()).ceil();
      cols = (totalCells / rows).ceil();
    } else {
      // Rectangle: make it wider than tall (2:1 ratio approximately)
      cols = (sqrt(totalCells.toDouble()) * 1.5).ceil();
      rows = (totalCells / cols).ceil();
    }

    return GridDimensions(rows: rows, cols: cols, cellSize: cellSize);
  }

  // Generate empty grid cells
  static List<GridCellModel> generateEmptyGrid(
    int rows,
    int cols,
    double cellSize,
  ) {
    List<GridCellModel> cells = [];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        cells.add(
          GridCellModel(
            row: row,
            col: col,
            cellSize: cellSize,
            cropName: null,
            plantedDate: null,
          ),
        );
      }
    }
    return cells;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'landSize': landSize,
      'landSizeUnit': landSizeUnit,
      'shape': shape.name,
      'availableCrops': availableCrops,
      'gridCells': gridCells.map((cell) => cell.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FarmPlotModel.fromJson(Map<String, dynamic> json) {
    return FarmPlotModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      landSize: (json['landSize'] ?? 0).toDouble(),
      landSizeUnit: json['landSizeUnit'] ?? 'acres',
      shape: FarmShape.values.firstWhere(
        (e) => e.name == json['shape'],
        orElse: () => FarmShape.square,
      ),
      availableCrops: json['availableCrops'] != null
          ? List<String>.from(json['availableCrops'])
          : [],
      gridCells: json['gridCells'] != null
          ? (json['gridCells'] as List)
                .map((cell) => GridCellModel.fromJson(cell))
                .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Get grid dimensions
  GridDimensions getGridDimensions() {
    if (gridCells.isEmpty) {
      return calculateGridDimensions(landSize, shape);
    }
    final maxRow = gridCells.map((c) => c.row).reduce((a, b) => a > b ? a : b);
    final maxCol = gridCells.map((c) => c.col).reduce((a, b) => a > b ? a : b);
    return GridDimensions(
      rows: maxRow + 1,
      cols: maxCol + 1,
      cellSize: gridCells.first.cellSize,
    );
  }

  // Get crop statistics
  Map<String, int> getCropDistribution() {
    Map<String, int> distribution = {};
    for (var cell in gridCells) {
      if (cell.cropName != null) {
        distribution[cell.cropName!] = (distribution[cell.cropName!] ?? 0) + 1;
      }
    }
    return distribution;
  }
}

class GridCellModel {
  final int row;
  final int col;
  final double cellSize; // in acres
  final String? cropName;
  final DateTime? plantedDate;

  GridCellModel({
    required this.row,
    required this.col,
    required this.cellSize,
    this.cropName,
    this.plantedDate,
  });

  // Get emoji for crop (for visual display)
  String get cropEmoji {
    if (cropName == null) return '🌱';

    final crop = cropName!.toLowerCase();
    if (crop.contains('rice') || crop.contains('paddy')) return '🌾';
    if (crop.contains('wheat')) return '🌾';
    if (crop.contains('corn') || crop.contains('maize')) return '🌽';
    if (crop.contains('tomato')) return '🍅';
    if (crop.contains('potato')) return '🥔';
    if (crop.contains('carrot')) return '🥕';
    if (crop.contains('onion')) return '🧅';
    if (crop.contains('cotton')) return '🌸';
    if (crop.contains('sugarcane')) return '🎋';
    if (crop.contains('coffee')) return '☕';
    if (crop.contains('tea')) return '🍵';
    return '🌿';
  }

  // Get realistic farm field color for crop
  Color get cropColor {
    if (cropName == null) {
      // Empty field - rich brown soil color
      return const Color(0xFFB8977A);
    }

    final crop = cropName!.toLowerCase();

    // Realistic field colors based on actual crop appearance
    if (crop.contains('rice') || crop.contains('paddy')) {
      return const Color(0xFF7CB342); // Vibrant green paddy
    }
    if (crop.contains('wheat')) {
      return const Color(0xFFD4A76A); // Golden wheat
    }
    if (crop.contains('corn') || crop.contains('maize')) {
      return const Color(0xFFF9A825); // Bright corn yellow
    }
    if (crop.contains('tomato')) {
      return const Color(0xFFE57373); // Tomato red with green leaves
    }
    if (crop.contains('potato')) {
      return const Color(0xFF8D6E63); // Dark soil brown
    }
    if (crop.contains('carrot')) {
      return const Color(0xFFFF7043); // Carrot orange
    }
    if (crop.contains('onion')) {
      return const Color(0xFFAB47BC); // Purple onion
    }
    if (crop.contains('cotton')) {
      return const Color(0xFFF5F5F5); // White cotton
    }
    if (crop.contains('sugarcane')) {
      return const Color(0xFF9CCC65); // Light green cane
    }
    if (crop.contains('coffee')) {
      return const Color(0xFF6D4C41); // Coffee brown
    }
    if (crop.contains('tea')) {
      return const Color(0xFF558B2F); // Deep green tea
    }
    return const Color(0xFF66BB6A); // Default green
  }

  // Get accent/border color for depth effect
  Color get cropAccentColor {
    if (cropName == null) {
      return const Color(0xFF9E7C5A); // Darker soil
    }
    return Color.alphaBlend(Colors.black.withOpacity(0.15), cropColor);
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'cellSize': cellSize,
      'cropName': cropName,
      'plantedDate': plantedDate?.toIso8601String(),
    };
  }

  factory GridCellModel.fromJson(Map<String, dynamic> json) {
    return GridCellModel(
      row: json['row'] ?? 0,
      col: json['col'] ?? 0,
      cellSize: (json['cellSize'] ?? 0.125).toDouble(),
      cropName: json['cropName'],
      plantedDate: json['plantedDate'] != null
          ? DateTime.parse(json['plantedDate'])
          : null,
    );
  }

  GridCellModel copyWith({String? cropName, DateTime? plantedDate}) {
    return GridCellModel(
      row: row,
      col: col,
      cellSize: cellSize,
      cropName: cropName ?? this.cropName,
      plantedDate: plantedDate ?? this.plantedDate,
    );
  }
}

class GridDimensions {
  final int rows;
  final int cols;
  final double cellSize;

  GridDimensions({
    required this.rows,
    required this.cols,
    required this.cellSize,
  });

  int get totalCells => rows * cols;
  double get totalArea => totalCells * cellSize;
}
