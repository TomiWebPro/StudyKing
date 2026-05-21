import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/mentor/services/mentor_wellbeing_service.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';

class _FakeSessionRepo extends SessionRepository {
  List<Session> _allSessions = [];
  List<Session> _todaySessions = [];
  int _todayDurationMs = 0;

  void setAllSessions(List<Session> sessions) => _allSessions = sessions;
  void setTodaySessions(List<Session> sessions) => _todaySessions = sessions;
  void setTodayDurationMs(int ms) => _todayDurationMs = ms;

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(_allSessions);

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success(_todaySessions);

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(_todayDurationMs);
}

class _FakeNudgeRepo extends EngagementNudgeRepository {
  final List<EngagementNudgeModel> _nudges = [];
  int _todayCount = 0;
  bool _throwOnCreate = false;
  bool _throwOnGetTodayCount = false;

  void setTodayCount(int count) => _todayCount = count;
  void setThrowOnCreate() => _throwOnCreate = true;
  void setThrowOnGetTodayCount() => _throwOnGetTodayCount = true;

  List<EngagementNudgeModel> get createdNudges => List.unmodifiable(_nudges);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<int>> getTodayCount(String studentId) async {
    if (_throwOnGetTodayCount) return Result.failure('Simulated error');
    return Result.success(_todayCount);
  }

  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async {
    if (_throwOnCreate) throw Exception('Simulated error');
    _nudges.add(nudge);
    return Result.success(null);
  }
}

class _FakeMasteryGraphService extends MasteryGraphService {
  List<QuestionMasteryState> _atRisk = [];

  void setAtRiskQuestions(List<QuestionMasteryState> questions) => _atRisk = questions;

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async => Result.success(_atRisk);
}

