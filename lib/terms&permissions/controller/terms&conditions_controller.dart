import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/terms&conditions_model.dart';

class TermsConditionsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save terms acceptance to Firestore
  Future<Map<String, dynamic>> acceptTerms() async {
    try {
      // 1. Cache locally FIRST (Critical for offline/persistence)
      // 1. Cache locally FIRST (Critical for offline/persistence)
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool('terms_accepted', true);
      debugPrint('DEBUG: Saved T&C to local prefs: $success');

      final user = _auth.currentUser;
      if (user != null) {
          // 2. Try to sync with Firestore (Best effort)
          try {
            final termsModel = TermsConditionsModel(
              isAccepted: true,
              acceptedAt: DateTime.now(),
              userId: user.uid,
            );
            await _firestore.collection('users').doc(user.uid).set({
              'onboarding': {'termsAccepted': termsModel.toJson()},
            }, SetOptions(merge: true));
          } catch (e) {
            print('Warning: Failed to sync terms to Firestore: $e');
            // We suppress this error because local acceptance is enough for access
          }
      }

      return {'success': true, 'message': 'Terms accepted successfully'};
    } catch (e) {
      // Even if something crashes, try to save locally
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('terms_accepted', true);
        return {'success': true, 'message': 'Terms accepted (Offline mode)'};
      } catch (_) {
         return {'success': false, 'message': 'Error accepting terms: $e'};
      }
    }
  }


  // Check if terms are already accepted
  Future<bool> hasAcceptedTerms() async {
    try {
      // 1. Check local cache FIRST (Fast path)
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force reload from disk
      final localStatus = prefs.getBool('terms_accepted');
      debugPrint('DEBUG: T&C Local Prefs: $localStatus');
      
      if (localStatus == true) {
        debugPrint('DEBUG: Terms accepted locally.');
        return true;
      }

      final user = _auth.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in');
        return false;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('DEBUG: User document does not exist');
        return false;
      }

      final data = doc.data();
      if (data == null) {
        print('DEBUG: User document data is null');
        return false;
      }

      print('DEBUG: User document data: $data');

      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      if (onboarding == null) {
        print('DEBUG: Onboarding data is null - user has not accepted terms');
        return false;
      }

      final termsData = onboarding['termsAccepted'] as Map<String, dynamic>?;
      if (termsData == null) {
        print('DEBUG: Terms data is null');
        return false;
      }

      final isAccepted = termsData['isAccepted'] ?? false;
      print('DEBUG: Terms accepted status: $isAccepted');
      
      // Update cache if true
      if (isAccepted) {
        await prefs.setBool('terms_accepted', true);
      }
      return isAccepted;
    } catch (e) {
      print('DEBUG: Error checking terms: $e');
      return false;
    }
  }
}

class PermissionsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request gallery/photos permission
  Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // Request all permissions
  Future<PermissionsModel> requestAllPermissions() async {
    final location = await requestLocationPermission();
    final camera = await requestCameraPermission();
    final gallery = await requestGalleryPermission();

    return PermissionsModel(
      locationGranted: location,
      cameraGranted: camera,
      galleryGranted: gallery,
      grantedAt: DateTime.now(),
    );
  }

  // Check permission status
  Future<Map<String, bool>> checkPermissionStatus() async {
    return {
      'location': await Permission.location.isGranted,
      'camera': await Permission.camera.isGranted,
      'gallery': await Permission.photos.isGranted,
    };
  }

  // Save permissions to Firestore
  Future<Map<String, dynamic>> savePermissions(
    PermissionsModel permissions,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Use set with merge to create the field if it doesn't exist
      await _firestore.collection('users').doc(user.uid).set({
        'onboarding': {'permissionsGranted': permissions.toJson()},
      }, SetOptions(merge: true));

      return {'success': true, 'message': 'Permissions saved successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error saving permissions: $e'};
    }
  }

  // Check if permissions are already granted
  Future<bool> hasGrantedPermissions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) return false;

      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      if (onboarding == null) return false;

      final permData =
          onboarding['permissionsGranted'] as Map<String, dynamic>?;
      if (permData == null) return false;

      return permData['locationGranted'] == true &&
          permData['cameraGranted'] == true &&
          permData['galleryGranted'] == true;
    } catch (e) {
      return false;
    }
  }
}
