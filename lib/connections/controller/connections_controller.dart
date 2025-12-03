import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/farmer_model.dart';

class ConnectionsController extends ChangeNotifier {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  FarmerProfile? _selectedFarmer;
  List<FarmerProfile> _farmers = [];
  FarmerProfile? _currentUser;

  // Getters
  GoogleMapController? get mapController => _mapController;
  Set<Marker> get markers => _markers;
  FarmerProfile? get selectedFarmer => _selectedFarmer;
  List<FarmerProfile> get farmers => _farmers;
  FarmerProfile? get currentUser => _currentUser;

  ConnectionsController() {
    _loadStaticData();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  void _loadStaticData() {
    // Current user data
    _currentUser = FarmerProfile(
      id: 'user_1',
      name: 'Sam Anderson',
      phoneNumber: '9003854088',
      phoneVisible: true,
      latitude: 13.0827,
      longitude: 80.2707,
      exactLocationVisible: true,
      village: 'Chennai',
      district: 'Chennai',
      currentCrop: 'Rice',
      soilHealthStatus: 'Good',
      irrigationMethod: 'Drip Irrigation',
      riskAlerts: [],
      latestPrediction: CropPredictionData(
        estimatedYield: 5.2,
        growthPhase: 'Flowering',
        weatherRisk: 'Low',
        predictionDate: DateTime.now(),
      ),
      isFollowing: false,
    );

    // Static farmers data (sample)
    _farmers = [
      _currentUser!,
      FarmerProfile(
        id: 'farmer_2',
        name: 'Rajesh Kumar',
        phoneNumber: '9876543210',
        phoneVisible: true,
        latitude: 13.1067,
        longitude: 80.2897,
        village: 'Poonamallee',
        district: 'Chennai',
        currentCrop: 'Wheat',
        soilHealthStatus: 'Excellent',
        irrigationMethod: 'Sprinkler',
        riskAlerts: [],
        latestPrediction: CropPredictionData(
          estimatedYield: 4.8,
          growthPhase: 'Vegetative',
          weatherRisk: 'Medium',
          predictionDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ),
      FarmerProfile(
        id: 'farmer_3',
        name: 'Priya Devi',
        phoneNumber: '9123456789',
        phoneVisible: false,
        latitude: 13.0527,
        longitude: 80.2507,
        village: 'Tambaram',
        district: 'Chennai',
        currentCrop: 'Cotton',
        soilHealthStatus: 'Fair',
        irrigationMethod: 'Flood Irrigation',
        riskAlerts: ['Pest Alert: Bollworm detected in nearby fields'],
        latestPrediction: CropPredictionData(
          estimatedYield: 3.5,
          growthPhase: 'Fruiting',
          weatherRisk: 'High',
          predictionDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ),
      FarmerProfile(
        id: 'farmer_4',
        name: 'Murugan S',
        phoneNumber: '9988776655',
        phoneVisible: true,
        latitude: 13.1127,
        longitude: 80.2107,
        village: 'Avadi',
        district: 'Chennai',
        currentCrop: 'Sugarcane',
        soilHealthStatus: 'Good',
        irrigationMethod: 'Drip Irrigation',
        riskAlerts: ['Disease Alert: Red rot detected'],
        latestPrediction: CropPredictionData(
          estimatedYield: 68.5,
          growthPhase: 'Grand Growth',
          weatherRisk: 'Low',
          predictionDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ),
      FarmerProfile(
        id: 'farmer_5',
        name: 'Lakshmi Narayanan',
        phoneNumber: '9445566778',
        phoneVisible: true,
        latitude: 13.0427,
        longitude: 80.2207,
        village: 'Pallavaram',
        district: 'Chennai',
        currentCrop: 'Maize',
        soilHealthStatus: 'Excellent',
        irrigationMethod: 'Rain-fed',
        riskAlerts: [],
        latestPrediction: CropPredictionData(
          estimatedYield: 6.2,
          growthPhase: 'Maturity',
          weatherRisk: 'Low',
          predictionDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ),
    ];

    _createMarkers();
  }

  void _createMarkers() {
    _markers = _farmers.map((farmer) {
      final isCurrentUser = farmer.id == _currentUser?.id;
      return Marker(
        markerId: MarkerId(farmer.id),
        position: LatLng(farmer.latitude, farmer.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isCurrentUser ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(title: farmer.name, snippet: farmer.currentCrop),
        onTap: () => selectFarmer(farmer),
      );
    }).toSet();
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
