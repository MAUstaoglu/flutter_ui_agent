import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

void main() {
  group('LlmFunctionCall continueAfterNavigation', () {
    test('should default to false when not specified', () {
      final call = LlmFunctionCall('navigate', {});
      expect(call.continueAfterNavigation, false);
    });

    test('should be true when explicitly set', () {
      final call = LlmFunctionCall(
        'navigate',
        {},
        continueAfterNavigation: true,
      );
      expect(call.continueAfterNavigation, true);
    });

    test('should be false when explicitly set', () {
      final call = LlmFunctionCall(
        'navigate',
        {},
        continueAfterNavigation: false,
      );
      expect(call.continueAfterNavigation, false);
    });

    test('multiple function calls - first should have flag set', () {
      // Simulating what Gemini/HuggingFace provider would do
      final calls = ['navigate', 'enableWifi'].asMap().entries.map((entry) {
        final shouldContinue = entry.key == 0 && 2 > 1; // 2 total calls
        return LlmFunctionCall(
          entry.value,
          {},
          continueAfterNavigation: shouldContinue,
        );
      }).toList();

      expect(calls[0].continueAfterNavigation, true);
      expect(calls[1].continueAfterNavigation, false);
    });

    test('single function call - should not have flag set', () {
      final calls = ['navigate'].asMap().entries.map((entry) {
        final shouldContinue = entry.key == 0 && 1 > 1; // Only 1 call
        return LlmFunctionCall(
          entry.value,
          {},
          continueAfterNavigation: shouldContinue,
        );
      }).toList();

      expect(calls[0].continueAfterNavigation, false);
    });
  });
}
