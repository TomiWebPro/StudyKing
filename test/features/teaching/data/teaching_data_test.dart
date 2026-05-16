import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/teaching_data.dart';

void main() {
  group('teaching_data barrel', () {
    test('exports ConversationMessage', () {
      expect(ConversationMessage, isNotNull);
    });

    test('exports TutorSession', () {
      expect(TutorSession, isNotNull);
    });

    test('exports registerTeachingAdapters', () {
      expect(registerTeachingAdapters, isNotNull);
    });
  });
}
