import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/language.dart';
import '../constants/languages.dart';

class LanguageProvider extends ChangeNotifier {
  Language _currentLanguage = AppLanguages.english;
  bool _isLoading = false;

  Language get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  bool get isOdia => _currentLanguage.code == 'or';
  bool get isEnglish => _currentLanguage.code == 'en';
  bool get isHindi => _currentLanguage.code == 'hi';
  bool get isTamil => _currentLanguage.code == 'ta';

  LanguageProvider() {
    _loadLanguagePreference();
  }

  /// Load language preference from Firebase
  Future<void> _loadLanguagePreference() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final languageCode = data?['preferredLanguage'] as String?;
          if (languageCode != null) {
            _currentLanguage = AppLanguages.getLanguageByCode(languageCode);
          }
        }
      }
    } catch (e) {
      print('Error loading language preference: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Change language and save to Firebase
  Future<void> changeLanguage(Language language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    // Save to Firebase
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'preferredLanguage': language.code,
              'languageUpdatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  /// Toggle between languages cyclically
  Future<void> toggleLanguage() async {
    final currentIndex = AppLanguages.supportedLanguages.indexOf(_currentLanguage);
    final nextIndex = (currentIndex + 1) % AppLanguages.supportedLanguages.length;
    final nextLanguage = AppLanguages.supportedLanguages[nextIndex];
    await changeLanguage(nextLanguage);
  }
}
