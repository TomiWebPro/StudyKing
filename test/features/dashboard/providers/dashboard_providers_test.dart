import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';

class _FakeTopicRepository extends TopicRepository {
  @override
  Future<Result<void>> save(String key, Topic item) async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async => Result.success(null);
  @override
  Future<Result<List<Topic>>> getAll() async => Result.success([]);
  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.success(null);
  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);
  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success([]);
  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

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

void main() {
  group('DashboardProviders', () {
    test('dashboardTopicRepositoryProvider creates TopicRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardTopicRepositoryProvider),
        isA<TopicRepository>(),
      );
    });

    test('dashboardAttemptRepositoryProvider creates AttemptRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardAttemptRepositoryProvider),
        isA<AttemptRepository>(),
      );
    });

    test('dashboardStudyProgressTrackerProvider is wired to dashboardAttemptRepositoryProvider', () {
      final overrideAttempt = AttemptRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardAttemptRepositoryProvider.overrideWithValue(overrideAttempt),
        ],
      );
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

    test('dashboardAdherenceRepositoryProvider creates PlanAdherenceRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardAdherenceRepositoryProvider),
        isA<PlanAdherenceRepository>(),
      );
    });

    test('override propagation: dashboardTopicRepositoryProvider can be overridden with fake', () {
      final fakeRepo = _FakeTopicRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardTopicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(dashboardTopicRepositoryProvider),
        same(fakeRepo),
      );
    });

    test('override propagation: dashboardAttemptRepositoryProvider can be overridden with fake', () {
      final fakeRepo = _FakeAttemptRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardAttemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(dashboardAttemptRepositoryProvider),
        same(fakeRepo),
      );
    });

    test('override propagation: dashboardAdherenceRepositoryProvider can be overridden', () {
      final fakeRepo = PlanAdherenceRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardAdherenceRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(dashboardAdherenceRepositoryProvider),
        same(fakeRepo),
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
          dashboardAttemptRepositoryProvider.overrideWithValue(seededRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(dashboardStudyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());

      final stats = await tracker.getOverallStats('stu1');
      expect(stats['totalAttempts'], 3);
      expect(stats['correctAttempts'], 2);
      expect(stats['accuracy'], 2.0 / 3.0);
      expect(stats['avgTimePerQuestion'], (5000 + 10000 + 3000) / 3);
    });
  });
}
