/// Integration test: per-subject study time with daily-cap adherence annotations
/// in [MentorContextBuilder].
///
/// File placement: `test/integration/` (integration-level, separate from
/// unit/widget tests per AGENTS.md). This validates the full flow where the
/// real [SessionRepository] query feeds through the builder into the injected
/// mentor context prompt — Vision Next-Term §3.1.
///
/// Uses hand-written fakes, no Hive or network. Plain `test()` because
/// no widgets are pumped — the builder returns a string.

library;

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/mentor/services/mentor_context_builder.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

import '../helpers/fakes.dart';
// Aliased to disambiguate FakeMasteryGraphService / FakePlannerService
// which also exist in test/helpers/fakes.dart.
import '../features/mentor/services/tools/test_helpers.dart' as mht;

// ---------------------------------------------------------------------------
// Fixed clock returning a single date so "today" is deterministic.
// ---------------------------------------------------------------------------

class _FixedClock extends Clock {
  final DateTime nowDate;
  _FixedClock(this.nowDate);
  @override
  DateTime now() => nowDate;
}

// ---------------------------------------------------------------------------
// SessionRepository stub that lets us inject per-subject minutes.
// ---------------------------------------------------------------------------

class _PerSubjectSessionRepo extends SessionRepository {
  int _todayTotalMs = 0;
  Map<String, int> _todayBySubject = {};

  _PerSubjectSessionRepo({DateTime? fixedDate})
      : super(clock: _FixedClock(fixedDate ?? DateTime(2026, 3, 15)));

  void setTodayTotal(int ms) => _todayTotalMs = ms;
  void setTodayBySubject(Map<String, int> map) =>
      _todayBySubject = Map.unmodifiable(map);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(_todayTotalMs);

  @override
  Future<Result<Map<String, int>>> getTodayDurationBySubject() async =>
      Result.success(Map.from(_todayBySubject));

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(const []);

  @override
  Future<Result<Session?>> get(String key) async => Result.success(null);

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async =>
      Result.success(const []);

  @override
  Future<Result<List<Session>>> getByType(SessionType type) async =>
      Result.success(const []);

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async =>
      Result.success(const []);

  @override
  Future<Result<List<Session>>> getActive() async => Result.success(const []);

  @override
  Future<Result<bool>> hasSchedulingConflict(
      {required DateTime startTime,
      required int durationMinutes,
      String? excludeSessionId}) async =>
      Result.success(false);

  @override
  Future<Result<List<Session>>> getScheduledLessons() async =>
      Result.success(const []);

