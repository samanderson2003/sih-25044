// profile_view.dart (UPDATED)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../controller/profile_controller.dart';
import '../controller/farm_plot_controller.dart';
import '../../prior_data/view/simplified_data_collection_flow.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../providers/language_provider.dart';
import '../../constants/languages.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/farm_plot_visualization.dart';
import '../../models/farm_plot_model.dart';
import 'farm_plot_editor_screen.dart';
import '../controller/cattle_controller.dart';
import '../model/cattle_model.dart';
import 'add_cattle_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _controller = ProfileController();
  final _farmDataController = FarmDataController();
  final _farmPlotController = FarmPlotController();
  final _cattleController = CattleController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

  // Controllers for personal info
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _savePersonalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await _controller.updateProfile(
      displayName: _nameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _controller.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Profile'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),

      body: user == null
          ? const Center(child: TranslatedText('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: _controller.getUserProfileStream(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                }

                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(
                    child: TranslatedText('No profile data found'),
                  );
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final displayName = userData['displayName'] ?? '';
                final mobileNumber = userData['mobileNumber'] ?? '';
                // ignore: unused_local_variable
                final email = userData['email'] ?? '';

                if (!_isEditing) {
                  _nameController.text = displayName;
                  _mobileController.text = mobileNumber;
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: _controller.getFarmDataStream(),
                  builder: (context, farmSnapshot) {
                    final farmData =
                        farmSnapshot.hasData && farmSnapshot.data!.exists
                            ? farmSnapshot.data!.data() as Map<String, dynamic>
                            : null;
                    final hasFarmData = farmData != null;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture
                            Center(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFF2D5016),
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Personal Information Section
                            const TranslatedText(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D5016),
                              ),
                            ),
                            const SizedBox(height: 15),

                            _buildEditableField(
                              label: 'Name',
                              controller: _nameController,
                              icon: Icons.person,
                              validator: _controller.validateName,
                            ),
                            const SizedBox(height: 15),

                            _buildEditableField(
                              label: 'Mobile Number',
                              controller: _mobileController,
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: _controller.validateMobileNumber,
                            ),

                            const SizedBox(height: 30),

                            // Language Preference Section
                            const TranslatedText(
                              'Language Preference',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D5016),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildLanguageSelector(),

                            const SizedBox(height: 30),

                            // Farm Data Section
                            const TranslatedText(
                              'Farm Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D5016),
                              ),
                            ),
                            const SizedBox(height: 15),

                            if (hasFarmData && farmData != null) ...[
                              if (farmData['landDetails'] != null)
                                _buildFarmInfoCard(
                                  'Land Details',
                                  farmData['landDetails'],
                                  Icons.landscape,
                                ),
                              const SizedBox(height: 15),

                              if (farmData['soilQuality'] != null) ...[
                                // Warning banner for satellite data
                                if (farmData['soilQuality']['dataSource'] ==
                                    'satellite')
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.orange.shade700,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange.shade700,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TranslatedText(
                                                'Using Satellite Data',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              TranslatedText(
                                                'For best crop predictions, please update with actual lab test results',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (farmData['soilQuality']['dataSource'] ==
                                    'satellite')
                                  const SizedBox(height: 15),

                                _buildFarmInfoCard(
                                  'Soil Quality',
                                  farmData['soilQuality'],
                                  Icons.terrain,
                                ),
                              ],
                              const SizedBox(height: 15),

                              if (farmData['cropDetails'] != null)
                                _buildFarmInfoCard(
                                  'Current Crop',
                                  farmData['cropDetails'],
                                  Icons.grass,
                                ),
                              const SizedBox(height: 15),

                              if (farmData['pastData'] != null)
                                _buildFarmInfoCard(
                                  'Past Crop History',
                                  farmData['pastData'],
                                  Icons.history,
                                ),
                              const SizedBox(height: 15),

                              // Farm Plot Visualization Section
                              _buildFarmPlotSection(farmData),
                            ] else
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F6F0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2D5016,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.agriculture,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    TranslatedText(
                                      'No farm data collected yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SimplifiedDataCollectionFlow(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const TranslatedText(
                                        'Add Farm Data',
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF2D5016,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 30),

                            // Livestock Section
                            _buildLivestockSection(),

                            const SizedBox(height: 30),



                            // Action Buttons
                            if (_isEditing) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isSaving
                                          ? null
                                          : () {
                                              setState(() {
                                                _isEditing = false;
                                                _nameController.text =
                                                    displayName;
                                                _mobileController.text =
                                                    mobileNumber;
                                              });
                                            },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF2D5016,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF2D5016),
                                        ),
                                      ),
                                      child: const TranslatedText('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isSaving
                                          ? null
                                          : _savePersonalInfo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2D5016,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const TranslatedText(
                                              'Save Changes',
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                            ],

                            if (hasFarmData)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    // Fetch existing farm data
                                    final existingData =
                                        await _farmDataController.getFarmData();
                                    if (!mounted) return;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SimplifiedDataCollectionFlow(
                                              initialFarmData: existingData,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const TranslatedText(
                                    'Update Farm Data',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2D5016),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF2D5016),
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 15),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _controller.logout();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    );
                                  }
                                },
                                icon: const Icon(Icons.logout),
                                label: const TranslatedText('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    if (!_isEditing) {
      return _buildInfoCard(
        icon: icon,
        label: label,
        value: controller.text.isEmpty ? 'Not set' : controller.text,
        translateLabel: true,
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2D5016), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInfoCard(
    String title,
    Map<String, dynamic> data,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2D5016), size: 20),
              const SizedBox(width: 10),
              TranslatedText(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.entries.map((entry) {
            if (entry.value == null) return const SizedBox.shrink();

            String displayValue;
            if (entry.value is Map) {
              return const SizedBox.shrink();
            } else if (entry.value is List) {
              displayValue = (entry.value as List).join(', ');
            } else {
              displayValue = entry.value.toString();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TranslatedText(
                      _controller.formatFieldName(entry.key),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TranslatedText(
                      displayValue,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.language,
                  color: Color(0xFF2D5016),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'App Language',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: languageProvider.currentLanguage.code,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      items: AppLanguages.supportedLanguages
                          .map(
                            (lang) => DropdownMenuItem(
                              value: lang.code,
                              child: Row(
                                children: [
                                  Text(lang.nativeName),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${lang.name})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (code) async {
                        if (code != null) {
                          final lang = AppLanguages.getLanguageByCode(code);
                          await languageProvider.changeLanguage(lang);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Language changed to ${lang.nativeName}',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool translateLabel = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2D5016), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translateLabel
                    ? TranslatedText(
                        label,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    : Text(
                        label,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D5016),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmPlotSection(Map<String, dynamic> farmData) {
    return StreamBuilder<FarmPlotModel?>(
      stream: _farmPlotController.getFarmPlotStream(),
      builder: (context, plotSnapshot) {
        final hasFarmPlot = plotSnapshot.hasData && plotSnapshot.data != null;
        final farmPlot = plotSnapshot.data;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.grid_on, color: Color(0xFF2D5016), size: 24),
                        SizedBox(width: 8),
                        TranslatedText(
                          'Farm Plot Layout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5016),
                          ),
                        ),
                      ],
                    ),
                    if (hasFarmPlot)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openFarmPlotEditor(farmData),
                        color: const Color(0xFF2D5016),
                        tooltip: 'Edit Farm Plot',
                      ),
                  ],
                ),
              ),

              // Content
              if (hasFarmPlot && farmPlot != null)
                FarmPlotVisualization(farmPlot: farmPlot, showStats: true)
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.grid_4x4,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      TranslatedText(
                        'No farm plot designed yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TranslatedText(
                        'Create a visual layout of your farm with crop assignments',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openFarmPlotEditor(farmData),
                        icon: const Icon(Icons.add),
                        label: const TranslatedText('Create Farm Plot'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5016),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFarmPlotEditor(Map<String, dynamic> farmData) async {
    // Get current farm data from Firestore
    final farmDataModel = await _farmDataController.getFarmData();

    if (farmDataModel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add farm data first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Navigate to farm plot editor
    final result = await Navigator.push<FarmPlotModel>(
      context,
      MaterialPageRoute(
        builder: (context) => FarmPlotEditorScreen(farmData: farmDataModel),
      ),
    );

    // If user saved the farm plot, save it to Firebase
    if (result != null && mounted) {
      final saveResult = await _farmPlotController.saveFarmPlot(result);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saveResult['message']),
          backgroundColor: saveResult['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildLivestockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TranslatedText(
              'Livestock',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5016),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCattleScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFF2D5016)),
              tooltip: 'Add Cattle',
            ),
          ],
        ),
        const SizedBox(height: 15),
        StreamBuilder<List<CattleModel>>(
          stream: _cattleController.getCattleStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF2D5016).withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 10),
                      const TranslatedText(
                        'No livestock added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCattleScreen(),
                            ),
                          );
                        },
                        child: const TranslatedText(
                          'Add your first cattle',
                          style: TextStyle(color: Color(0xFF2D5016)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cattle = snapshot.data![index];
                return _buildCattleCard(cattle);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCattleCard(CattleModel cattle) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cattle.type == 'cow'
                  ? '🐄'
                  : cattle.type == 'goat'
                      ? '🐐'
                      : '🐃',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  cattle.breed,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TranslatedText(
                      cattle.type[0].toUpperCase() + cattle.type.substring(1),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      ' • ${cattle.age} ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    TranslatedText(
                      'years old',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeleteCattle(cattle),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCattle(CattleModel cattle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TranslatedText('Delete Cattle'),
        content: Text('Are you sure you want to delete this ${cattle.breed}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const TranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cattleController.deleteCattle(cattle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cattle deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
