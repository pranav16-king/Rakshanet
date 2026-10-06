import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/services/ai/hybrid_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HybridAiService & On-Device Trained AI Model Tests', () {
    final ai = HybridAiService.instance;

    test('1. Test On-Device CPR Protocol Intent', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('How do I perform CPR on an adult who collapsed?');

      expect(res.isOnline, isFalse);
      expect(res.source, contains('Trained On-Device AI Model'));
      expect(res.text.toLowerCase(), contains('cpr'));
      expect(res.steps.length, greaterThanOrEqualTo(3));
      expect(res.warningNotice, isNotNull);
      print('CPR Test Passed: ${res.text} (${res.steps.length} steps)');
    });

    test('2. Test On-Device Severe Bleeding & Tourniquet Intent', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('Deep cut with severe arterial bleeding spurting blood');

      expect(res.isOnline, isFalse);
      expect(res.text.toLowerCase(), anyOf(contains('bleed'), contains('hemorrhage')));
      expect(res.steps.any((s) => s.toLowerCase().contains('tourniquet') || s.toLowerCase().contains('pressure')), isTrue);
      print('Bleeding Test Passed: ${res.text}');
    });

    test('3. Test On-Device Snakebite Protocol Intent', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('Poisonous snake bit my leg what to do');

      expect(res.isOnline, isFalse);
      expect(res.text.toLowerCase(), contains('snake'));
      expect(res.warningNotice?.toLowerCase(), contains('not cut'));
      print('Snakebite Test Passed: ${res.text}');
    });

    test('4. Test On-Device Earthquake & Rubble Intent', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('Trapped under collapsed rubble after strong earthquake');

      expect(res.isOnline, isFalse);
      expect(res.text.toLowerCase(), contains('earthquake'));
      expect(res.steps.any((s) => s.toLowerCase().contains('tapping') || s.toLowerCase().contains('drop')), isTrue);
      print('Earthquake Test Passed: ${res.text}');
    });

    test('5. Test On-Device Water Purification Intent', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('How can I purify dirty contaminated flood water without a filter?');

      expect(res.isOnline, isFalse);
      expect(res.text.toLowerCase(), contains('water'));
      expect(res.steps.any((s) => s.toLowerCase().contains('boil') || s.toLowerCase().contains('bleach')), isTrue);
      print('Water Purification Test Passed: ${res.text}');
    });

    test('6. Test On-Device Dynamic Math Arithmetic', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('What is 25 * 14?');

      expect(res.isOnline, isFalse);
      expect(res.steps.any((s) => s.contains('350')), isTrue);
      print('Math Test Passed: 25 * 14 = 350');
    });

    test('7. Test On-Device Dynamic Percentage Math', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('Calculate 15% of 850');

      expect(res.isOnline, isFalse);
      expect(res.steps.any((s) => s.contains('127.50')), isTrue);
      print('Percentage Test Passed: 15% of 850 = 127.50');
    });

    test('8. Test On-Device Dynamic Unit Conversion (Celsius to Fahrenheit)', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('Convert 40 celsius to fahrenheit');

      expect(res.isOnline, isFalse);
      expect(res.steps.any((s) => s.contains('104.0°F') || s.contains('104')), isTrue);
      print('Unit Conversion Test Passed: 40°C = 104°F');
    });

    test('9. Test On-Device Dynamic Survival Ration Planning', () async {
      ai.forceOfflineMode = true;
      final res = await ai.processQuery('How much water ration needed for 4 people for 5 days?');

      expect(res.isOnline, isFalse);
      expect(res.steps.any((s) => s.contains('60 Liters') || s.contains('60')), isTrue);
      print('Ration Math Test Passed: 4 people * 5 days = 60 Liters');
    });

    test('10. Test Groq Cloud & Seamless Offline Fallback', () async {
      ai.forceOfflineMode = false;
      final res = await ai.processQuery('What are three critical survival priorities during a sudden power outage?');
      expect(res.steps.isNotEmpty, isTrue);
      expect(res.text.isNotEmpty, isTrue);
      print('Hybrid Query Passed (source: ${res.source}, online: ${res.isOnline}): ${res.text}');
    });
  });
}
