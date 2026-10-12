import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/mentor/services/tools/get_adherence_trends_tool.dart';
import 'test_helpers.dart';

DateTime _startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

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

PlanAdherenceModel _recordAt(String id, DateTime date, double adherence) {
  return PlanAdherenceModel(
    id: id,
    studentId: 'student-1',
    date: date,
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

    group('architecture boundary', () {
      test('tool does not import other features', () {
        // Regression guard for the feature→feature import rule enforced by
        // test/architecture/architectural_constraints_test.dart:
        // the adherence-trends tool may only depend on core and its own
        // feature. Records are read through the core
        // PlanAdherenceOrchestrator and projected into a private snapshot.
        final source = File(
          'lib/features/mentor/services/tools/get_adherence_trends_tool.dart',
        ).readAsStringSync();
        final featureImports = RegExp(
          r"""import ['"]package:studyking/features/(\w+)/""",
        ).allMatches(source);
        expect(featureImports, isEmpty);
      });
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

      // Each calendar day's adherence is re-derived from its summed
      // actuals against the day's plan targets, then days are
      // averaged once each.
      final dayScores = records.map((m) => calculateAdherenceScore(
            plannedQuestions: m.plannedQuestions,
            actualQuestions: m.actualQuestions,
            plannedMinutes: m.plannedMinutes,
            actualMinutes: m.actualMinutes,
          ));
      final trueAvg = dayScores.reduce((a, b) => a + b) / dayScores.length;
      final expectedRounded = double.parse(trueAvg.toStringAsFixed(2));
      expect(result['averageAdherence'], equals(expectedRounded));
      expect(result['averageAdherence'], isNot(equals(trueAvg)));
    });

    test('locks the 2-decimal rounding for weekly buckets', () async {
      // Records pinned to explicit calendar weeks so the expected
      // bucketing is deterministic: two days in the week two weeks
      // back and two days last week -> two buckets (oldest first).
      final thisMonday = _startOfWeek(DateTime.now());
      final lastWeekMonday = thisMonday.subtract(const Duration(days: 7));
      final twoWeeksAgoMonday =
          thisMonday.subtract(const Duration(days: 14));
      final records = <PlanAdherenceModel>[
        _recordAt('w1a', twoWeeksAgoMonday, 0.111),
        _recordAt(
          'w1b',
          twoWeeksAgoMonday.add(const Duration(days: 2)),
          0.222,
        ),
        _recordAt('w2a', lastWeekMonday, 0.333),
        _recordAt(
          'w2b',
          lastWeekMonday.add(const Duration(days: 1)),
          0.444,
        ),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'days': 30});
      final buckets = result['weeklyAdherence'] as List<double>;
      expect(buckets.length, equals(2));

      double dayScore(PlanAdherenceModel m) => calculateAdherenceScore(
            plannedQuestions: m.plannedQuestions,
            actualQuestions: m.actualQuestions,
            plannedMinutes: m.plannedMinutes,
            actualMinutes: m.actualMinutes,
          );

      final expectedFirst = double.parse(
        ((dayScore(records[0]) + dayScore(records[1])) / 2)
            .toStringAsFixed(2),
      );
      final expectedSecond = double.parse(
        ((dayScore(records[2]) + dayScore(records[3])) / 2)
            .toStringAsFixed(2),
      );
      expect(buckets[0], equals(expectedFirst));
      expect(buckets[1], equals(expectedSecond));
    });

    test('sums same-day sessions into one day weighted once',
        () async {
      final day = DateTime.now().subtract(const Duration(days: 1)).dateOnly;
      // Two half-sessions on the same day: each is 5/10 questions
      // and 30/60 minutes (stored score 0.5 each).
      final records = <PlanAdherenceModel>[
        _recordAt('s1', day, 0.5),
        _recordAt('s2', day.add(const Duration(hours: 2)), 0.5),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      // One day, not two records.
      expect(result['totalDays'], equals(1));
      // The day's actuals are summed before scoring: across the two
      // sessions the student completed the full day plan.
      expect(result['averageAdherence'], equals(1.0));
      final breakdown = result['perDayBreakdown'] as List;
      expect(breakdown.length, equals(1));
      expect(breakdown.first['actualQuestions'], equals(10));
      expect(breakdown.first['actualMinutes'], equals(60));
      expect(breakdown.first['adherence'], equals(1.0));
    });

    test('lists each low-adherence date only once', () async {
      final day = DateTime.now().subtract(const Duration(days: 1)).dateOnly;
      // Two same-day records that aggregate to a low day (4/10
      // questions, 24/60 minutes -> adherence 0.4).
      final records = <PlanAdherenceModel>[
        _recordAt('l1', day, 0.2),
        _recordAt('l2', day.add(const Duration(hours: 1)), 0.2),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      final lowDays = result['lowAdherenceDays'] as List<String>;
      expect(lowDays.length, equals(1));
      expect(lowDays.toSet().length, equals(1));
      expect(lowDays.single, equals(
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      ));
    });

    test('missedDays counts distinct zero-score days', () async {
      final day1 = DateTime.now().subtract(const Duration(days: 2)).dateOnly;
      final day2 = DateTime.now().subtract(const Duration(days: 1)).dateOnly;
      final day3 = DateTime.now().subtract(const Duration(days: 3)).dateOnly;
      // Two zero-score records on day1, one on day2, and a healthy
      // day3: only two distinct days were missed.
      final records = <PlanAdherenceModel>[
        _recordAt('z1', day1, 0.0),
        _recordAt('z2', day1.add(const Duration(hours: 1)), 0.0),
        _recordAt('z3', day2, 0.0),
        _recordAt('ok', day3, 0.9),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['missedDays'], equals(2));
      expect(result['totalDays'], equals(3));
    });

    test('weekly buckets never straddle a calendar-week boundary',
        () async {
      // Four days at the start of one week and four days at the
      // start of the following week (both weeks fully in the past
      // so the repository's date-range filter keeps them regardless
      // of the current weekday): buckets must split exactly at the
      // week boundary, not chunk every 7 records.
      final thisMonday = _startOfWeek(DateTime.now());
      final earlyMonday = thisMonday.subtract(const Duration(days: 14));
      final lateMonday = thisMonday.subtract(const Duration(days: 7));
      final records = <PlanAdherenceModel>[
        // Start of the earlier week (Mon-Thu).
        _recordAt('e1', earlyMonday, 0.1),
        _recordAt('e2', earlyMonday.add(const Duration(days: 1)), 0.2),
        _recordAt('e3', earlyMonday.add(const Duration(days: 2)), 0.3),
        _recordAt('e4', earlyMonday.add(const Duration(days: 3)), 0.4),
        // Start of the following week (Mon-Thu).
        _recordAt('l1', lateMonday, 0.5),
        _recordAt('l2', lateMonday.add(const Duration(days: 1)), 0.6),
        _recordAt('l3', lateMonday.add(const Duration(days: 2)), 0.7),
        _recordAt('l4', lateMonday.add(const Duration(days: 3)), 0.8),
      ];
      repo = FakePlanAdherenceRepository(records);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'days': 30});
      final buckets = result['weeklyAdherence'] as List<double>;

      // Earlier week: (0.1 + 0.2 + 0.3 + 0.4) / 4 = 0.25. Following
      // week: (0.5 + 0.6 + 0.7 + 0.8) / 4 = 0.65. A 7-record chunk
      // would instead merge the earlier week with the first three
      // records of the following week (avg 0.4) and isolate the
      // last record (0.8).
      expect(buckets.length, equals(2));
      expect(buckets[0], equals(0.25));
      expect(buckets[1], equals(0.65));
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

    test('parses a stringified days argument without throwing',
        () async {
      final recent = _recordAt(
        'recent',
        DateTime.now().subtract(const Duration(hours: 3)),
        0.9,
      );
      final older = _recordAt(
        'older',
        DateTime.now().subtract(const Duration(days: 5)),
        0.5,
      );
      repo = FakePlanAdherenceRepository([recent, older]);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'days': '1'});

      // Only the record inside the parsed 1-day window is counted:
      // the string "1" must be honored, not crash the tool.
      expect(result['totalDays'], equals(1));
      expect(result['averageAdherence'], equals(0.9));
    });

    test('falls back to the default days when the argument is unparseable',
        () async {
      final recent = _recordAt(
        'recent',
        DateTime.now().subtract(const Duration(hours: 3)),
        0.9,
      );
      final older = _recordAt(
        'older',
        DateTime.now().subtract(const Duration(days: 5)),
        0.5,
      );
      repo = FakePlanAdherenceRepository([recent, older]);
      orchestrator = FakePlanAdherenceOrchestrator(repo);

      final tool = GetAdherenceTrendsTool(
        orchestrator: orchestrator,
        studentIdService: studentIdService,
      );

      // 'not-a-number' falls back to the documented default (14 days),
      // so both records are in range instead of the tool throwing.
      final result = await tool.execute({'days': 'not-a-number'});

      expect(result['totalDays'], equals(2));
    });
  });
}
