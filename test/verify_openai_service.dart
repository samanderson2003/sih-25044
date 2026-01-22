
import 'package:sih_25044/services/openai_service.dart';

void main() async {
  print('Starting OpenAI Service Verification...');

  try {
    final suggestions = await OpenAIService.get10PercentYieldGuide(
      cropName: 'Rice (Paddy)',
      district: 'Khordha',
      soilType: 'Alluvial',
      currentYield: 4.5,
    );

    print('\nSuccessfully received ${suggestions.length} categories of recommendations:');
    suggestions.forEach((category, items) {
      print('\n--- $category ---');
      for (var item in items) {
        print('- ${item.productName}: ${item.description}');
      }
    });

  } catch (e) {
    print('Error: $e');
  }
}
