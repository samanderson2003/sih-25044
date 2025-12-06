import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _apiKey = 'sk_qkuwvpnz_Qmc4avxO4uiTyfbt30wNeBkx';
  static const String _baseUrl = 'https://api.sarvam.ai/translate';

  // Cache to avoid repeated API calls for same text
  static final Map<String, Map<String, String>> _cache = {};

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

    // Check cache
    if (_cache.containsKey(targetLanguage) &&
        _cache[targetLanguage]!.containsKey(text)) {
      print('📦 Using cached translation for: $text');
      return _cache[targetLanguage]![text]!;
    }

    print('🌐 Translating "$text" from $sourceLanguage to $targetLanguage');

    try {
      // Sarvam AI uses language codes like 'en-IN', 'od-IN' (not or-IN!)
      final sourceCode = sourceLanguage == 'en' ? 'en-IN' : 'od-IN';
      final targetCode = targetLanguage == 'or' ? 'od-IN' : 'en-IN';

      print('🔄 API Request: $sourceCode -> $targetCode');

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

      print('📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ API Response: $data');
        final translatedText = data['translated_text'] as String;

        // Cache the result
        _cache[targetLanguage] ??= {};
        _cache[targetLanguage]![text] = translatedText;

        print('✨ Translated: "$text" -> "$translatedText"');
        return translatedText;
      } else {
        print('❌ Translation error: ${response.statusCode} - ${response.body}');
        return text; // Return original on error
      }
    } catch (e) {
      print('💥 Translation exception: $e');
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
    ];
  }
}
