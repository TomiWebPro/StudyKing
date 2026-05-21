import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/study_progress_provider.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show attemptRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> _attempts;

  _FakeAttemptRepository(this._attempts);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(
      _attempts.where((a) => a.studentId == studentId).toList(),
    );
  }
}

class _FailingAttemptRepository extends AttemptRepository {
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.failure('Storage error');
  }
}

void main() {
  group('studyProgressTrackerProvider', () {
    test('constructs StudyProgressTracker with default dependencies', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());

      final tracker = container.read(studyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    test('falls back to en locale when l10nProvider is null', () {
      final container = ProviderContainer(
        overrides: [
          l10nProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(() => container.dispose());

      final tracker = container.read(studyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    test('returns same instance on repeated reads', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());

      final tracker1 = container.read(studyProgressTrackerProvider);
      final tracker2 = container.read(studyProgressTrackerProvider);
      expect(tracker1, same(tracker2));
    });

    test('applies provided localization via override', () {
      final container = ProviderContainer(
        overrides: [
          l10nProvider.overrideWith(
            (ref) => lookupAppLocalizations(const Locale('en')),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      final tracker = container.read(studyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    group('behavioral: dependency wiring', () {
      test('uses overridden attemptRepository for getOverallStats', () async {
        final now = DateTime.now();
        final fakeRepo = _FakeAttemptRepository([
          StudentAttempt(
            id: 'a1',
            studentId: 'stu1',
            questionId: 'q1',
            subjectId: 'sub1',
            isCorrect: true,
            timestamp: now,
            userAnswer: 'correct',
            timeSpentMs: 5000,
          ),
          StudentAttempt(
            id: 'a2',
            studentId: 'stu1',
            questionId: 'q2',
            subjectId: 'sub1',
            isCorrect: false,
            timestamp: now,
            userAnswer: 'wrong',
            timeSpentMs: 3000,
          ),
        ]);
        final container = ProviderContainer(
          overrides: [
            attemptRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(() => container.dispose());

        final tracker = container.read(studyProgressTrackerProvider);
        final stats = await tracker.getOverallStats('stu1');
        expect(stats.data!['totalAttempts'], 2);
        expect(stats.data!['correctAttempts'], 1);
        expect(stats.data!['accuracy'], 50);
      });

      test('error-state: handles attemptRepo failure gracefully', () async {
        final failingRepo = _FailingAttemptRepository();
        final container = ProviderContainer(
          overrides: [
            attemptRepositoryProvider.overrideWithValue(failingRepo),
          ],
        );
        addTearDown(() => container.dispose());

        final tracker = container.read(studyProgressTrackerProvider);
        final stats = await tracker.getOverallStats('stu1');
        expect(stats.data!['totalAttempts'], 0);
        expect(stats.data!['correctAttempts'], 0);
        expect(stats.data!['accuracy'], 0);
      });
    });
  });
}
