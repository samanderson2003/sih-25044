import 'package:flutter/material.dart';
import '../model/farm_data_model.dart';

class PastDataScreen extends StatefulWidget {
  final LandDetailsModel landDetails;
  final SoilQualityModel soilQuality;
  final PastDataModel? existingData;

  const PastDataScreen({
    super.key,
    required this.landDetails,
    required this.soilQuality,
    this.existingData,
  });

  @override
  State<PastDataScreen> createState() => _PastDataScreenState();
}

class _PastDataScreenState extends State<PastDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<CropHistoryModel> _cropHistory = [];
  final _averageYieldController = TextEditingController();
  final _commonPestsController = TextEditingController();
  final _commonDiseasesController = TextEditingController();
  final _fertilizersUsedController = TextEditingController();

  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  static const textColor = Color(0xFF4A4A4A);

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    _cropHistory.addAll(data.cropHistory);
    _averageYieldController.text = data.averageYield?.toString() ?? '';
    _commonPestsController.text = data.commonPests?.join(', ') ?? '';
    _commonDiseasesController.text = data.commonDiseases?.join(', ') ?? '';
    _fertilizersUsedController.text = data.fertilizersUsed ?? '';
  }

  void _addCropHistory() {
    showDialog(
      context: context,
      builder: (context) => _CropHistoryDialog(
        onSave: (history) {
          setState(() {
            _cropHistory.add(history);
          });
        },
      ),
    );
  }

  void _editCropHistory(int index) {
    showDialog(
      context: context,
      builder: (context) => _CropHistoryDialog(
        existingHistory: _cropHistory[index],
        onSave: (history) {
          setState(() {
            _cropHistory[index] = history;
          });
        },
      ),
    );
  }

  void _removeCropHistory(int index) {
    setState(() {
      _cropHistory.removeAt(index);
    });
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;

    final pastData = PastDataModel(
      cropHistory: _cropHistory,
      averageYield: double.tryParse(_averageYieldController.text),
      commonPests: _commonPestsController.text.isNotEmpty
          ? _commonPestsController.text.split(',').map((e) => e.trim()).toList()
          : null,
      commonDiseases: _commonDiseasesController.text.isNotEmpty
          ? _commonDiseasesController.text
                .split(',')
                .map((e) => e.trim())
                .toList()
          : null,
      fertilizersUsed: _fertilizersUsedController.text.isNotEmpty
          ? _fertilizersUsedController.text
          : null,
    );

    // Return data back to welcome screen
    Navigator.pop(context, pastData);
  }

  void _skip() {
    final pastData = PastDataModel(
      cropHistory: const [],
      averageYield: null,
      commonPests: null,
      commonDiseases: null,
      fertilizersUsed: null,
    );

    // Return empty data back to welcome screen
    Navigator.pop(context, pastData);
  }

  @override
  void dispose() {
    _averageYieldController.dispose();
    _commonPestsController.dispose();
    _commonDiseasesController.dispose();
    _fertilizersUsedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Past Crop Data'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            color: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Step 3 of 4',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crop History (Last 2-3 Years)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us understand your farming patterns',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Crop history list
                    if (_cropHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: textColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No crop history added yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._cropHistory.asMap().entries.map((entry) {
                        final index = entry.key;
                        final history = entry.value;
                        return _buildHistoryCard(history, index);
                      }),

                    const SizedBox(height: 16),

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addCropHistory,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Crop History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Average yield
                    TextFormField(
                      controller: _averageYieldController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(
                        'Average Yield (quintals/acre)',
                        'Overall average from past crops',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Common pests
                    TextFormField(
                      controller: _commonPestsController,
                      decoration: _inputDecoration(
                        'Common Pests',
                        'e.g., Aphids, Bollworms (comma separated)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Common diseases
                    TextFormField(
                      controller: _commonDiseasesController,
                      decoration: _inputDecoration(
                        'Common Diseases',
                        'e.g., Leaf blight, Root rot (comma separated)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Fertilizers used
                    TextFormField(
                      controller: _fertilizersUsedController,
                      decoration: _inputDecoration(
                        'Fertilizers Used',
                        'e.g., Urea, DAP, NPK (comma separated)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next: Current Crop',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(CropHistoryModel history, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.agriculture, color: primaryColor),
        ),
        title: Text(
          history.cropName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${history.season} ${history.year} • ${history.yield} quintals/acre',
          style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editCropHistory(index),
              color: primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _removeCropHistory(index),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

// Dialog for adding/editing crop history
class _CropHistoryDialog extends StatefulWidget {
  final CropHistoryModel? existingHistory;
  final Function(CropHistoryModel) onSave;

  const _CropHistoryDialog({this.existingHistory, required this.onSave});

  @override
  State<_CropHistoryDialog> createState() => _CropHistoryDialogState();
}

class _CropHistoryDialogState extends State<_CropHistoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _yieldController = TextEditingController();
  String? _season;
  int? _year;

  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];
  final List<int> _years = List.generate(
    5,
    (index) => DateTime.now().year - index,
  );

  @override
  void initState() {
    super.initState();
    if (widget.existingHistory != null) {
      _cropNameController.text = widget.existingHistory!.cropName;
      _season = widget.existingHistory!.season;
      _year = widget.existingHistory!.year;
      _yieldController.text = widget.existingHistory!.yield.toString();
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final history = CropHistoryModel(
      cropName: _cropNameController.text,
      season: _season!,
      year: _year!,
      yield: double.parse(_yieldController.text),
    );

    widget.onSave(history);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingHistory == null
            ? 'Add Crop History'
            : 'Edit Crop History',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(labelText: 'Crop Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _season,
                decoration: const InputDecoration(labelText: 'Season'),
                items: _seasons
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _season = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _year,
                decoration: const InputDecoration(labelText: 'Year'),
                items: _years
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (value) => setState(() => _year = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yieldController,
                decoration: const InputDecoration(
                  labelText: 'Yield (quintals/acre)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
