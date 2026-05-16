import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/practice.dart';

void main() {
  test('practice barrel exports PracticeScreen', () {
    expect(PracticeScreen, isNotNull);
  });

  test('practice barrel exports PracticeSessionScreen', () {
    expect(PracticeSessionScreen, isNotNull);
  });

  test('practice barrel exports PracticeResultsScreen', () {
    expect(PracticeResultsScreen, isNotNull);
  });

  test('practice barrel exports PracticeSessionService', () {
    expect(PracticeSessionService, isNotNull);
  });

  test('practice barrel exports PracticeDataService', () {
    expect(PracticeDataService, isNotNull);
  });

  test('practice barrel exports SpacedRepetitionService', () {
    expect(SpacedRepetitionService, isNotNull);
  });
}
