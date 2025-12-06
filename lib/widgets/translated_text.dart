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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translate();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    print(
      '🔤 TranslatedText: "${widget.text}" | Language: ${languageProvider.currentLanguage.code}',
    );

    // If English, no translation needed
    if (languageProvider.isEnglish) {
      print('🏴󠁧󠁢󠁥󠁮󠁧󠁿 Skipping translation (English selected)');
      setState(() {
        _translatedText = widget.text;
      });
      return;
    }

    print('🇮🇳 Translating to Odia...');
    final translated = await TranslationService.translate(
      widget.text,
      targetLanguage: languageProvider.currentLanguage.code,
    );

    if (mounted) {
      setState(() {
        _translatedText = translated;
      });
      print('✅ Updated UI with: $translated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Re-translate whenever language changes
        Future.microtask(() => _translate());

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
