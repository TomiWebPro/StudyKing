import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/mentor/services/tools/get_adherence_trends_tool.dart';
import 'test_helpers.dart';

PlanAdherenceModel _record(int dayOffset, double adherence) {
  final now = DateTime.now();
  return PlanAdherenceModel(
    id: 'rec-$dayOffset',
    studentId: 'student-1',
    date: now.subtract(Duration(days: dayOffset + 1)),
    plannedQuestions: 10,
    actualQuestions: (adherence * 10).round(),
    plannedMinutes: 60,
    actualMinutes: (adherence * 60).round(),
    adherenceScore: adherence,
  );
}

void main() {
  group('GetAdherenceTrendsTool', () {
    late FakeStudentIdService studentIdService;
    late FakePlanAdherenceOrchestrator orchestrator;
    late FakePlanAdherenceRepository repo;

    setUp(() {
      studentIdService = FakeStudentIdService('student-1');
    });

    test('returns structured output with correct fields for real data',
        () async {
      final records = <PlanAdherenceModel>[
        _record(7, 0.1),
        _record(6, 0.2),
        _record(5, 0.3),
        _record(4, 0.4),
        _record(3, 0.6),
        _record(2, 0.7),
        _record(1, 0.8),
        _record(0, 0.9),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['averageAdherence'], isA<double>());
      expect(result['trend'], equals('improving'));
      expect(result['totalDays'], equals(8));
      expect(result['missedDays'], equals(0));
      expect(result['lowAdherenceDays'], isA<List>());
      expect(result['perDayBreakdown'], isA<List>());
      expect(result['weeklyAdherence'], isA<List>());
      expect(result['recommendation'], isA<String>());
      // perDayBreakdown is ordered most-recent first.
      final breakdown = result['perDayBreakdown'] as List;
      expect(breakdown.length, equals(8));
      expect(breakdown.first['adherence'], equals(0.9));
    });

    test('locks the 2-decimal rounding behavior for averageAdherence',
        () async {
      final records = <PlanAdherenceModel>[
        _record(2, 0.111),
        _record(1, 0.222),
        _record(0, 0.333),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'days': 14});

      final trueAvg = records.fold<double>(0.0, (s, m) => s + m.adherenceScore) /
          records.length;
      final expectedRounded = double.parse(trueAvg.toStringAsFixed(2));
      expect(result['averageAdherence'], equals(expectedRounded));
      expect(result['averageAdherence'], isNot(equals(trueAvg)));
    });

    test('locks the 2-decimal rounding for weekly buckets', () async {
      // 8 records -> 2 weekly buckets (first 7, last 1).
      final records = <PlanAdherenceModel>[
        _record(7, 0.111),
        _record(6, 0.222),
        _record(5, 0.333),
        _record(4, 0.444),
        _record(3, 0.555),
        _record(2, 0.666),
        _record(1, 0.777),
        _record(0, 0.888),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});
      final buckets = result['weeklyAdherence'] as List<double>;
      expect(buckets.length, equals(2));
      final first7 = records.sublist(0, 7);
      final expectedFirst = double.parse(
        (first7.fold<double>(0.0, (s, m) => s + m.adherenceScore) / 7)
            .toStringAsFixed(2),
      );
      expect(buckets.first, equals(expectedFirst));
    });

    test('degrades gracefully with no data (no throw)', () async {
      repo = FakePlanAdherenceRepository(const []);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['averageAdherence'], equals(0.0));
      expect(result['trend'], equals('insufficient_data'));
      expect(result['totalDays'], equals(0));
      expect(result['perDayBreakdown'], equals([]));
      expect(result['recommendation'], contains('No adherence data'));
    });
  });
}
