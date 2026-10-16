import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:studyking/features/mentor/services/tools/schedule_rest_day_tool.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'test_helpers.dart';

void main() {
  group('ScheduleRestDayTool', () {
    late FakePlannerService planner;

    setUpAll(() async {
      await AppLocalizations.delegate.load(const Locale('en'));
    });

    setUp(() => planner = FakePlannerService());

    test('marks the day as a rest day and reports success', () async {
      planner.markRestDayResult = true;
      final tool = ScheduleRestDayTool(
        plannerService: planner,
        localeName: 'en',
      );

      final date = DateTime(2026, 1, 31);
      final result = await tool.execute({
        'date': date.toIso8601String(),
      });

      expect(result['success'], isTrue);
      expect(result['message'], isA<String>());
      expect(result['date'], date.toIso8601String());
      expect(planner.markRestDayCallCount, 1);
      expect(planner.lastMarkRestDayDate, date);
    });

    test('reports failure when the date has no matching daily plan', () async {
      planner.markRestDayResult = true;
      planner.markRestDayNoMatch = true;
      final tool = ScheduleRestDayTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'date': DateTime(2026, 2, 15).toIso8601String(),
      });

      expect(result['success'], isFalse);
      expect(result['message'], isA<String>());
      expect(planner.markRestDayCallCount, 1);
    });

    test('returns validation failure for an unparseable date', () async {
      final tool = ScheduleRestDayTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'date': 'not-a-date',
      });

      expect(result['success'], isFalse);
      expect(
        result['message'],
        lookupAppLocalizations(const Locale('en')).toolScheduleRestDayInvalidDate,
      );
      expect(planner.markRestDayCallCount, 0);
    });

    test('returns validation failure when date is missing', () async {
      final tool = ScheduleRestDayTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({});

      expect(result['success'], isFalse);
      expect(result['message'], isA<String>());
      expect(planner.markRestDayCallCount, 0);
    });

    test('does not alter the plan when date is missing', () async {
      planner.markRestDayResult = true;
      final tool = ScheduleRestDayTool(
        plannerService: planner,
        localeName: 'en',
      );

      await tool.execute({});

      expect(planner.markRestDayCallCount, 0);
      expect(planner.lastMarkRestDayDate, isNull);
    });
  });
}
