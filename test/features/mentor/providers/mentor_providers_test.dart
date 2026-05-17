import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart' show defaultModelForProvider;
import 'package:studyking/core/providers/app_providers.dart' show llmProviderProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart' show LlmProvider;
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart';

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts;
  _FakeAttemptRepo(this._attempts);
  @override
  Future<void> init() async {}
  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async => _attempts;
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
  group('MentorProviders', () {
    test('mentorAttemptRepositoryProvider creates AttemptRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mentorAttemptRepositoryProvider);
      expect(repo, isA<AttemptRepository>());
    });

    test('mentorPendingActionRepoProvider creates PendingActionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mentorPendingActionRepoProvider);
      expect(repo, isA<PendingActionRepository>());
    });

    test('mentorProgressTrackerProvider is wired to mentorAttemptRepositoryProvider', () {
      final overrideAttemptRepo = AttemptRepository();
      final container = ProviderContainer(
        overrides: [
          mentorAttemptRepositoryProvider.overrideWithValue(overrideAttemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    test('mentorPendingActionRepoProvider can be overridden', () {
      final fakeRepo = PendingActionRepository();
      final container = ProviderContainer(
        overrides: [
          mentorPendingActionRepoProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(mentorPendingActionRepoProvider);
      expect(repo, same(fakeRepo));
    });

    test('mentorProgressTrackerProvider is wired to mentorSessionRepositoryProvider', () {
      final fakeSessionRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          mentorSessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    test('mentorModelIdProvider returns default model id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final modelId = container.read(mentorModelIdProvider);
      expect(modelId, isNotEmpty);
    });

    test('mentorModelIdProvider falls back to default model when settings are empty', () {
      final container = ProviderContainer(
        overrides: [
          llmProviderProvider.overrideWith((ref) => LlmProvider.openRouter),
        ],
      );
      addTearDown(container.dispose);

      final modelId = container.read(mentorModelIdProvider);
      expect(modelId, isNotEmpty);
      expect(modelId, equals(defaultModelForProvider(container.read(llmProviderProvider))));
    });

    test('mentorAttemptRepositoryProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(mentorAttemptRepositoryProvider);
      final b = container.read(mentorAttemptRepositoryProvider);
      expect(a, same(b));
    });

    test('mentorPendingActionRepoProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(mentorPendingActionRepoProvider);
      final b = container.read(mentorPendingActionRepoProvider);
      expect(a, same(b));
    });

    test('mentorProgressTrackerProvider uses overridden attemptRepo for stats', () async {
      final now = DateTime.now();
      final seededAttempts = [
        StudentAttempt(
          id: 'a1', studentId: 'stu1', questionId: 'q1', subjectId: 'sub1',
          isCorrect: true, timeSpentMs: 5000,
          confidence: 3, userAnswer: 'A', timestamp: now,
        ),
      ];
      final fakeRepo = _FakeAttemptRepo(seededAttempts);
      final container = ProviderContainer(
        overrides: [
          mentorAttemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());

      final stats = await tracker.getOverallStats('stu1');
      expect(stats['totalAttempts'], 1);
      expect(stats['correctAttempts'], 1);
      expect(stats['accuracy'], 100);
    });
  });
}
