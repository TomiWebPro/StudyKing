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

  test('practice barrel exports SpacedRepetitionEngine', () {
    expect(SpacedRepetitionEngine, isNotNull);
  });

  test('practice barrel exports ReadinessScorer', () {
    expect(ReadinessScorer, isNotNull);
  });

  test('practice barrel exports MasteryRecorder', () {
    expect(MasteryRecorder, isNotNull);
  });

  test('practice barrel exports MistakeReviewService', () {
    expect(MistakeReviewService, isNotNull);
  });

  test('practice barrel exports DifficultyAdapter', () {
    expect(DifficultyAdapter, isNotNull);
  });

  test('practice barrel exports ExamSessionService', () {
    expect(ExamSessionService, isNotNull);
  });

  test('practice barrel exports ExamSessionScreen', () {
    expect(ExamSessionScreen, isNotNull);
  });

  test('practice barrel exports PracticeAnswerRecord', () {
    expect(PracticeAnswerRecord, isNotNull);
  });

  test('practice barrel exports PracticeSessionResult', () {
    expect(PracticeSessionResult, isNotNull);
  });
}
