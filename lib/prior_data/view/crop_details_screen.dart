import 'package:flutter/material.dart';
import '../model/farm_data_model.dart';

class CropDetailsScreen extends StatefulWidget {
  final LandDetailsModel landDetails;
  final SoilQualityModel soilQuality;
  final PastDataModel pastData;
  final CropDetailsModel? existingData;

  const CropDetailsScreen({
    super.key,
    required this.landDetails,
    required this.soilQuality,
    required this.pastData,
    this.existingData,
  });

  @override
  State<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cropNameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _seedRateController = TextEditingController();

  String? _season;
  DateTime? _sowingDate;
  DateTime? _expectedHarvestDate;

  bool _isSaving = false;

  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  static const textColor = Color(0xFF4A4A4A);

  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    _cropNameController.text = data.currentCropName;
    _season = data.season;
    _sowingDate = data.sowingDate;
    _expectedHarvestDate = data.expectedHarvestDate;
    _varietyController.text = data.variety ?? '';
    _seedRateController.text = data.seedRate?.toString() ?? '';
  }

  Future<void> _selectDate(BuildContext context, bool isSowing) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isSowing
          ? (_sowingDate ?? DateTime.now())
          : (_expectedHarvestDate ??
                DateTime.now().add(const Duration(days: 90))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isSowing) {
          _sowingDate = picked;
        } else {
          _expectedHarvestDate = picked;
        }
      });
    }
  }

  Future<void> _handleFinish() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sowingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select sowing date')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final cropDetails = CropDetailsModel(
        currentCropName: _cropNameController.text,
        season: _season!,
        sowingDate: _sowingDate!,
        expectedHarvestDate: _expectedHarvestDate,
        variety: _varietyController.text.isNotEmpty
            ? _varietyController.text
            : null,
        seedRate: double.tryParse(_seedRateController.text),
      );

      // Return data back to welcome screen
      Navigator.pop(context, cropDetails);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _varietyController.dispose();
    _seedRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Current Crop Details'),
        elevation: 0,
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
                  'Step 4 of 4',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 1.0,
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
                      'Tell us about your current crop',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This information helps us provide accurate predictions',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Crop name
                    TextFormField(
                      controller: _cropNameController,
                      decoration: _inputDecoration(
                        'Crop Name*',
                        'e.g., Wheat, Rice, Cotton',
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter crop name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Season
                    DropdownButtonFormField<String>(
                      value: _season,
                      decoration: _inputDecoration('Season*', null),
                      items: _seasons
                          .map(
                            (season) => DropdownMenuItem(
                              value: season,
                              child: Text(season),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _season = value),
                      validator: (value) =>
                          value == null ? 'Please select season' : null,
                    ),
                    const SizedBox(height: 16),

                    // Sowing date
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: _inputDecoration('Sowing Date*', null),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _sowingDate == null
                                  ? 'Select sowing date'
                                  : '${_sowingDate!.day}/${_sowingDate!.month}/${_sowingDate!.year}',
                              style: TextStyle(
                                color: _sowingDate == null
                                    ? textColor.withOpacity(0.5)
                                    : textColor,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Expected harvest date
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          'Expected Harvest Date',
                          null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _expectedHarvestDate == null
                                  ? 'Select harvest date (optional)'
                                  : '${_expectedHarvestDate!.day}/${_expectedHarvestDate!.month}/${_expectedHarvestDate!.year}',
                              style: TextStyle(
                                color: _expectedHarvestDate == null
                                    ? textColor.withOpacity(0.5)
                                    : textColor,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Variety
                    TextFormField(
                      controller: _varietyController,
                      decoration: _inputDecoration(
                        'Variety',
                        'e.g., Basmati, BT Cotton',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Seed rate
                    TextFormField(
                      controller: _seedRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration('Seed Rate (kg/acre)', null),
                    ),

                    const SizedBox(height: 32),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can update these details anytime from your profile',
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Finish button
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
                onPressed: _isSaving ? null : _handleFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Finish Setup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String? hint) {
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
