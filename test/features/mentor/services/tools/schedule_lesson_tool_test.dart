import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:studyking/features/mentor/services/tools/schedule_lesson_tool.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'test_helpers.dart';

void main() {
  group('ScheduleLessonTool', () {
    late FakePlannerService planner;

    setUpAll(() async {
      await AppLocalizations.delegate.load(const Locale('en'));
    });

    setUp(() => planner = FakePlannerService());

    test('returns success when the lesson is scheduled', () async {
      planner.scheduleResult = true;
      final tool = ScheduleLessonTool(
        plannerService: planner,
        localeName: 'en',
      );

      final scheduledTime = DateTime.now();
      final result = await tool.execute({
        'topicId': 't1',
        'topicTitle': 'Algebra',
        'subjectId': 's1',
        'scheduledTime': scheduledTime.toIso8601String(),
      });

      expect(result['success'], isTrue);
      expect(result['message'], isA<String>());
      expect(planner.scheduleLessonCallCount, 1);
      expect(planner.lastScheduledTime, scheduledTime);
    });

    test('reports failure when scheduling does not succeed', () async {
      planner.scheduleResult = false;
      final tool = ScheduleLessonTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'topicId': 't1',
        'topicTitle': 'Algebra',
        'subjectId': 's1',
        'scheduledTime': DateTime.now().toIso8601String(),
      });

      expect(result['success'], isFalse);
      expect(result['message'], isA<String>());
      expect(planner.scheduleLessonCallCount, 1);
    });

    test('returns validation failure for a relative date string',
        () async {
      final tool = ScheduleLessonTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'topicId': 't1',
        'topicTitle': 'Algebra',
        'subjectId': 's1',
        'scheduledTime': 'tomorrow 5pm',
      });

      expect(result['success'], isFalse);
      expect(
        result['message'],
        lookupAppLocalizations(const Locale('en'))
            .toolScheduleLessonInvalidTime,
      );
      expect(planner.scheduleLessonCallCount, 0);
    });

    test('returns validation failure for a non-ISO date string', () async {
      final tool = ScheduleLessonTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'topicId': 't1',
        'topicTitle': 'Algebra',
        'subjectId': 's1',
        'scheduledTime': 'not-a-date',
      });

      expect(result['success'], isFalse);
      expect(result['message'], isA<String>());
      expect(planner.scheduleLessonCallCount, 0);
    });

    test('returns validation failure when scheduledTime is missing',
        () async {
      final tool = ScheduleLessonTool(
        plannerService: planner,
        localeName: 'en',
      );

      final result = await tool.execute({
        'topicId': 't1',
        'topicTitle': 'Algebra',
        'subjectId': 's1',
      });

      expect(result['success'], isFalse);
      expect(result['message'], isA<String>());
      expect(planner.scheduleLessonCallCount, 0);
    });
  });
}
