import 'package:flutter/material.dart';
import '../../models/farm_plot_model.dart';
import '../../prior_data/model/farm_data_model.dart';

class FarmPlotEditorScreen extends StatefulWidget {
  final FarmDataModel farmData;

  const FarmPlotEditorScreen({super.key, required this.farmData});

  @override
  State<FarmPlotEditorScreen> createState() => _FarmPlotEditorScreenState();
}

class _FarmPlotEditorScreenState extends State<FarmPlotEditorScreen> {
  FarmShape _selectedShape = FarmShape.square;
  List<GridCellModel> _gridCells = [];
  late GridDimensions _gridDimensions;
  String? _selectedCrop;

  @override
  void initState() {
    super.initState();
    _generateGrid();
  }

  void _generateGrid() {
    final landSize = widget.farmData.farmBasics.landSize;
    final landSizeUnit = widget.farmData.farmBasics.landSizeUnit;

    // Convert to acres if in cents
    final acres = landSizeUnit == 'cents' ? landSize * 0.00988 : landSize;

    _gridDimensions = FarmPlotModel.calculateGridDimensions(
      acres,
      _selectedShape,
    );

    _gridCells = FarmPlotModel.generateEmptyGrid(
      _gridDimensions.rows,
      _gridDimensions.cols,
      _gridDimensions.cellSize,
    );
  }

  void _onShapeChanged(FarmShape? shape) {
    if (shape == null) return;
    setState(() {
      _selectedShape = shape;
      _generateGrid();
    });
  }

  void _onCellTap(int row, int col) {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a crop first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      final index = row * _gridDimensions.cols + col;
      _gridCells[index] = _gridCells[index].copyWith(
        cropName: _selectedCrop,
        plantedDate: DateTime.now(),
      );
    });
  }

  void _clearCell(int row, int col) {
    setState(() {
      final index = row * _gridDimensions.cols + col;
      _gridCells[index] = GridCellModel(
        row: row,
        col: col,
        cellSize: _gridDimensions.cellSize,
        cropName: null,
        plantedDate: null,
      );
    });
  }

  void _fillAllWithCrop() {
    if (_selectedCrop == null) return;

    setState(() {
      _gridCells = _gridCells.map((cell) {
        return cell.copyWith(
          cropName: _selectedCrop,
          plantedDate: DateTime.now(),
        );
      }).toList();
    });
  }

  void _clearAll() {
    setState(() {
      _generateGrid();
    });
  }

  void _savePlot() {
    // Check if at least one cell has a crop
    final hasAnyCrop = _gridCells.any((cell) => cell.cropName != null);

    if (!hasAnyCrop) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign crops to at least one cell'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create FarmPlotModel
    final farmPlot = FarmPlotModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.farmData.userId,
      landSize: widget.farmData.farmBasics.landSize,
      landSizeUnit: widget.farmData.farmBasics.landSizeUnit,
      shape: _selectedShape,
      availableCrops: widget.farmData.farmBasics.crops,
      gridCells: _gridCells,
      createdAt: DateTime.now(),
    );

    // Return to profile with farm plot data
    Navigator.of(context).pop(farmPlot);
  }

  Map<String, int> _getCropStats() {
    Map<String, int> stats = {};
    for (var cell in _gridCells) {
      if (cell.cropName != null) {
        stats[cell.cropName!] = (stats[cell.cropName!] ?? 0) + 1;
      }
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final crops = widget.farmData.farmBasics.crops;
    final cropStats = _getCropStats();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.landscape, size: 24),
            SizedBox(width: 8),
            Text('Farm Plot Designer'),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D5016), Color(0xFF3E6B1F)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _savePlot,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2D5016),
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Shape selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Farm Shape',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<FarmShape>(
                        title: const Text('Square'),
                        subtitle: Text(
                          '${_selectedShape == FarmShape.square ? _gridDimensions.rows : ''} x ${_selectedShape == FarmShape.square ? _gridDimensions.cols : ''}',
                        ),
                        value: FarmShape.square,
                        groupValue: _selectedShape,
                        onChanged: _onShapeChanged,
                        activeColor: const Color(0xFF2D5016),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<FarmShape>(
                        title: const Text('Rectangle'),
                        subtitle: Text(
                          '${_selectedShape == FarmShape.rectangle ? _gridDimensions.rows : ''} x ${_selectedShape == FarmShape.rectangle ? _gridDimensions.cols : ''}',
                        ),
                        value: FarmShape.rectangle,
                        groupValue: _selectedShape,
                        onChanged: _onShapeChanged,
                        activeColor: const Color(0xFF2D5016),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Crop selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Crop to Assign',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _fillAllWithCrop,
                          icon: const Icon(Icons.format_color_fill, size: 16),
                          label: const Text('Fill All'),
                        ),
                        TextButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: crops.map((crop) {
                    final isSelected = _selectedCrop == crop;
                    final count = cropStats[crop] ?? 0;

                    return FilterChip(
                      label: Text('$crop ${count > 0 ? '($count)' : ''}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCrop = selected ? crop : null;
                        });
                      },
                      selectedColor: const Color(0xFF2D5016).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF2D5016),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Grid display
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tap cells to assign ${_selectedCrop ?? 'a crop'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats bar
          if (cropStats.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFF2D5016),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Crop Distribution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...cropStats.entries.map((entry) {
                    final percentage = (entry.value / _gridCells.length * 100);
                    // Get cell to access color
                    final sampleCell = _gridCells.firstWhere(
                      (c) => c.cropName == entry.key,
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  sampleCell.cropColor,
                                  sampleCell.cropAccentColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: sampleCell.cropAccentColor,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sampleCell.cropEmoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation(
                                  sampleCell.cropColor,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: Text(
                              '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.end,
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
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
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
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: List.generate(_gridDimensions.rows, (row) {
            return Row(
              children: List.generate(_gridDimensions.cols, (col) {
                final index = row * _gridDimensions.cols + col;
                final cell = _gridCells[index];
                final isSelected =
                    cell.cropName == _selectedCrop && _selectedCrop != null;

                return GestureDetector(
                  onTap: () => _onCellTap(row, col),
                  onLongPress: () => _clearCell(row, col),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      // Gradient for realistic depth
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cell.cropColor, cell.cropAccentColor],
                      ),
                      // Field borders
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : cell.cropAccentColor,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      // Highlight selected cells
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Texture overlay
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
                              fontSize: 22,
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
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}
