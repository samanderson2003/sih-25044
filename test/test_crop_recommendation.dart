import 'package:sih_25044/services/crop_recommendation_service.dart';

void main() async {
  print('🌾 ===== CROP RECOMMENDATION SERVICE TEST =====');
  print('Testing AI crop recommendation for Tamil Nadu farmer\n');

  try {
    // Test data for a Tamil Nadu farmer
    final recommendation = await CropRecommendationService.recommendCrop(
      district: 'Chengalpattu',
      soilType: 'Clay Loam',
      soilPh: 6.5,
      rainfallMm: 1200.0,
      currentYield: 4.5,
      currentCrop: 'Rice',
      areaHectares: 2.0,
      soilOrganic: 0.8,
      soilNutrients: {
        'zinc': 0.8,
        'iron': 0.9,
        'copper': 0.6,
        'manganese': 0.85,
        'boron': 0.5,
      },
    );

    if (recommendation != null) {
      print('✅ Successfully got recommendation!\n');
      print('═' * 60);
      print('🌾 RECOMMENDED CROP: ${recommendation.recommendedCrop}');
      print('═' * 60);
      print('\n📝 Reason: ${recommendation.reason}');
      print('📈 Expected Yield Increase: ${recommendation.expectedYieldIncrease.toStringAsFixed(1)}%');

      print('\n🌱 Best Varieties:');
      for (var variety in recommendation.bestVarieties) {
        print('   ✓ $variety');
      }

      print('\n💧 Irrigation Plan:');
      print('   Method: ${recommendation.irrigation.method}');
      print('   Frequency: ${recommendation.irrigation.frequency}');
      print('   Water Qty: ${recommendation.irrigation.waterQuantity}');
      print('   Subsidy: ${recommendation.irrigation.tamilNaduSubsidy}');

      print('\n🌿 Fertilizer Plan:');
      for (var stage in recommendation.fertilizer.stages) {
        print('   • ${stage.stage}: ${stage.product} (${stage.dosage})');
        print('     Timing: ${stage.timing} - Cost: ${stage.cost}');
      }
      print('   Organic: ${recommendation.fertilizer.organicAlternative}');

      print('\n🐛 Pest Control - Major Pests:');
      for (var pest in recommendation.pestControl.majorPests) {
        print('   • ${pest.pestName}: ${pest.symptom}');
        print('     Treatment: ${pest.treatment}');
      }

      print('\n🏛️ Tamil Nadu Schemes:');
      for (var scheme in recommendation.tamilNaduSchemes) {
        print('   ✓ $scheme');
      }

      print('\n💰 Investment: ${recommendation.estimatedInvestment}');
      print('\n🌾 ===== TEST PASSED - RECOMMENDATION SUCCESSFUL =====');
    } else {
      print('❌ No recommendation received');
      print('🌾 ===== TEST FAILED =====');
    }
  } catch (e) {
    print('❌ Error during test: $e');
    print('🌾 ===== TEST FAILED WITH EXCEPTION =====');
  }
}
