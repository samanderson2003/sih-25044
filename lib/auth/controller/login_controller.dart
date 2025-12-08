// login_controller.dart (UPDATED)
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/login_model.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Utility to check if phone is already registered ---
  Future<bool> isPhoneNumberRegistered(String mobileNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('mobileNumber', isEqualTo: mobileNumber)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone registration: $e');
      return false;
    }
  }

  // --- 1. Send OTP (Modified for Phone Check) ---
  Future<Map<String, dynamic>> sendOtp(String rawMobileNumber) async {
    // --- FIX: Ensure mobile number is trimmed and cleaned here ---
    final mobileNumber = rawMobileNumber.trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // 1. Validation Check (using trimmed/cleaned number)
    final model = LoginModel(mobile: mobileNumber);
    if (model.validateMobile() != null) {
      // Return the error from the model if validation fails
      return {'success': false, 'message': model.validateMobile()!};
    }

    // 2. Login Check: Only send OTP if the user IS registered
    if (!await isPhoneNumberRegistered(mobileNumber)) {
      return {
        'success': false,
        'message': 'No account found with this mobile number. Please sign up.',
      };
    }

    // 3. Proceed with OTP
    String phoneNumber = '+91$mobileNumber';
    String? verificationId;
    final completer = Completer<void>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          print('🔴 Firebase Auth Error Code: ${e.code}');
          print('🔴 Firebase Auth Error Message: ${e.message}');
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String vid, int? token) {
          verificationId = vid;
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (String vid) {
          verificationId = vid;
          if (!completer.isCompleted) completer.complete();
        },
      );
    } on FirebaseAuthException catch (e) {
      // Handle rate limiting and other Firebase errors immediately
      print('🔴 Immediate Firebase Error: ${e.code} - ${e.message}');
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    try {
      await completer.future.timeout(const Duration(seconds: 65));
      if (verificationId != null) {
        return {
          'success': true,
          'message': 'OTP sent successfully!',
          'verificationId': verificationId,
        };
      } else {
        return {'success': false, 'message': 'Failed to get verification ID.'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'OTP sending timed out.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during OTP send.',
      };
    }
  }

  // --- 2. Verify OTP and Log In (Unchanged) ---
  Future<Map<String, dynamic>> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _ensureUserDocument(userCredential.user!);
      }

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'OTP verification failed. Please check the code.',
      };
    }
  }

  // Ensure user document exists in Firestore (for Login)
  Future<void> _ensureUserDocument(User user) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        // Create minimal profile for users authenticated via Phone Auth
        await userDocRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Update last login for existing user
        await userDocRef.update({'lastLogin': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      print("Error ensuring user document: $e");
    }
  }

  // Error message helper
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'session-expired':
        return 'OTP session expired. Please request a new OTP';
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'too-many-requests':
        return 'Too many login attempts detected. Firebase has temporarily blocked this phone number.\n\nPlease wait 1-2 hours before trying again, or use a different phone number.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later or contact support.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'invalid-app-credential':
        return 'App verification failed. This may be due to too many attempts. Please wait and try again.';
      default:
        return 'Authentication error: ${code}\n\nIf you see this repeatedly, Firebase may have rate-limited your device. Please wait 1-2 hours and try again.';
    }
  }
}
