import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controller/terms&conditions_controller.dart';
import '../model/terms&conditions_model.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../prior_data/view/simplified_data_collection_flow.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final PermissionsController _controller = PermissionsController();
  bool _isLoading = false;

  bool _locationGranted = false;
  bool _cameraGranted = false;
  bool _galleryGranted = false;

  // Theme colors
  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  static const textColor = Color(0xFF4A4A4A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes (user returns from settings), recheck permissions
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await _controller.checkPermissionStatus();
    setState(() {
      _locationGranted = status['location'] ?? false;
      _cameraGranted = status['camera'] ?? false;
      _galleryGranted = status['gallery'] ?? false;
    });
  }

  Future<void> _requestPermission(String type) async {
    bool granted = false;

    switch (type) {
      case 'location':
        granted = await _controller.requestLocationPermission();
        setState(() => _locationGranted = granted);
        break;
      case 'camera':
        granted = await _controller.requestCameraPermission();
        setState(() => _cameraGranted = granted);
        break;
      case 'gallery':
        granted = await _controller.requestGalleryPermission();
        setState(() => _galleryGranted = granted);
        break;
    }

    if (mounted) {
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} permission granted'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show dialog to open settings if permission denied
        _showPermissionDeniedDialog(type);
      }
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${permissionType.toUpperCase()} Permission Required'),
        content: Text(
          'This permission is required for the app to function properly. '
          'Please enable it from your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              // Recheck permissions after returning from settings
              await Future.delayed(const Duration(seconds: 1));
              _checkPermissions();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    final permissions = await _controller.requestAllPermissions();

    setState(() {
      _locationGranted = permissions.locationGranted;
      _cameraGranted = permissions.cameraGranted;
      _galleryGranted = permissions.galleryGranted;
      _isLoading = false;
    });

    // Save to Firestore
    await _controller.savePermissions(permissions);

    if (mounted) {
      if (permissions.allGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All permissions granted!'),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Some permissions were not granted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _handleContinue() async {
    // Check if location permission is granted (mandatory)
    if (!_locationGranted) {
      _showLocationRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    final permissions = PermissionsModel(
      locationGranted: _locationGranted,
      cameraGranted: _cameraGranted,
      galleryGranted: _galleryGranted,
      grantedAt: DateTime.now(),
    );

    await _controller.savePermissions(permissions);

    setState(() => _isLoading = false);

    _navigateToHome();
  }

  void _showLocationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Location Required'),
          ],
        ),
        content: const Text(
          'Location permission is mandatory for this app to provide:\n\n'
          '• Accurate weather data for your farm\n'
          '• Nearby soil testing centers\n'
          '• Location-based crop recommendations\n\n'
          'Please grant location permission to continue.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              _requestPermission('location');
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() async {
    // Check if farm data is complete
    final farmDataController = FarmDataController();
    final isFarmDataComplete = await farmDataController.isFarmDataComplete();

    if (!mounted) return;

    if (!isFarmDataComplete) {
      // Farm data not complete - go to data collection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SimplifiedDataCollectionFlow(),
        ),
      );
    } else {
      // All good - go to main screen
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('App Permissions'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'We need a few permissions to provide the best experience',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location Permission Card (MANDATORY)
                  _buildPermissionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Location Access (Required)',
                    description:
                        'To fetch accurate weather data for your area and help you find nearby soil testing centers',
                    isGranted: _locationGranted,
                    isMandatory: true,
                    onTap: () => _requestPermission('location'),
                  ),
                  const SizedBox(height: 16),

                  // Camera Permission Card
                  _buildPermissionCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Camera Access',
                    description:
                        'To capture photos of your crops and upload soil test reports',
                    isGranted: _cameraGranted,
                    onTap: () => _requestPermission('camera'),
                  ),
                  const SizedBox(height: 16),

                  // Gallery Permission Card
                  _buildPermissionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Gallery Access',
                    description:
                        'To select existing photos and documents from your device',
                    isGranted: _galleryGranted,
                    onTap: () => _requestPermission('gallery'),
                  ),
                  const SizedBox(height: 24),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can change these permissions anytime from your device settings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
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

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grant All Permissions button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestAllPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
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
                            'Grant All Permissions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Continue button (requires location permission)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    child: Text(
                      _locationGranted
                          ? 'Continue to Dashboard'
                          : 'Continue Without Permissions',
                      style: TextStyle(
                        fontSize: 14,
                        color: _locationGranted ? primaryColor : textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
    bool isMandatory = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? Colors.green.shade200
              : (isMandatory ? Colors.orange.shade200 : Colors.grey.shade200),
          width: isMandatory && !isGranted ? 2.0 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGranted ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? Colors.green.shade50
                            : (isMandatory
                                  ? Colors.orange.shade50
                                  : primaryColor.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: isGranted
                            ? Colors.green.shade700
                            : (isMandatory
                                  ? Colors.orange.shade700
                                  : primaryColor),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              if (isMandatory && !isGranted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'REQUIRED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withOpacity(0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Status icon
                    Icon(
                      isGranted ? Icons.check_circle : Icons.arrow_forward_ios,
                      color: isGranted ? Colors.green.shade700 : Colors.grey,
                      size: isGranted ? 24 : 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
