import '../models/language.dart';

class AppLanguages {
  static const Language english = Language(
    code: 'en',
    name: 'English',
    nativeName: 'English',
  );

  static const Language odia = Language(
    code: 'or',
    name: 'Odia',
    nativeName: 'ଓଡ଼ିଆ',
  );

  static const Language hindi = Language(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिंदी',
  );

  static const Language tamil = Language(
    code: 'ta',
    name: 'Tamil',
    nativeName: 'தமிழ்',
  );

  static const List<Language> supportedLanguages = [english, odia, hindi, tamil];

  static Language getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => english,
    );
  }
}
