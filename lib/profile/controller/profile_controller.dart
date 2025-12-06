// profile_controller.dart (UPDATED)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/profile_model.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user profile stream
  Stream<DocumentSnapshot> getUserProfileStream() {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // Get farm data stream
  Stream<DocumentSnapshot> getFarmDataStream() {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('farmData').doc(user.uid).snapshots();
  }

  // Get user profile
  Future<ProfileModel?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return ProfileModel.fromJson(doc.data()!);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? mobileNumber,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (mobileNumber != null) updateData['mobileNumber'] = mobileNumber;

      if (updateData.isEmpty) {
        return {'success': false, 'message': 'No data to update'};
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error updating profile: $e'};
    }
  }

  // Get farm data
  Future<Map<String, dynamic>?> getFarmData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('farmData').doc(user.uid).get();
      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      print('Error fetching farm data: $e');
      return null;
    }
  }

  // Check if farm data exists
  Future<bool> hasFarmData() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('farmData').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Validate mobile number
  String? validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    // Aggressive cleaning and length check
    final cleanNumber = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length != 10) {
      return 'Mobile number must be 10 digits';
    }
    return null;
  }

  // Validate name
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    // Added validation based on previous request: Only Uppercase, lowercase, and space
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  // Format field names for display
  String formatFieldName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}