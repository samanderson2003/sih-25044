import 'package:flutter/material.dart';
import '../../models/farm_plot_model.dart';

class FarmPlotVisualization extends StatelessWidget {
  final FarmPlotModel farmPlot;
  final bool showStats;
  final double? maxWidth;

  const FarmPlotVisualization({
    super.key,
    required this.farmPlot,
    this.showStats = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final gridDims = farmPlot.getGridDimensions();
    final cropStats = farmPlot.getCropDistribution();
    final screenWidth = maxWidth ?? MediaQuery.of(context).size.width - 32;
    final cellSize = (screenWidth / gridDims.cols).clamp(30.0, 60.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Farm info header - Enhanced design
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF2D5016), const Color(0xFF3E6B1F)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${farmPlot.landSize} ${farmPlot.landSizeUnit}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            farmPlot.shape == FarmShape.square
                                ? Icons.crop_square
                                : Icons.crop_landscape,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${farmPlot.shape == FarmShape.square ? 'Square' : 'Rectangle'} Field',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_on,
                      color: Color(0xFF2D5016),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${gridDims.rows} × ${gridDims.cols}',
                      style: const TextStyle(
                        color: Color(0xFF2D5016),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid visualization - Realistic farm field
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  // Farm boundary - wooden fence style
                  border: Border.all(color: const Color(0xFF5D4037), width: 4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: List.generate(gridDims.rows, (row) {
                      return Row(
                        children: List.generate(gridDims.cols, (col) {
                          final index = row * gridDims.cols + col;
                          final cell = farmPlot.gridCells[index];

                          return Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              // Gradient for realistic depth
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [cell.cropColor, cell.cropAccentColor],
                              ),
                              // Field borders - subtle furrows
                              border: Border.all(
                                color: cell.cropAccentColor,
                                width: 1.5,
                              ),
                              // Very subtle rounded corners for organic look
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Stack(
                              children: [
                                // Subtle texture overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                ),
                                // Crop emoji
                                Center(
                                  child: Text(
                                    cell.cropEmoji,
                                    style: TextStyle(
                                      fontSize: cellSize * 0.45,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 2,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Crop legend and stats
        if (showStats && cropStats.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crop Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...cropStats.entries.map((entry) {
                  final percentage =
                      (entry.value / farmPlot.gridCells.length * 100);
                  final cellArea = gridDims.cellSize * entry.value;

                  // Get color for this crop
                  final color = farmPlot.gridCells
                      .firstWhere((c) => c.cropName == entry.key)
                      .cropColor;

                  final emoji = farmPlot.gridCells
                      .firstWhere((c) => c.cropName == entry.key)
                      .cropEmoji;

                  final accentColor = farmPlot.gridCells
                      .firstWhere((c) => c.cropName == entry.key)
                      .cropAccentColor;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Crop indicator with gradient
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [color, accentColor],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accentColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2D5016),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.square_foot,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${cellArea.toStringAsFixed(2)} ${farmPlot.landSizeUnit}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.pie_chart,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
