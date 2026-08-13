import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/mentor/services/tools/get_adherence_trends_tool.dart';
import '../../../../helpers/fakes.dart';

class _FakeAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];

  _FakeAdherenceRepo() : super();

  void addRecord(PlanAdherenceModel record) => _records.add(record);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<PlanAdherenceModel>>> getByDateRange(
      String studentId, DateTime start, DateTime end) async {
    return Result.success(
      _records
          .where((m) =>
              m.studentId == studentId &&
              m.date.isAfter(start) &&
              m.date.isBefore(end))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getByStudent(
      String studentId) async {
    return Result.success(
      _records.where((m) => m.studentId == studentId).toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getWeekly(
      String studentId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getByDateRange(studentId, weekAgo, now);
  }
}

/// A minimal orchestrator subclass that allows injecting a fake adherence
/// repository via the overridden getter so the tool's execute() can be tested
/// end-to-end without Hive.
class _TestOrchestrator extends PlanAdherenceOrchestrator {
  final _FakeAdherenceRepo _fakeRepo;

  _TestOrchestrator(this._fakeRepo)
      : super(
          adherenceRepository: null,
          planRepository: null,
          planService: null,
          masteryService: null,
          l10n: null,
        );

  @override
  PlanAdherenceRepository get adherenceRepository => _fakeRepo;
}

PlanAdherenceModel _record({
  required String studentId,
  required DateTime date,
  double adherenceScore = 0.8,
  int plannedMinutes = 60,
  int actualMinutes = 48,
  int plannedQuestions = 20,
  int actualQuestions = 16,
}) {
  return PlanAdherenceModel(
    id: 'rec-${date.millisecondsSinceEpoch}',
    studentId: studentId,
    date: date,
    adherenceScore: adherenceScore,
    plannedMinutes: plannedMinutes,
    actualMinutes: actualMinutes,
    plannedQuestions: plannedQuestions,
    actualQuestions: actualQuestions,
  );
}

void main() {
  group('GetAdherenceTrendsTool', () {
    late FakeStudentIdService fakeStudentId;
    late GetAdherenceTrendsTool tool;

    setUp(() {
      fakeStudentId = FakeStudentIdService()..setStudentId('student-1');
    });

    test('name returns get_adherence_trends', () {
      final fakeRepo = _FakeAdherenceRepo();
      final orchestrator = _TestOrchestrator(fakeRepo);
      tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: fakeStudentId,
      );
      expect(tool.name, 'get_adherence_trends');
    });

    test('description is not empty', () {
      final fakeRepo = _FakeAdherenceRepo();
      final orchestrator = _TestOrchestrator(fakeRepo);
      tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: fakeStudentId,
      );
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final fakeRepo = _FakeAdherenceRepo();
      final orchestrator = _TestOrchestrator(fakeRepo);
      tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: fakeStudentId,
      );
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect((params['properties'] as Map).containsKey('days'), isTrue);
      expect(params['required'], []);
    });
  });

  group('GetAdherenceTrendsTool - execute', () {
    late FakeStudentIdService fakeStudentId;
    late _FakeAdherenceRepo fakeRepo;
    late _TestOrchestrator fakeOrchestrator;
    late GetAdherenceTrendsTool tool;

    setUp(() {
      fakeStudentId = FakeStudentIdService()..setStudentId('student-1');
      fakeRepo = _FakeAdherenceRepo();
      fakeOrchestrator = _TestOrchestrator(fakeRepo);
      tool = GetAdherenceTrendsTool(
        orchestrator: fakeOrchestrator,
        studentIdService: fakeStudentId,
      );
    });

    test('returns insufficient_data when no records exist', () async {
      final result = await tool.execute({});

      expect(result['averageAdherence'], 0.0);
      expect(result['trend'], 'insufficient_data');
      expect(result['lowAdherenceDays'], isEmpty);
      expect(result['missedDays'], 0);
      expect(result['totalDays'], 0);
      expect(result['perDayBreakdown'], isEmpty);
      expect(result['recommendation'], contains('No adherence data'));
    });

    test('computes average adherence correctly', () async {
      final now = DateTime.now();
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 1)),
        adherenceScore: 0.6,
      ));
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 2)),
        adherenceScore: 0.8,
      ));

      final result = await tool.execute({'days': 14});

      expect(result['averageAdherence'], closeTo(0.7, 0.01));
      expect(result['totalDays'], 2);
    });

    test('identifies low adherence days', () async {
      final now = DateTime.now();
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 1)),
        adherenceScore: 0.3,
      ));
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 2)),
        adherenceScore: 0.9,
      ));

      final result = await tool.execute({'days': 14});

      expect(result['lowAdherenceDays'], hasLength(1));
    });

    test('counts missed days correctly', () async {
      final now = DateTime.now();
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 1)),
        adherenceScore: 0.0,
      ));
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 2)),
        adherenceScore: 0.0,
      ));
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 3)),
        adherenceScore: 0.7,
      ));

      final result = await tool.execute({'days': 14});

      expect(result['missedDays'], 2);
    });

    test('computes trend as declining when second half worse', () async {
      final now = DateTime.now();
      for (var i = 8; i <= 13; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.9,
        ));
      }
      for (var i = 1; i <= 6; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.3,
        ));
      }

      final result = await tool.execute({'days': 14});

      expect(result['trend'], 'declining');
    });

    test('computes trend as improving when second half better', () async {
      final now = DateTime.now();
      for (var i = 8; i <= 13; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.3,
        ));
      }
      for (var i = 1; i <= 6; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.9,
        ));
      }

      final result = await tool.execute({'days': 14});

      expect(result['trend'], 'improving');
    });

    test('computes trend as steady when both halves similar', () async {
      final now = DateTime.now();
      for (var i = 8; i <= 13; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.7,
        ));
      }
      for (var i = 1; i <= 6; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.7,
        ));
      }

      final result = await tool.execute({'days': 14});

      expect(result['trend'], 'steady');
    });

    test('returns per-day breakdown with correct fields', () async {
      final now = DateTime.now();
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 1)),
        adherenceScore: 0.75,
        plannedMinutes: 90,
        actualMinutes: 67,
        plannedQuestions: 30,
        actualQuestions: 22,
      ));

      final result = await tool.execute({'days': 14});
      final breakdown = result['perDayBreakdown'] as List;

      expect(breakdown, hasLength(1));
      expect(breakdown[0]['plannedMinutes'], 90);
      expect(breakdown[0]['actualMinutes'], 67);
      expect(breakdown[0]['plannedQuestions'], 30);
      expect(breakdown[0]['actualQuestions'], 22);
      expect(breakdown[0]['adherence'], 0.75);
    });

    test('returns weeklyAdherence buckets', () async {
      final now = DateTime.now();
      for (var i = 1; i <= 14; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: i <= 7 ? 0.6 : 0.9,
        ));
      }

      final result = await tool.execute({'days': 20});
      final weekly = result['weeklyAdherence'] as List;

      expect(weekly, hasLength(2));
      expect((weekly[0] as num).toDouble(), closeTo(0.9, 0.05));
      expect((weekly[1] as num).toDouble(), closeTo(0.6, 0.05));
    });

    test('recommendation for declining trend mentions action', () async {
      final now = DateTime.now();
      for (var i = 8; i <= 13; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.9,
        ));
      }
      for (var i = 1; i <= 3; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.0,
        ));
      }

      final result = await tool.execute({'days': 14});

      expect(result['trend'], 'declining');
      expect(result['recommendation'], contains('declining'));
    });

    test('recommendation for improving trend is encouraging', () async {
      final now = DateTime.now();
      for (var i = 8; i <= 13; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.3,
        ));
      }
      for (var i = 1; i <= 6; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.9,
        ));
      }

      final result = await tool.execute({'days': 14});

      expect(result['trend'], 'improving');
      expect(result['recommendation'], contains('improving'));
    });

    test('uses default days of 14', () async {
      final now = DateTime.now();
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 1)),
        adherenceScore: 0.8,
      ));

      final result = await tool.execute({});

      expect(result['totalDays'], 1);
    });

    test('respects custom days parameter', () async {
      final now = DateTime.now();
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 3)),
        adherenceScore: 0.8,
      ));
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 10)),
        adherenceScore: 0.6,
      ));

      final result = await tool.execute({'days': 7});

      expect(result['totalDays'], 1);
    });

    test('filters by student ID', () async {
      final now = DateTime.now();
      fakeRepo.addRecord(_record(
        studentId: 'student-1',
        date: now.subtract(const Duration(days: 1)),
        adherenceScore: 0.8,
      ));
      fakeRepo.addRecord(_record(
        studentId: 'other-student',
        date: now.subtract(const Duration(days: 1)),
        adherenceScore: 0.3,
      ));

      final result = await tool.execute({'days': 14});

      expect(result['totalDays'], 1);
    });

    test('recommendation for steady with low days warns', () async {
      final now = DateTime.now();
      for (var i = 1; i <= 10; i++) {
        fakeRepo.addRecord(_record(
          studentId: 'student-1',
          date: now.subtract(Duration(days: i)),
          adherenceScore: 0.3,
        ));
      }

      final result = await tool.execute({'days': 14});

      expect(result['trend'], 'steady');
      expect(result['recommendation'], contains('low-adherence'));
    });
  });
}