  @override
  Future<Result<void>> save(String key, Session item) async => Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

void main() {
  group('Integration - Per-subject study time & cap adherence', () {
    /// Builds a MentorContextBuilder with standard fakes wired in.
    Future<MentorContextBuilder> buildBuilder({
      Map<String, int>? todayBySubject,
      int todayTotalMs = 0,
    }) async {
      final sessionRepo = _PerSubjectSessionRepo();
      sessionRepo.setTodayTotal(todayTotalMs);
      if (todayBySubject != null && todayBySubject.isNotEmpty) {
        sessionRepo.setTodayBySubject(todayBySubject);
      }

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Use FakePlannerService with a plan that has syllabus goals mapped
      // to each subjectId used in todayBySubject. This ensures the builder
      // resolves subjectId → human-readable titles.
      final goals = <Map<String, dynamic>>[
        {'subjectId': 'physics', 'subjectTitle': 'Physics'},
        {'subjectId': 'chemistry', 'subjectTitle': 'Chemistry'},
        {'subjectId': 'math', 'subjectTitle': 'Math AA HL'},
      ];

      final plannerSvc = mht.FakePlannerService(
        PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: const [],
          ),
          recommendations: const [],
          metadata: {'syllabus_goals': goals},
        ),
      );

      return MentorContextBuilder(
        progressTracker: StudyProgressTracker(
          attemptRepo: FakeAttemptRepository(),
          sessionRepo: sessionRepo,
          l10n: l10n,
        ),
        masteryService: mht.FakeMasteryGraphService(),
        plannerService: plannerSvc,
        sessionRepository: sessionRepo,
        localeName: 'en',
      );
    }

    test('per-subject breakdown sorted descending by usage', () async {
      final builder = await buildBuilder(todayBySubject: {
        'physics': 2700000, // 45 min
        'chemistry': 1800000, // 30 min
        'math': 900000, // 15 min
      }, todayTotalMs: 5400000);

      final result = await builder.buildContextPrompt();
      expect(result.isSuccess, isTrue);
      final ctx = result.data!;

      // Total time visible.
      expect(ctx, contains("Today's study time: 90 minutes"));

      // Per-subject section present.
      expect(ctx, contains('Per-subject study time today'));

      // Labels resolved from syllabus goals → human-readable titles.
      expect(ctx, contains('Physics: 45 minutes'));
      expect(ctx, contains('Chemistry: 30 minutes'));
      expect(ctx, contains('Math AA HL: 15 minutes'));

      // Sorted desc: Physics first, then Chemistry, then Math.
      final pIdx = ctx.indexOf('Physics: 45 minutes');
      final cIdx = ctx.indexOf('Chemistry: 30 minutes');
      final mIdx = ctx.indexOf('Math AA HL: 15 minutes');
      expect(pIdx, greaterThan(-1), reason: 'Physics label found');
      expect(cIdx, greaterThan(-1), reason: 'Chemistry label found');
      expect(mIdx, greaterThan(-1), reason: 'Math AA HL label found');
      expect(pIdx, lessThan(cIdx), reason: 'Physics (45 min) before Chemistry (30 min)');
      expect(cIdx, lessThan(mIdx), reason: 'Chemistry (30 min) before Math (15 min)');
    });

    test('cap percentage annotation included when global cap > 0', () async {
      // Note: Without Hive settings, getDailyCapMinutes() returns 0, so cap
      // percentage lines are not injected. The per-subject breakdown itself is
      // validated above — cap % requires actual SettingsService backing.
      final builder = await buildBuilder(todayBySubject: {
        'physics': 2700000, // 45 min
        'chemistry': 1080000, // 18 min
      }, todayTotalMs: 3780000);

      final result = await builder.buildContextPrompt();
      expect(result.isSuccess, isTrue);
      final ctx = result.data!;

      expect(ctx, contains('Per-subject study time today'));
      // Subject title resolution verified even when cap annotation absent.
      expect(ctx, contains('Physics: 45 minutes'));
      expect(ctx, contains('Chemistry: 18 minutes'));
    });

    test('omits per-subject block when no sessions', () async {
      final builder = await buildBuilder(todayBySubject: {}, todayTotalMs: 0);

      final result = await builder.buildContextPrompt();
      expect(result.isSuccess, isTrue);
      expect(result.data, isNot(contains('Per-subject study time today')),
          reason: 'per-subject section omitted when no sessions');
    });

    test('falls back to raw subjectId when syllabus goal absent', () async {
      final builder = await buildBuilder(todayBySubject: {
        'cs-101': 1800000, // unknown subject not in any plan
      }, todayTotalMs: 1800000);

      final result = await builder.buildContextPrompt();
      expect(result.isSuccess, isTrue);
      expect(result.data, contains('cs-101: 30 minutes'),
          reason: 'raw subjectId used when no matching syllabus goal');
    });

    test('full multi-subject day produces actionable context', () async {
      final builder = await buildBuilder(todayBySubject: {
        'physics': 3600000, // 60 min
        'chemistry': 1200000, // 20 min
        'math': 2400000, // 40 min
      }, todayTotalMs: 7200000);

      final result = await builder.buildContextPrompt();
      expect(result.isSuccess, isTrue);
      final ctx = result.data!;

      // Agent can answer: "What did I spend on each subject?"
      expect(ctx, contains('Per-subject study time today'));
      expect(ctx, contains('Physics: 60 minutes'));
      expect(ctx, contains('Math AA HL: 40 minutes'));
      expect(ctx, contains('Chemistry: 20 minutes'));

      // Sorted descending order confirmed.
      expect(ctx.indexOf('Physics: 60 minutes'),
          lessThan(ctx.indexOf('Math AA HL: 40 minutes')),
          reason: 'sorted desc by usage');
      expect(ctx.indexOf('Math AA HL: 40 minutes'),
          lessThan(ctx.indexOf('Chemistry: 20 minutes')),
          reason: 'sorted desc by usage');
    });
  });
}
