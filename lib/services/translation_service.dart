import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  static String get _apiKey => dotenv.env['SARVAM_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.sarvam.ai/translate';

  // Cache to avoid repeated API calls for same text
  static final Map<String, Map<String, String>> _cache = {};

  // Local dictionary for static content (Months)
  static final Map<String, Map<String, String>> _localDictionary = {
    'ta': {
      'January': 'ஜனவரி',
      'February': 'பிப்ரவரி',
      'March': 'மார்ச்',
      'April': 'ஏப்ரல்',
      'May': 'மே',
      'June': 'ஜூன்',
      'July': 'ஜூலை',
      'August': 'ஆகஸ்ட்',
      'September': 'செப்டம்பர்',
      'October': 'அக்டோபர்',
      'November': 'நவம்பர்',
      'December': 'டிசம்பர்',
    },
    'or': {
      'January': 'ଜାନୁଆରୀ',
      'February': 'ଫେବୃଆରୀ',
      'March': 'ମାର୍ଚ୍ଚ',
      'April': 'ଏପ୍ରିଲ',
      'May': 'ମେ',
      'June': 'ଜୁନ',
      'July': 'ଜୁଲାଇ',
      'August': 'ଅଗଷ୍ଟ',
      'September': 'ସେପ୍ଟେମ୍ବର',
      'October': 'ଅକ୍ଟୋବର',
      'November': 'ନଭେମ୍ବର',
      'December': 'ଡିସେମ୍ବର',
    },
    'hi': {
      'January': 'जनवरी',
      'February': 'फरवरी',
      'March': 'मार्च',
      'April': 'अप्रैल',
      'May': 'मई',
      'June': 'जून',
      'July': 'जुलाई',
      'August': 'अगस्त',
      'September': 'सितंबर',
      'October': 'अक्टूबर',
      'November': 'नवंबर',
      'December': 'दिसंबर',
    },
  };

  // Rate limiting
  static DateTime? _lastRequestTime;
  static const _minDelayBetweenRequests = Duration(milliseconds: 100);

  /// Translate text to target language using Sarvam AI
  /// [text] - The text to translate
  /// [targetLanguage] - Target language code ('or' for Odia, 'en' for English)
  /// [sourceLanguage] - Source language code (defaults to 'en')
  static Future<String> translate(
    String text, {
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    // If target is same as source, return original
    if (targetLanguage == sourceLanguage) return text;

    // Check local dictionary first (for static known values like months)
    if (_localDictionary.containsKey(targetLanguage) && 
        _localDictionary[targetLanguage]!.containsKey(text)) {
      return _localDictionary[targetLanguage]![text]!;
    }

    // Check cache first
    if (_cache.containsKey(targetLanguage) &&
        _cache[targetLanguage]!.containsKey(text)) {
      return _cache[targetLanguage]![text]!;
    }

    // Rate limiting - add small delay between requests
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minDelayBetweenRequests) {
        await Future.delayed(_minDelayBetweenRequests - timeSinceLastRequest);
      }
    }

    try {
      // Sarvam AI uses language codes like 'en-IN', 'od-IN', 'hi-IN', 'ta-IN'
      String getSarvamCode(String code) {
        switch (code) {
          case 'en': return 'en-IN';
          case 'or': return 'od-IN'; // Sarvam uses 'od-IN' for Odia
          case 'hi': return 'hi-IN';
          case 'ta': return 'ta-IN';
          default: return 'en-IN';
        }
      }

      final sourceCode = getSarvamCode(sourceLanguage);
      final targetCode = getSarvamCode(targetLanguage);

      _lastRequestTime = DateTime.now();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': _apiKey,
        },
        body: json.encode({
          'input': text,
          'source_language_code': sourceCode,
          'target_language_code': targetCode,
          'speaker_gender': 'Male',
          'mode': 'formal',
          'model': 'mayura:v1',
          'enable_preprocessing': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['translated_text'] as String;

        // Cache the result
        _cache[targetLanguage] ??= {};
        _cache[targetLanguage]![text] = translatedText;

        return translatedText;
      } else if (response.statusCode == 429) {
        // Rate limit hit - wait and retry once
        await Future.delayed(const Duration(seconds: 1));
        return text; // Return original to avoid cascading failures
      } else {
        return text; // Return original on error
      }
    } catch (e) {
      return text; // Return original on error
    }
  }

  /// Translate multiple texts sequentially (Sarvam doesn't support batch)
  static Future<List<String>> translateBatch(
    List<String> texts, {
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    if (targetLanguage == sourceLanguage) return texts;

    final results = <String>[];
    for (final text in texts) {
      final translated = await translate(
        text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      results.add(translated);
    }
    return results;
  }

  /// Clear translation cache
  static void clearCache() {
    _cache.clear();
  }

  /// Get supported languages (Sarvam supports en-IN and or-IN)
  static Future<List<Map<String, String>>> getSupportedLanguages() async {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'or', 'name': 'Odia'},
      {'code': 'hi', 'name': 'Hindi'},
      {'code': 'ta', 'name': 'Tamil'},
    ];
  }
}
