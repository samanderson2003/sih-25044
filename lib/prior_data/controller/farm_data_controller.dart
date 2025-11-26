import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../model/farm_data_model.dart';

class FarmDataController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save farm data to Firestore
  Future<Map<String, dynamic>> saveFarmData(FarmDataModel farmData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _firestore
          .collection('farmData')
          .doc(user.uid)
          .set(farmData.toJson(), SetOptions(merge: true));

      // Also update user's profile completion status
      await _firestore.collection('users').doc(user.uid).set({
        'profileCompleted': true,
        'farmDataCollected': true,
      }, SetOptions(merge: true));

      return {'success': true, 'message': 'Farm data saved successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error saving farm data: $e'};
    }
  }

  // Get farm data from Firestore
  Future<FarmDataModel?> getFarmData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('farmData').doc(user.uid).get();
      if (!doc.exists) return null;

      return FarmDataModel.fromJson(doc.data()!);
    } catch (e) {
      print('Error fetching farm data: $e');
      return null;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied ||
          hasPermission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get nearby soil test centers (mock data for now - can be replaced with real API)
  Future<List<SoilTestCenter>> getNearbyTestCenters(
    double latitude,
    double longitude,
  ) async {
    // Mock data - replace with actual API call
    final mockCenters = [
      SoilTestCenter(
        name: 'Government Soil Testing Laboratory',
        address: 'Agriculture Department, District Office',
        latitude: latitude + 0.01,
        longitude: longitude + 0.01,
        distance: _calculateDistance(
          latitude,
          longitude,
          latitude + 0.01,
          longitude + 0.01,
        ),
        phone: '+91-1234567890',
        timing: '9:00 AM - 5:00 PM (Mon-Fri)',
      ),
      SoilTestCenter(
        name: 'Krishi Vigyan Kendra',
        address: 'Agricultural University Campus',
        latitude: latitude + 0.02,
        longitude: longitude - 0.01,
        distance: _calculateDistance(
          latitude,
          longitude,
          latitude + 0.02,
          longitude - 0.01,
        ),
        phone: '+91-0987654321',
        timing: '8:00 AM - 4:00 PM (Mon-Sat)',
      ),
      SoilTestCenter(
        name: 'Private Agri-Testing Center',
        address: 'Main Road, Near Market',
        latitude: latitude - 0.01,
        longitude: longitude + 0.02,
        distance: _calculateDistance(
          latitude,
          longitude,
          latitude - 0.01,
          longitude + 0.02,
        ),
        phone: '+91-5555555555',
        timing: '10:00 AM - 6:00 PM (All days)',
      ),
    ];

    // Sort by distance
    mockCenters.sort((a, b) => a.distance.compareTo(b.distance));
    return mockCenters;
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Get soil data from satellite API (mock - replace with real API)
  Future<SoilQualityModel?> getSoilDataFromSatellite(
    double latitude,
    double longitude,
  ) async {
    try {
      // Mock satellite data - replace with actual API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Return estimated soil data with disclaimer
      return SoilQualityModel(
        zinc: 0.5 + (latitude % 1) * 2, // Mock values
        iron: 3.5 + (longitude % 1) * 2,
        copper: 1.2 + (latitude % 1),
        manganese: 2.8 + (longitude % 1) * 1.5,
        boron: 0.8 + (latitude % 1) * 0.5,
        sulfur: 12.5 + (longitude % 1) * 5,
        soilType: 'Loamy',
        ph: 6.5 + (latitude % 1),
        organicCarbon: 0.5 + (longitude % 1) * 0.3,
        nitrogen: 220 + (latitude % 1) * 50,
        phosphorus: 18 + (longitude % 1) * 10,
        potassium: 180 + (latitude % 1) * 40,
        dataSource: 'satellite',
        isAccurate: false,
        testDate: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching satellite data: $e');
      return null;
    }
  }

  // Check if farm data collection is complete
  Future<bool> isFarmDataComplete() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      return userData?['farmDataCollected'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
