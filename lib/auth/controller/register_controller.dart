import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/register_model.dart';

class RegisterController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email/Password Registration
  Future<Map<String, dynamic>> registerWithEmail(RegisterModel model) async {
    try {
      // Validate model
      if (!model.isValid()) {
        return {
          'success': false,
          'message':
              model.validateEmail() ??
              model.validatePassword() ??
              model.validateConfirmPassword() ??
              model.validateName(),
        };
      }

      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: model.email.trim(),
            password: model.password.trim(),
          );

      // Update display name if provided
      if (model.name != null && model.name!.isNotEmpty) {
        await userCredential.user?.updateDisplayName(model.name);
      }

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          userCredential.user!,
          model.name,
          model.mobileNumber,
        );
      }

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return {
        'success': true,
        'message': 'Registration successful! Please verify your email.',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Google Sign Up
  Future<Map<String, dynamic>> registerWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        return {'success': false, 'message': 'Sign up cancelled'};
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          userCredential.user!,
          userCredential.user!.displayName,
          null, // No mobile number from Google sign-in
        );
      }

      return {
        'success': true,
        'message': 'Google Sign-Up successful!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during Google sign-up.',
      };
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user,
    String? name,
    String? mobileNumber,
  ) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        await userDocRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': name ?? user.displayName,
          'mobileNumber': mobileNumber,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'emailVerified': user.emailVerified,
        });
      }
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  // Error message helper
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