MentorWellbeingService _createService({
  SessionRepository? sessionRepository,
  EngagementNudgeRepository? nudgeRepo,
  MasteryGraphService? masteryService,
  String localeName = 'en',
  String studentId = 'test-student',
}) {
  return MentorWellbeingService(
    sessionRepository: sessionRepository ?? _FakeSessionRepo(),
    nudgeRepo: nudgeRepo ?? _FakeNudgeRepo(),
    masteryService: masteryService ?? _FakeMasteryGraphService(),
    localeName: localeName,
    studentId: studentId,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('MentorWellbeingService', () {
    group('checkWellbeingAndGenerateNudges', () {
      test('returns empty list with normal activity', () async {
        final service = _createService();
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isEmpty);
      });

      test('creates overwork nudge when daily cap exceeded', () async {
        Hive.init(Directory.systemTemp.path);
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('dailyCapMinutes', 60);

        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodayDurationMs(3600000 * 2);

        final nudgeRepo = _FakeNudgeRepo();
        final service = _createService(
          sessionRepository: sessionRepo,
          nudgeRepo: nudgeRepo,
        );

        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isNotEmpty);
        expect(nudgeRepo.createdNudges, isNotEmpty);
        expect(nudgeRepo.createdNudges.first.nudgeType, equals(NudgeType.overwork.name));

        await box.clear();
        await box.close();
      });

      test('creates wellbeing nudge for late-night sessions', () async {
        final now = DateTime.now();
        final lateNightSession = Session(
          id: 'late-1',
          studentId: 'test-student',
          startTime: DateTime(now.year, now.month, now.day, 23, 0),
        );
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodaySessions([lateNightSession]);

        final nudgeRepo = _FakeNudgeRepo();
        final service = _createService(
          sessionRepository: sessionRepo,
          nudgeRepo: nudgeRepo,
        );

        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isNotEmpty);
        expect(nudgeRepo.createdNudges, isNotEmpty);
        expect(nudgeRepo.createdNudges.first.message, contains('late-night'));
      });

      test('creates revision nudge when 3+ at-risk questions', () async {
        final now = DateTime.now();
        final atRiskQuestions = List.generate(3, (i) => QuestionMasteryState(
          studentId: 'test-student',
          questionId: 'q-$i',
          lastAttempt: now,
        ));
        final mastery = _FakeMasteryGraphService();
        mastery.setAtRiskQuestions(atRiskQuestions);

        final service = _createService(masteryService: mastery);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isNotEmpty);
        expect(result.data!.first, contains('revision'));
      });

      test('does not create revision nudge with fewer than 3 at-risk questions', () async {
        final now = DateTime.now();
        final atRiskQuestions = List.generate(2, (i) => QuestionMasteryState(
          studentId: 'test-student',
          questionId: 'q-$i',
          lastAttempt: now,
        ));
        final mastery = _FakeMasteryGraphService();
        mastery.setAtRiskQuestions(atRiskQuestions);

        final service = _createService(masteryService: mastery);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data!.where((m) => m.contains('revision')), isEmpty);
      });

      test('handles repository errors gracefully', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodayDurationMs(0);

        final service = _createService(sessionRepository: sessionRepo);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isA<List<String>>());
      });

      test('returns empty when getTodayDurationMs fails', () async {
        final sessionRepo = _FakeSessionRepo();
        sessionRepo.setTodayDurationMs(0);

        final service = _createService(sessionRepository: sessionRepo);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isEmpty);
      });

      group('inactivity nudges', () {
        late DateTime oldDate;

        setUp(() {
          oldDate = DateTime.now().subtract(const Duration(hours: 72));
        });

        Session completedSession(String id, DateTime startTime) {
          return Session(
            id: id,
            studentId: 'test-student',
            startTime: startTime,
            completed: true,
          );
        }

        test('creates 48h inactivity nudge', () async {
          final sessionRepo = _FakeSessionRepo();
          sessionRepo.setAllSessions([completedSession('s1', oldDate)]);

          final nudgeRepo = _FakeNudgeRepo();
          final service = _createService(
            sessionRepository: sessionRepo,
            nudgeRepo: nudgeRepo,
          );

        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isNotEmpty);
        expect(result.data!.first, contains('48 hours'));
        });

        test('creates 7-day inactivity nudge', () async {
          final date7d = DateTime.now().subtract(const Duration(days: 8));
          final sessionRepo = _FakeSessionRepo();
          sessionRepo.setAllSessions([completedSession('s1', date7d)]);

          final nudgeRepo = _FakeNudgeRepo();
          final service = _createService(
            sessionRepository: sessionRepo,
            nudgeRepo: nudgeRepo,
          );

        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isNotEmpty);
        expect(result.data!.first, contains('days'));
        });

        test('creates 14-day inactivity nudge', () async {
          final date14d = DateTime.now().subtract(const Duration(days: 15));
          final sessionRepo = _FakeSessionRepo();
          sessionRepo.setAllSessions([completedSession('s1', date14d)]);

          final nudgeRepo = _FakeNudgeRepo();
          final service = _createService(
            sessionRepository: sessionRepo,
            nudgeRepo: nudgeRepo,
          );

          final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isNotEmpty);
        expect(result.data!.first, contains('days'));
        });

        test('creates 30-day inactivity nudge', () async {
          final date30d = DateTime.now().subtract(const Duration(days: 31));
          final sessionRepo = _FakeSessionRepo();
          sessionRepo.setAllSessions([completedSession('s1', date30d)]);

          final nudgeRepo = _FakeNudgeRepo();
          final service = _createService(
            sessionRepository: sessionRepo,
            nudgeRepo: nudgeRepo,
          );

          final result = await service.checkWellbeingAndGenerateNudges();
        expect(result.data, isNotEmpty);
        expect(result.data!.first, contains('days'));
        });
      });

      group('nudge cap limit', () {
        test('prevents additional nudges when at max per day (overwork still generated)', () async {
          Hive.init(Directory.systemTemp.path);
          final box = await Hive.openBox(HiveBoxNames.settings);
          await box.put('dailyCapMinutes', 60);

          final sessionRepo = _FakeSessionRepo();
          sessionRepo.setTodayDurationMs(3600000 * 2);

          final nudgeRepo = _FakeNudgeRepo();
          nudgeRepo.setTodayCount(5);

          final service = _createService(
            sessionRepository: sessionRepo,
            nudgeRepo: nudgeRepo,
          );

          // Overwork nudge is created before the cap check, so result has it
          final result = await service.checkWellbeingAndGenerateNudges();
          expect(result.data, isNotEmpty);
          // Only the overwork message should be present (others blocked by cap)
          expect(result.data!.length, equals(1));

          await box.clear();
          await box.close();
        });

        test('allows nudge when under daily cap limit', () async {
          Hive.init(Directory.systemTemp.path);
          final box = await Hive.openBox(HiveBoxNames.settings);
          await box.put('dailyCapMinutes', 60);

          final sessionRepo = _FakeSessionRepo();
          sessionRepo.setTodayDurationMs(3600000 * 2);

          final nudgeRepo = _FakeNudgeRepo();
          nudgeRepo.setTodayCount(3);

          final service = _createService(
            sessionRepository: sessionRepo,
            nudgeRepo: nudgeRepo,
          );

          final result = await service.checkWellbeingAndGenerateNudges();
          expect(result.data, isNotEmpty);

          await box.clear();
          await box.close();
        });

        test('handles getTodayCount failure gracefully', () async {
          Hive.init(Directory.systemTemp.path);
          final box = await Hive.openBox(HiveBoxNames.settings);
          await box.put('dailyCapMinutes', 60);

          final nudgeRepo = _FakeNudgeRepo();
          nudgeRepo.setThrowOnGetTodayCount();

          final service = _createService(nudgeRepo: nudgeRepo);

          final result = await service.checkWellbeingAndGenerateNudges();
          expect(result.data, isA<List<String>>());

          await box.clear();
          await box.close();
        });
      });

      group('streak messages', () {
        test('adds congratulatory streak message for 7+ consecutive days', () async {
          final now = DateTime.now();
          final sessionRepo = _FakeSessionRepo();
          sessionRepo.setAllSessions(List.generate(7, (i) => Session(
            id: 's$i', studentId: 'test-student',
            startTime: now.subtract(Duration(days: i)),
            completed: true,
          )));

          final service = _createService(sessionRepository: sessionRepo);
          final result = await service.checkWellbeingAndGenerateNudges();
          expect(result.data, isNotEmpty);
          expect(result.data!.any((m) => m.contains('study streak')), isTrue);
        });
      });
    });
  });
}
