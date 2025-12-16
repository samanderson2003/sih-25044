import 'package:flutter/material.dart';
import '../model/farm_data_model.dart';
import 'map_location_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:open_location_code/open_location_code.dart' as olc;

/// Step 1: Farm Basics - Location, Size, Crop, Season
/// Simplified from old LandDetailsScreen - only essential ML model inputs
class FarmBasicsScreen extends StatefulWidget {
  final FarmBasicsModel? initialData;
  final Function(FarmBasicsModel) onSave;

  const FarmBasicsScreen({super.key, this.initialData, required this.onSave});

  @override
  State<FarmBasicsScreen> createState() => _FarmBasicsScreenState();
}

class _FarmBasicsScreenState extends State<FarmBasicsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Location data
  LocationModel? _location;
  String _displayAddress = '';

  // Manual address entry controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isGeocodingAddress = false;

  // Farm size
  final _landSizeController = TextEditingController();
  String _landSizeUnit = 'Acres';

  // Multiple crops selection
  final List<String> _selectedCrops = [];

  // Available crops for selection
  final List<String> _availableCrops = [
    'Rice',
    'Maize',
    'Finger Millet / Ragi',
    'Wheat',
    'Pulses',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _location = widget.initialData!.location;
      _landSizeController.text = widget.initialData!.landSize.toString();
      _landSizeUnit = widget.initialData!.landSizeUnit;
      // Only add crops that are in the available crops list
      final validCrops = widget.initialData!.crops
          .where((crop) => _availableCrops.contains(crop))
          .toList();
      _selectedCrops.addAll(validCrops);
      _updateDisplayAddress();
      _populateAddressFields();
    }
  }

  void _populateAddressFields() async {
    if (_location == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _location!.latitude,
        _location!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _addressController.text = place.street ?? '';
          _cityController.text =
              place.subAdministrativeArea ?? place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _pincodeController.text = place.postalCode ?? '';
        });
      }
    } catch (e) {
      print('Error populating address fields: $e');
    }
  }

  void _updateDisplayAddress() async {
    if (_location == null) return;

    // Show state and district if available
    if (_location!.state != null && _location!.district != null) {
      setState(() {
        _displayAddress = '${_location!.district}, ${_location!.state}';
      });
    } else {
      // Fallback to reverse geocoding
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _location!.latitude,
          _location!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _displayAddress =
                '${place.subAdministrativeArea ?? place.locality}, ${place.administrativeArea}';
          });
        }
      } catch (e) {
        setState(() {
          _displayAddress = 'Location selected';
        });
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _location?.latitude,
          initialLongitude: _location?.longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _location = LocationModel(
          latitude: result.coordinates.latitude,
          longitude: result.coordinates.longitude,
          state: result.state,
          district: result.district,
          plusCode: result.plusCode,
        );
        // Update manual address fields if available
        if (result.address != null) _addressController.text = result.address!;
        if (result.city != null) _cityController.text = result.city!;
        if (result.state != null) _stateController.text = result.state!;
        if (result.pincode != null) _pincodeController.text = result.pincode!;
      });
      _updateDisplayAddress();
    }
  }

  Future<void> _findLocationFromAddress() async {
    // Build complete address string
    String fullAddress = '';
    if (_addressController.text.isNotEmpty) {
      fullAddress += _addressController.text;
    }
    if (_cityController.text.isNotEmpty) {
      fullAddress += ', ${_cityController.text}';
    }
    if (_stateController.text.isNotEmpty) {
      fullAddress += ', ${_stateController.text}';
    }
    if (_pincodeController.text.isNotEmpty) {
      fullAddress += ' ${_pincodeController.text}';
    }

    if (fullAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one address field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeocodingAddress = true;
    });

    try {
      List<Location> locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        final location = locations.first;

        // Generate Plus Code (full precision)
        final plusCode = olc.PlusCode.encode(
          olc.LatLng(location.latitude, location.longitude),
          codeLength: 11,
        );

        setState(() {
          _location = LocationModel(
            latitude: location.latitude,
            longitude: location.longitude,
            state: _stateController.text.isNotEmpty
                ? _stateController.text
                : null,
            district: _cityController.text.isNotEmpty
                ? _cityController.text
                : null,
            plusCode: plusCode.toString(),
          );
          _isGeocodingAddress = false;
        });
        _updateDisplayAddress();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location found! Tap the map card to view'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeocodingAddress = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Could not find location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveData() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select farm location on map'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one crop'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final farmBasics = FarmBasicsModel(
      landSize: double.parse(_landSizeController.text),
      landSizeUnit: _landSizeUnit,
      location: _location!,
      crops: _selectedCrops,
    );

    widget.onSave(farmBasics);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),

            // Section: Farm Location
            _buildSectionTitle('📍 Farm Location'),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: _openMapPicker,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _location == null
                            ? Icons.location_off
                            : Icons.location_on,
                        color: _location == null
                            ? Colors.grey
                            : const Color(0xFF2D5016),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _location == null
                                  ? 'Select Location'
                                  : 'Location Selected',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_location?.plusCode != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.grid_4x4,
                                    size: 14,
                                    color: Color(0xFF2D5016),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _location!.plusCode!,
                                    style: const TextStyle(
                                      color: Color(0xFF2D5016),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_displayAddress.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _displayAddress,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade400)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade400)),
              ],
            ),
            const SizedBox(height: 16),

            // Manual Address Entry Section
            Text(
              'Enter Address Manually',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // Address field
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Street Address (Optional)',
                hintText: 'e.g., Village/Colony name',
                prefixIcon: const Icon(Icons.home, color: Color(0xFF2D5016)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D5016),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // City/District field
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City/District',
                hintText: 'e.g., Pune',
                prefixIcon: const Icon(
                  Icons.location_city,
                  color: Color(0xFF2D5016),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D5016),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // State field
            TextFormField(
              controller: _stateController,
              decoration: InputDecoration(
                labelText: 'State',
                hintText: 'e.g., Maharashtra',
                prefixIcon: const Icon(Icons.map, color: Color(0xFF2D5016)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D5016),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Pincode field
            TextFormField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Pincode',
                hintText: 'e.g., 411001',
                prefixIcon: const Icon(
                  Icons.pin_drop,
                  color: Color(0xFF2D5016),
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D5016),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Find Location from Address button
            OutlinedButton.icon(
              onPressed: _isGeocodingAddress ? null : _findLocationFromAddress,
              icon: _isGeocodingAddress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2D5016),
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                _isGeocodingAddress
                    ? 'Finding Location...'
                    : 'Find Location from Address',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D5016),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF2D5016)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Farm Size
            _buildSectionTitle('📏 Farm Size'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _landSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Area',
                      prefixIcon: const Icon(
                        Icons.landscape,
                        color: Color(0xFF2D5016),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2D5016),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _landSizeUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2D5016),
                          width: 2,
                        ),
                      ),
                    ),
                    items: ['Acres', 'Cents']
                        .map(
                          (unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _landSizeUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Crop Selection (Multiple)
            _buildSectionTitle('🌾 Crops Grown'),
            const SizedBox(height: 8),
            Text(
              'Select all crops you grow on this farm',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Selected crops display
            if (_selectedCrops.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedCrops.map((crop) {
                  return Chip(
                    label: Text(crop),
                    backgroundColor: const Color(0xFF2D5016).withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF2D5016),
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF2D5016),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedCrops.remove(crop);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Add crop dropdown
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Row(
                      children: [
                        const Icon(Icons.add, color: Color(0xFF2D5016)),
                        const SizedBox(width: 12),
                        Text(
                          _selectedCrops.isEmpty
                              ? 'Select crops'
                              : 'Add another crop',
                          style: const TextStyle(
                            color: Color(0xFF2D5016),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    items: _availableCrops
                        .where((crop) => !_selectedCrops.contains(crop))
                        .map(
                          (crop) =>
                              DropdownMenuItem(value: crop, child: Text(crop)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCrops.add(value);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next: Soil Quality →',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/main');
                  },
                  child: Text(
                    'Set Profile Later',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D5016),
      ),
    );
  }

  @override
  void dispose() {
    _landSizeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
