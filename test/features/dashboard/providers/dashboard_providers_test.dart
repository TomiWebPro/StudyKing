import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show attemptRepositoryProvider;
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';

class _SeededAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts;
  _SeededAttemptRepo(this._attempts);
  @override
  Future<void> init() async {}
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success(_attempts);
  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.success(null);
  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);
  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success(_attempts);
  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class _FailingAttemptRepo extends AttemptRepository {
  @override
  Future<void> init() async {}
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async =>
      Result.failure('Repo failure');
  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.failure('Repo failure');
  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.failure('Repo failure');
  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.failure('Repo failure');
  @override
  Future<Result<void>> delete(String key) async => Result.failure('Repo failure');
}

class _FakeAdherenceRepo extends PlanAdherenceRepository {
  @override
  Future<void> init() async {}
}

void main() {
  group('DashboardProviders', () {
    test('dashboardStudyProgressTrackerProvider creates StudyProgressTracker', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tracker = container.read(dashboardStudyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    test('dashboardInstrumentationServiceProvider creates InstrumentationService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardInstrumentationServiceProvider),
        isA<InstrumentationService>(),
      );
    });

    test('dashboardStudyProgressTrackerProvider uses overridden attemptRepo for stats', () async {
      final now = DateTime.now();
      final seededAttempts = [
        StudentAttempt(
          id: 'a1', studentId: 'stu1', questionId: 'q1', subjectId: 'sub1',
          isCorrect: true, timeSpentMs: 5000,
          confidence: 3, userAnswer: 'A', timestamp: now,
        ),
        StudentAttempt(
          id: 'a2', studentId: 'stu1', questionId: 'q2', subjectId: 'sub1',
          isCorrect: false, timeSpentMs: 10000,
          confidence: 2, userAnswer: 'B', timestamp: now,
        ),
        StudentAttempt(
          id: 'a3', studentId: 'stu1', questionId: 'q3', subjectId: 'sub1',
          isCorrect: true, timeSpentMs: 3000,
          confidence: 4, userAnswer: 'C', timestamp: now,
        ),
      ];
      final seededRepo = _SeededAttemptRepo(seededAttempts);
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(seededRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(dashboardStudyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());

      final stats = await tracker.getOverallStats('stu1');
      expect(stats.data!['totalAttempts'], 3);
      expect(stats.data!['correctAttempts'], 2);
      expect(stats.data!['accuracy'], 2.0 / 3.0);
      expect(stats.data!['avgTimePerQuestion'], (5000 + 10000 + 3000) / 3);
    });

    test('dashboardStudyProgressTrackerProvider handles error-state when attemptRepo fails', () async {
      final failingRepo = _FailingAttemptRepo();
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(failingRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(dashboardStudyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());

      final stats = await tracker.getOverallStats('stu1');
      expect(stats.data!['totalAttempts'], 0);
      expect(stats.data!['correctAttempts'], 0);
      expect(stats.data!['accuracy'], 0.0);
    });

    test('dashboardInstrumentationServiceProvider uses shared adherence repo', () {
      final fakeAdherenceRepo = _FakeAdherenceRepo();
      final container = ProviderContainer(
        overrides: [
          engagementAdherenceRepoProvider.overrideWithValue(fakeAdherenceRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(dashboardInstrumentationServiceProvider);
      expect(service, isA<InstrumentationService>());
    });
  });
}
