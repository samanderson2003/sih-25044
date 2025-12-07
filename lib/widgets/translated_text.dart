import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translatedText;
  String? _lastLanguageCode;
  String? _lastTranslatedForText;
  bool _isTranslating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndTranslate();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _lastTranslatedForText = null; // Reset when text changes
      _checkAndTranslate();
    }
  }

  void _checkAndTranslate() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    final currentLangCode = languageProvider.currentLanguage.code;

    // Only translate if:
    // 1. Language changed OR
    // 2. We haven't translated this text for this language yet
    if (_lastLanguageCode != currentLangCode ||
        _lastTranslatedForText != widget.text) {
      _lastLanguageCode = currentLangCode;
      _lastTranslatedForText = widget.text;
      _translate();
    }
  }

  Future<void> _translate() async {
    if (_isTranslating) return; // Prevent duplicate translations

    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    // If English, no translation needed
    if (languageProvider.isEnglish) {
      if (mounted && _translatedText != widget.text) {
        setState(() {
          _translatedText = widget.text;
        });
      }
      return;
    }

    _isTranslating = true;

    final translated = await TranslationService.translate(
      widget.text,
      targetLanguage: languageProvider.currentLanguage.code,
    );

    if (mounted && _translatedText != translated) {
      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });
    } else {
      _isTranslating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Only schedule translation if language actually changed
        if (_lastLanguageCode != languageProvider.currentLanguage.code &&
            !_isTranslating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _checkAndTranslate();
            }
          });
        }

        return Text(
          _translatedText ?? widget.text,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
