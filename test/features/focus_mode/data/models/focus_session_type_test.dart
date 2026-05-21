import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';

void main() {
  group('FocusSessionType', () {
    test('has all expected enum values', () {
      expect(FocusSessionType.values, hasLength(4));
      expect(FocusSessionType.values, containsAll([
        FocusSessionType.quickPractice,
        FocusSessionType.spacedRepetition,
        FocusSessionType.weakAreaAttack,
        FocusSessionType.freeFocus,
      ]));
    });

    test('toString returns correct name', () {
      expect(FocusSessionType.quickPractice.toString(), 'FocusSessionType.quickPractice');
      expect(FocusSessionType.spacedRepetition.toString(), 'FocusSessionType.spacedRepetition');
      expect(FocusSessionType.weakAreaAttack.toString(), 'FocusSessionType.weakAreaAttack');
      expect(FocusSessionType.freeFocus.toString(), 'FocusSessionType.freeFocus');
    });

    test('name property returns correct string', () {
      expect(FocusSessionType.quickPractice.name, 'quickPractice');
      expect(FocusSessionType.spacedRepetition.name, 'spacedRepetition');
      expect(FocusSessionType.weakAreaAttack.name, 'weakAreaAttack');
      expect(FocusSessionType.freeFocus.name, 'freeFocus');
    });

    test('can be deserialized from name', () {
      for (final type in FocusSessionType.values) {
        expect(FocusSessionType.values.firstWhere((t) => t.name == type.name), type);
      }
    });
  });
}
