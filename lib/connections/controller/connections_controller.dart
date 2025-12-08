import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/farmer_model.dart';
import '../../services/sentinel_hub_service.dart';

class ConnectionsController extends ChangeNotifier {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  FarmerProfile? _selectedFarmer;
  List<FarmerProfile> _farmers = [];
  FarmerProfile? _currentUser;
  BitmapDescriptor? _farmerIcon;
  BitmapDescriptor? _myFarmIcon;
  BitmapDescriptor? _diseaseIcon; // Red marker for diseased crops
  bool _isLoading = true;
  String? _error;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SentinelHubService _sentinelService = SentinelHubService();

  // Getters
  GoogleMapController? get mapController => _mapController;
  Set<Marker> get markers => _markers;
  FarmerProfile? get selectedFarmer => _selectedFarmer;
  List<FarmerProfile> get farmers => _farmers;
  FarmerProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ConnectionsController() {
    print('\n\n');
    print('╔══════════════════════════════════════════════════════════╗');
    print('║  CONNECTIONS CONTROLLER INITIALIZED                      ║');
    print('╚══════════════════════════════════════════════════════════╝');
    print('\n');
    _loadCustomMarkerIcon();
    _loadFarmersFromFirebase();
  }

  Future<void> _loadCustomMarkerIcon() async {
    print('📌 Loading custom marker icons...');
    // Load farmer icon
    final ByteData farmerData = await rootBundle.load('assets/pin.png');
    final ui.Codec farmerCodec = await ui.instantiateImageCodec(
      farmerData.buffer.asUint8List(),
      targetWidth: 120,
    );
    final ui.FrameInfo farmerFi = await farmerCodec.getNextFrame();
    final ByteData? farmerByteData = await farmerFi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List farmerResizedData = farmerByteData!.buffer.asUint8List();
    _farmerIcon = BitmapDescriptor.fromBytes(farmerResizedData);

    // Load myfarm icon
    final ByteData myFarmData = await rootBundle.load(
      'assets/farm-location.png',
    );
    final ui.Codec myFarmCodec = await ui.instantiateImageCodec(
      myFarmData.buffer.asUint8List(),
      targetWidth: 120,
    );
    final ui.FrameInfo myFarmFi = await myFarmCodec.getNextFrame();
    final ByteData? myFarmByteData = await myFarmFi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List myFarmResizedData = myFarmByteData!.buffer.asUint8List();
    _myFarmIcon = BitmapDescriptor.fromBytes(myFarmResizedData);

    // Create red disease marker icon
    _diseaseIcon = await _createColoredMarker(Colors.red);

    _createMarkers(); // Create markers after icons are loaded
  }

  /// Create a colored marker icon programmatically
  Future<BitmapDescriptor> _createColoredMarker(Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw marker pin shape
    const double markerSize = 80;
    const double pinHeight = 100;

    // Draw circle (top part of pin)
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      markerSize / 2,
      paint,
    );

    // Draw triangle (bottom pointer)
    final path = Path();
    path.moveTo(markerSize / 2, pinHeight);
    path.lineTo(markerSize * 0.2, markerSize / 2);
    path.lineTo(markerSize * 0.8, markerSize / 2);
    path.close();
    canvas.drawPath(path, paint);

