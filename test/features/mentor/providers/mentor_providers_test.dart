import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart' show defaultModelForProvider;
import 'package:studyking/core/providers/app_providers.dart' show llmProviderProvider, settingsProvider, SettingsController, l10nProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart' show LlmProvider;
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts;
  bool shouldThrow = false;
  _FakeAttemptRepo(this._attempts);
  @override
  Future<void> init() async {
    if (shouldThrow) throw Exception('init error');
  }
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_attempts);
  }
  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.success(null);
  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);
  @override
  Future<Result<List<StudentAttempt>>> getAll() async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_attempts);
  }
  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class _FakeSettingsRepository extends SettingsRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(SettingsBox(selectedModel: 'custom-model'));

  @override
  Future<Result<void>> saveApiKey({required String service, required String key}) async => Result.success(null);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async => Result.success(null);
}

void main() {
  group('MentorProviders', () {
    test('mentorAttemptRepositoryProvider creates AttemptRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mentorAttemptRepositoryProvider);
      expect(repo, isA<AttemptRepository>());
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

    test('mentorProgressTrackerProvider handles error when attempt repo is missing data', () async {
      final emptyRepo = _FakeAttemptRepo([]);
      final container = ProviderContainer(
        overrides: [
          mentorAttemptRepositoryProvider.overrideWithValue(emptyRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());

      final stats = await tracker.getOverallStats('nonexistent');
      expect(stats['totalAttempts'], 0);
      expect(stats['correctAttempts'], 0);
    });

    test('mentorEngagementNudgeRepoProvider creates EngagementNudgeRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mentorEngagementNudgeRepoProvider);
      expect(repo, isA<EngagementNudgeRepository>());
    });

    test('mentorEngagementNudgeRepoProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(mentorEngagementNudgeRepoProvider);
      final b = container.read(mentorEngagementNudgeRepoProvider);
      expect(a, same(b));
    });

    test('mentorEngagementNudgeRepoProvider can be overridden', () {
      final fakeRepo = EngagementNudgeRepository();
      final container = ProviderContainer(
        overrides: [
          mentorEngagementNudgeRepoProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(mentorEngagementNudgeRepoProvider);
      expect(repo, same(fakeRepo));
    });

    test('mentorSessionRepositoryProvider creates SessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mentorSessionRepositoryProvider);
      expect(repo, isA<SessionRepository>());
    });

    test('mentorSessionRepositoryProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(mentorSessionRepositoryProvider);
      final b = container.read(mentorSessionRepositoryProvider);
      expect(a, same(b));
    });

    test('mentorSessionRepositoryProvider can be overridden', () {
      final fakeRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          mentorSessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(mentorSessionRepositoryProvider);
      expect(repo, same(fakeRepo));
    });

    test('mentorModelIdProvider uses saved model when selectedModel is non-empty', () async {
      final fakeRepo = _FakeSettingsRepository();
      final controller = SettingsController(fakeRepo);
      await controller.saveApiKey('dummy');

      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) => controller),
        ],
      );
      addTearDown(container.dispose);

      final modelId = container.read(mentorModelIdProvider);
      expect(modelId, equals('custom-model'));
    });

    test('mentorModelIdProvider wired correctly with llmProviderProvider fallback', () {
      final container = ProviderContainer(
        overrides: [
          llmProviderProvider.overrideWith((ref) => LlmProvider.ollama),
        ],
      );
      addTearDown(container.dispose);

      final modelId = container.read(mentorModelIdProvider);
      expect(modelId, equals(defaultModelForProvider(LlmProvider.ollama)));
    });

    test('mentorProgressTrackerProvider handles error from attempt repo', () async {
      final now = DateTime.now();
      final seededAttempts = [
        StudentAttempt(
          id: 'a1', studentId: 'stu1', questionId: 'q1', subjectId: 'sub1',
          isCorrect: true, timeSpentMs: 5000,
          confidence: 3, userAnswer: 'A', timestamp: now,
        ),
      ];
      final fakeRepo = _FakeAttemptRepo(seededAttempts);
      fakeRepo.shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          mentorAttemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      final stats = await tracker.getOverallStats('stu1');
      expect(stats['totalAttempts'], 0);
      expect(stats['correctAttempts'], 0);
    });

    test('mentorProgressTrackerProvider recovers after error', () async {
      final now = DateTime.now();
      final seededAttempts = [
        StudentAttempt(
          id: 'a1', studentId: 'stu1', questionId: 'q1', subjectId: 'sub1',
          isCorrect: true, timeSpentMs: 5000,
          confidence: 3, userAnswer: 'A', timestamp: now,
        ),
      ];
      final fakeRepo = _FakeAttemptRepo(seededAttempts);

      fakeRepo.shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          mentorAttemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      var stats = await tracker.getOverallStats('stu1');
      expect(stats['totalAttempts'], 0);

      fakeRepo.shouldThrow = false;
      stats = await tracker.getOverallStats('stu1');
      expect(stats['totalAttempts'], 1);
      expect(stats['correctAttempts'], 1);
      expect(stats['accuracy'], 100);
    });

    test('mentorProgressTrackerProvider handles l10nProvider changes gracefully', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());

      container.read(l10nProvider.notifier).state =
          lookupAppLocalizations(const Locale('es'));
      await Future<void>.delayed(Duration.zero);

      final trackerAfterUpdate = container.read(mentorProgressTrackerProvider);
      expect(trackerAfterUpdate, isA<StudyProgressTracker>());
    });

    test('mentorProgressTrackerProvider l10nProvider reset to null', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(l10nProvider.notifier).state =
          lookupAppLocalizations(const Locale('es'));
      await Future<void>.delayed(Duration.zero);

      container.read(l10nProvider.notifier).state = null;
      await Future<void>.delayed(Duration.zero);

      final tracker = container.read(mentorProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });
  });
}
