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

      final result = await tool.execute({
        'topicId': 't1',
        'topicTitle': 'Algebra',
        'subjectId': 's1',
        'scheduledTime': DateTime.now().toIso8601String(),
      });

      expect(result['success'], isTrue);
      expect(result['message'], isA<String>());
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
    });
  });
}