    // Draw white border
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      markerSize / 2,
      paint,
    );
    canvas.drawPath(path, paint);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(markerSize.toInt(), pinHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  /// Load all farmers from Firebase Firestore
  Future<void> _loadFarmersFromFirebase() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('========================================');
      print('🔍 STARTING FIREBASE FETCH');
      print('========================================');

      final currentUserId = _auth.currentUser?.uid;
      print('👤 Current user ID: $currentUserId');

      // Fetch all farm data from Firestore
      print('📡 Querying farmData collection...');
      final QuerySnapshot snapshot = await _firestore
          .collection('farmData')
          .get();

      print('========================================');
      print('📊 FOUND ${snapshot.docs.length} FARM DOCUMENTS');
      print('========================================');

      _farmers = [];
      int validFarmers = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('📋 DOCUMENT ID: ${doc.id}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('🔑 Keys in document: ${data.keys.toList()}');

          // Get farmBasics first - it contains location!
          print('\n🌾 FARM BASICS CHECK:');
          final farmBasics = data['farmBasics'] as Map<String, dynamic>?;
          if (farmBasics == null) {
            print('❌ farmBasics IS NULL!');
            print('📦 Full document data: $data');
            continue;
          }
          print('✅ farmBasics exists');
          print('🔑 farmBasics keys: ${farmBasics.keys.toList()}');

          // Location is INSIDE farmBasics!
          print('\n📍 LOCATION CHECK:');
          final location = farmBasics['location'] as Map<String, dynamic>?;
          if (location == null) {
            print('❌ LOCATION IS NULL inside farmBasics!');
            print('📦 farmBasics data: $farmBasics');
            continue;
          }
          print('✅ Location object exists');
          print('📍 Location keys: ${location.keys.toList()}');
          print('📍 Location data: $location');

          // Check latitude and longitude
          print('\n🌐 COORDINATES CHECK:');
          final latitude = location['latitude'];
          final longitude = location['longitude'];
          print('   Latitude (raw): $latitude (type: ${latitude.runtimeType})');
          print(
            '   Longitude (raw): $longitude (type: ${longitude.runtimeType})',
          );

          if (latitude == null || longitude == null) {
            print('❌ MISSING COORDINATES!');
            continue;
          }

          final lat = (latitude as num).toDouble();
          final lng = (longitude as num).toDouble();
          print('✅ Valid coordinates: ($lat, $lng)');

          // Get crops from farmBasics
          final crops = farmBasics['crops'] as List<dynamic>?;
          print('\n🌾 Crops: ${crops ?? "NULL"}');

          String currentCrop = 'Not Specified';
          if (crops != null && crops.isNotEmpty) {
            currentCrop = crops.join(', ');
          }
          print(
            '🌾 Final crop value: $currentCrop',
          ); // Get user name from users collection
          print('\n👤 USER INFO CHECK:');
          String userName = 'Farmer ${doc.id.substring(0, 6)}';
          String phoneNumber = 'N/A';

          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(doc.id)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              userName =
                  userData?['name'] ?? userData?['displayName'] ?? userName;
              phoneNumber = userData?['phoneNumber'] ?? phoneNumber;
              print('✅ Found user: $userName');
            } else {
              print('⚠️ User document does not exist');
            }
          } catch (e) {
            print('⚠️ Error fetching user data: $e');
          }

          // Extract soil quality
          print('\n🌱 SOIL QUALITY CHECK:');
          final soilQuality = data['soilQuality'] as Map<String, dynamic>?;
          if (soilQuality == null) {
            print('⚠️ soilQuality is NULL');
          } else {
            print('✅ soilQuality exists: $soilQuality');
          }

          final boron = soilQuality?['boron'] as num? ?? 0;
          final copper = soilQuality?['copper'] as num? ?? 0;
          final iron = soilQuality?['iron'] as num? ?? 0;
          final manganese = soilQuality?['manganese'] as num? ?? 0;
          final zinc = soilQuality?['zinc'] as num? ?? 0;

          String soilHealthStatus = _calculateSoilHealth(
            boron.toDouble(),
            copper.toDouble(),
            iron.toDouble(),
            manganese.toDouble(),
            zinc.toDouble(),
          );
          print('🌱 Soil health status: $soilHealthStatus');

          final district =
              location['district'] ?? location['state'] ?? 'Unknown';
          print('🏘️ District: $district');

          // Get irrigation method
          final irrigation =
              farmBasics['irrigation'] ?? data['irrigation'] ?? 'Not Specified';
          print('💧 Irrigation: $irrigation');

          // Generate risk alerts
          List<String> riskAlerts = _generateRiskAlerts(soilQuality);
          print('⚠️ Risk alerts: ${riskAlerts.length} alerts');

          // Analyze satellite data for crop health monitoring
          print('\n🛰️ CROP HEALTH ANALYSIS (Multi-Index):');
          Map<String, dynamic>? healthAnalysis;
          try {
            healthAnalysis = await _sentinelService.analyzeVegetationHealth(
              latitude: lat,
              longitude: lng,
              bufferKm: 0.5,
            );
            print('✅ Health analysis complete:');
            print(
              '   📊 NDVI: ${healthAnalysis['ndvi_mean']?.toStringAsFixed(3)} (Biomass)',
            );
            print(
              '   🌿 NDRE: ${healthAnalysis['ndre_mean']?.toStringAsFixed(3)} (Chlorophyll)',
            );
            print(
              '   💧 NDWI: ${healthAnalysis['ndwi_mean']?.toStringAsFixed(3)} (Water)',
            );
            print(
              '   🌾 SAVI: ${healthAnalysis['savi_mean']?.toStringAsFixed(3)} (Soil-Adjusted)',
            );
            print('   Status: ${healthAnalysis['health_status']}');
            print('   Stress Type: ${healthAnalysis['stress_type']}');
            print('   Stress Detected: ${healthAnalysis['stress_detected']}');
            print(
              '   Confidence: ${(healthAnalysis['confidence'] * 100).toStringAsFixed(1)}%',
            );
          } catch (e) {
            print('⚠️ Satellite analysis failed: $e');
            healthAnalysis = null;
          }

          // Create farmer profile
          print('\n✅ CREATING FARMER PROFILE...');
          final farmerProfile = FarmerProfile(
            id: doc.id,
            name: userName,
            phoneNumber: phoneNumber,
            phoneVisible: data['phoneVisible'] ?? false,
            latitude: lat,
            longitude: lng,
            exactLocationVisible: data['exactLocationVisible'] ?? true,
            village: location['plusCode'] ?? '',
            district: district,
            currentCrop: currentCrop,
            soilHealthStatus: soilHealthStatus,
            irrigationMethod: irrigation,
            riskAlerts: riskAlerts,
            latestPrediction: null,
            profileImage: data['profileImage'],
            isFollowing: false,
            stressDetected: healthAnalysis?['stress_detected'],
            healthStatus: healthAnalysis?['health_status'],
            stressType: healthAnalysis?['stress_type'],
            confidence: healthAnalysis?['confidence']?.toDouble(),
            ndviMean: healthAnalysis?['ndvi_mean']?.toDouble(),
            ndreMean: healthAnalysis?['ndre_mean']?.toDouble(),
            ndwiMean: healthAnalysis?['ndwi_mean']?.toDouble(),
            saviMean: healthAnalysis?['savi_mean']?.toDouble(),
            healthIndicators: healthAnalysis?['indicators'] != null
                ? List<String>.from(healthAnalysis!['indicators'])
                : null,
            recommendations: healthAnalysis?['recommendations'] != null
                ? List<String>.from(healthAnalysis!['recommendations'])
                : null,
            disclaimer: healthAnalysis?['disclaimer'],
          );

          _farmers.add(farmerProfile);
          validFarmers++;
          print('✅ SUCCESSFULLY ADDED FARMER: $userName');
          print('   Position: ($lat, $lng)');

          // Set current user
          if (doc.id == currentUserId) {
            _currentUser = farmerProfile;
            print('🏠 SET AS CURRENT USER');
          }
        } catch (e, stackTrace) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('❌ ERROR PROCESSING DOCUMENT: ${doc.id}');
          print('❌ Error: $e');
          print('❌ Stack trace: $stackTrace');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
      }

      print('\n========================================');
      print('✅ SUCCESSFULLY LOADED $validFarmers FARMERS');
      print('📍 Total farmers in list: ${_farmers.length}');
      print('👤 Current user: ${_currentUser?.name ?? "Not found"}');
      print('========================================');

      _isLoading = false;
      _createMarkers();

      // Move camera to current user location if available
      if (_currentUser != null && _mapController != null) {
        print('📷 Moving camera to current user location');
        moveToLocation(_currentUser!.latitude, _currentUser!.longitude);
      } else if (_farmers.isNotEmpty && _mapController != null) {
        print('📷 Moving camera to first farmer');
        moveToLocation(_farmers.first.latitude, _farmers.first.longitude);
      }
    } catch (e, stackTrace) {
      _error = 'Failed to load farmers: $e';
      _isLoading = false;
      print('========================================');
      print('❌ FATAL ERROR LOADING FARMERS');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      print('========================================');
      notifyListeners();
    }
  }

  /// Calculate soil health status based on nutrient levels
  String _calculateSoilHealth(
    double boron,
    double copper,
    double iron,
    double manganese,
    double zinc,
  ) {
    final avgNutrient = (boron + copper + iron + manganese + zinc) / 5;

    if (avgNutrient >= 85) {
      return 'Excellent';
    } else if (avgNutrient >= 70) {
      return 'Good';
    } else if (avgNutrient >= 50) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  /// Generate risk alerts based on soil quality
  List<String> _generateRiskAlerts(Map<String, dynamic>? soilQuality) {
    if (soilQuality == null) return [];

    List<String> alerts = [];

    final boron = (soilQuality['boron'] as num?)?.toDouble() ?? 0;
    final copper = (soilQuality['copper'] as num?)?.toDouble() ?? 0;
    final iron = (soilQuality['iron'] as num?)?.toDouble() ?? 0;
    final manganese = (soilQuality['manganese'] as num?)?.toDouble() ?? 0;
    final zinc = (soilQuality['zinc'] as num?)?.toDouble() ?? 0;

    if (zinc < 60) alerts.add('Low Zinc: Apply zinc sulfate fertilizer');
    if (iron < 70) alerts.add('Low Iron: Consider iron chelate application');
    if (boron < 70) alerts.add('Low Boron: Risk of hollow stem in crops');
    if (copper < 70) alerts.add('Low Copper: May affect grain formation');
    if (manganese < 70)
      alerts.add('Low Manganese: Check for leaf discoloration');

    return alerts;
  }

  /// Refresh farmers data from Firebase
  Future<void> refreshFarmers() async {
    await _loadFarmersFromFirebase();
  }

  void _createMarkers() {
    if (_farmerIcon == null || _myFarmIcon == null || _diseaseIcon == null) {
      print('⏳ Marker icons not loaded yet, waiting...');
      return;
    }

    print('\n========================================');
    print('🗺️ CREATING MARKERS');
    print('========================================');
    print('📊 Total farmers to create markers for: ${_farmers.length}');

    _markers = _farmers.map((farmer) {
      final isCurrentUser = farmer.id == _currentUser?.id;
      final hasStressDetected = farmer.stressDetected == true;

      print('📍 Creating marker for: ${farmer.name}');
      print('   Position: (${farmer.latitude}, ${farmer.longitude})');
      print('   Is current user: $isCurrentUser');
      print('   Stress detected: $hasStressDetected');
      print('   Stress type: ${farmer.stressType}');

      // Choose marker icon based on crop health status
      BitmapDescriptor markerIcon;
      if (isCurrentUser) {
        markerIcon = _myFarmIcon!;
      } else if (hasStressDetected) {
        markerIcon = _diseaseIcon!; // Red marker for stressed crops
      } else {
        markerIcon = _farmerIcon!; // Green marker for healthy crops
      }

      // Create snippet based on stress type
      String snippet;
      if (hasStressDetected) {
        switch (farmer.stressType) {
          case 'disease_or_pest':
            snippet = '⚠️ Possible Disease/Pest - ${farmer.currentCrop}';
            break;
          case 'water_stress':
            snippet = '💧 Water Stress - ${farmer.currentCrop}';
            break;
          case 'early_stress':
            snippet = '🔍 Early Stress Signs - ${farmer.currentCrop}';
            break;
          default:
            snippet = '⚠️ Vegetation Stress - ${farmer.currentCrop}';
        }
      } else {
        snippet = farmer.currentCrop;
      }

      return Marker(
        markerId: MarkerId(farmer.id),
        position: LatLng(farmer.latitude, farmer.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(title: farmer.name, snippet: snippet),
        onTap: () => selectFarmer(farmer),
      );
    }).toSet();

    print('========================================');
    print('✅ CREATED ${_markers.length} MARKERS');
    print('========================================\n');
    notifyListeners();
  }

  void selectFarmer(FarmerProfile farmer) {
    _selectedFarmer = farmer;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFarmer = null;
    notifyListeners();
  }

  void toggleFollow(String farmerId) {
    final index = _farmers.indexWhere((f) => f.id == farmerId);
    if (index != -1) {
      final farmer = _farmers[index];
      _farmers[index] = FarmerProfile(
        id: farmer.id,
        name: farmer.name,
        phoneNumber: farmer.phoneNumber,
        phoneVisible: farmer.phoneVisible,
        latitude: farmer.latitude,
        longitude: farmer.longitude,
        exactLocationVisible: farmer.exactLocationVisible,
        village: farmer.village,
        district: farmer.district,
        currentCrop: farmer.currentCrop,
        soilHealthStatus: farmer.soilHealthStatus,
        irrigationMethod: farmer.irrigationMethod,
        riskAlerts: farmer.riskAlerts,
        latestPrediction: farmer.latestPrediction,
        profileImage: farmer.profileImage,
        isFollowing: !farmer.isFollowing,
      );

      if (_selectedFarmer?.id == farmerId) {
        _selectedFarmer = _farmers[index];
      }

      notifyListeners();
    }
  }

  void moveToLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
