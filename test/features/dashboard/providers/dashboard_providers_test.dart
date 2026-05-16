import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> save(String key, Topic item) async {}
  @override
  Future<Topic?> get(String key) async => null;
  @override
  Future<List<Topic>> getAll() async => [];
  @override
  Future<void> delete(String key) async {}
}

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<void> save(String key, StudentAttempt item) async {}
  @override
  Future<StudentAttempt?> get(String key) async => null;
  @override
  Future<List<StudentAttempt>> getAll() async => [];
  @override
  Future<void> delete(String key) async {}
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
  });
}
