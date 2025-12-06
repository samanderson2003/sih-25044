// register_controller.dart
import 'dart:async'; // <--- ADDED IMPORT
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/register_model.dart';

class RegisterController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Utility to check if phone is already registered ---
  Future<bool> isPhoneNumberRegistered(String mobileNumber) async {
    // Firebase Auth provides no direct way to check for phone existence without sending OTP,
    // so we rely on Firestore for an existing user record. 
    // This is an imperfect but common workaround.
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('mobileNumber', isEqualTo: mobileNumber)
          .limit(1)
          .get();
      
      // Also check if the phone is registered directly in Firebase Auth
      // Note: This check is often restricted in live apps due to security rules.
      // We rely primarily on Firestore record established during signup.
      // If the user has signed up, their number should be in Firestore.
      if (querySnapshot.docs.isNotEmpty) {
        return true;
      }

      // Check for user existence by phone number via a safe method 
      // (This usually requires a complex backend/cloud function, so we rely on Firestore)
      
      return false;

    } catch (e) {
      print('Error checking phone registration: $e');
      return false; 
    }
  }


  // --- 1. Send OTP (Modified for Validation and Pre-Check) ---
  Future<Map<String, dynamic>> sendOtp(
    String name, 
    String mobileNumber, // Mobile number without +91
  ) async {
    // 1. Model Validation
    final model = RegisterModel(
      email: '', password: '', confirmPassword: '', 
      name: name, mobileNumber: mobileNumber,
    );
    if (model.validateName() != null) {
      return {'success': false, 'message': model.validateName()!};
    }
    if (model.validateMobileNumber() != null) {
      return {'success': false, 'message': model.validateMobileNumber()!};
    }

    // 2. Pre-registration Check
    if (await isPhoneNumberRegistered(mobileNumber)) {
      return {
        'success': false,
        'message': 'This mobile number is already registered. Please log in.',
      };
    }

    // 3. Proceed with OTP
    String phoneNumber = '+91$mobileNumber';
    String? verificationId;
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
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
      return {'success': false, 'message': 'An unexpected error occurred during OTP send.'};
    }
  }

  // --- 2. Verify OTP (Unchanged) ---
  Future<Map<String, dynamic>> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return {
        'success': true,
        'message': 'Phone number verified successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'OTP verification failed. Please check the code.'};
    }
  }

  // --- 3. Finalize Registration (Unchanged) ---
  Future<Map<String, dynamic>> finalizeRegistration(
    RegisterModel model,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return {'success': false, 'message': 'User not authenticated. Please try verification again.'};
    }
    
    // Update Firebase Auth profile
    try {
      if (model.name != null && model.name!.isNotEmpty) {
        await user.updateDisplayName(model.name);
      }
    } catch(e) {
      print("Warning: Could not update display name: $e");
    }

    // Create/Update user document in Firestore
    await _createUserDocument(
      user,
      model.name,
      model.mobileNumber,
    );

    return {
      'success': true,
      'message': 'Registration successful! Proceed to terms.',
      'user': user,
    };
  }

  // --- Create/Update user document in Firestore (for Sign Up) ---
  Future<void> _createUserDocument(
    User user,
    String? name,
    String? mobileNumber,
  ) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      final dataToSet = {
        'uid': user.uid,
        'email': user.email ?? 'phone_${mobileNumber}@phone.com',
        'displayName': name ?? user.displayName,
        'mobileNumber': mobileNumber,
        'photoURL': user.photoURL,
      };

      if (!docSnapshot.exists) {
        // New user document
        await userDocRef.set({
          ...dataToSet,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'emailVerified': user.emailVerified,
        });
      } else {
        // Existing user document (Update phone number and name in case of merge)
        await userDocRef.update({
          'displayName': name ?? user.displayName,
          'mobileNumber': mobileNumber,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  // Error message helper (Unchanged)
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'session-expired':
        return 'OTP session expired. Please request a new OTP';
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'user-not-found':
        // This case is primarily handled by the pre-check, but kept for robustness.
        return 'No account found with this number.';
      default:
        return 'An error occurred. Please try again. Code: $code';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}