import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/mentor.dart';

void main() {
  group('mentor barrel', () {
    test('exports MentorService', () => expect(MentorService, isNotNull));
    test('exports MentorScreen', () => expect(MentorScreen, isNotNull));
    test('exports mentorModelIdProvider', () => expect(mentorModelIdProvider, isNotNull));
    test('exports MentorAction', () => expect(MentorAction, isNotNull));
    test('exports ProgressReport', () => expect(ProgressReport, isNotNull));
  });
}
