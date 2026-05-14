import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/practice.dart';

void main() {
  test('practice barrel exports PracticeScreen', () {
    expect(PracticeScreen, isNotNull);
  });

  test('practice barrel exports PracticeResultsScreen', () {
    expect(PracticeResultsScreen, isNotNull);
  });

  test('practice barrel exports PracticeSessionNavButtons', () {
    expect(PracticeSessionNavButtons, isNotNull);
  });

  test('practice barrel exports PracticeEmptyState', () {
    expect(PracticeEmptyState, isNotNull);
  });

  test('practice barrel exports PracticeFeedbackWidget', () {
    expect(PracticeFeedbackWidget, isNotNull);
  });

  test('practice barrel exports PracticeModeCard', () {
    expect(PracticeModeCard, isNotNull);
  });

  test('practice barrel exports PracticeModeGrid', () => expect(PracticeModeGrid, isNotNull));
  test('practice barrel exports PracticeModeOption', () => expect(PracticeModeOption, isNotNull));
  test('practice barrel exports PracticeModeSheet', () => expect(PracticeModeSheet, isNotNull));
  test('practice barrel exports PracticeSessionStatsBar', () => expect(PracticeSessionStatsBar, isNotNull));
  test('practice barrel exports SpacedRepetitionSheet', () => expect(SpacedRepetitionSheet, isNotNull));
  test('practice barrel exports SubjectPracticeCard', () => expect(SubjectPracticeCard, isNotNull));
  test('practice barrel exports SubjectSelectionSheet', () => expect(SubjectSelectionSheet, isNotNull));
  test('practice barrel exports TopicSelectionSheet', () => expect(TopicSelectionSheet, isNotNull));
  test('practice barrel exports WeakAreasSheet', () => expect(WeakAreasSheet, isNotNull));
  test('practice barrel exports PracticeAnswerRecord', () => expect(PracticeAnswerRecord, isNotNull));
  test('practice barrel exports PracticeSessionResult', () => expect(PracticeSessionResult, isNotNull));
  test('practice barrel exports PracticeSessionService', () => expect(PracticeSessionService, isNotNull));
  test('practice barrel exports PracticeDataService', () => expect(PracticeDataService, isNotNull));
}
