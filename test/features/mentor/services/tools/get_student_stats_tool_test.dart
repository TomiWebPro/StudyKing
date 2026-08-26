import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:studyking/features/mentor/services/tools/get_student_stats_tool.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'test_helpers.dart';

void main() {
  group('GetStudentStatsTool', () {
    late AppLocalizations l10n;
    late FakeStudentIdService studentIdService;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    setUp(() => studentIdService = FakeStudentIdService('student-1'));

    test('returns stats from the progress tracker', () async {
      final tracker = FakeStudyProgressTracker(l10n, {
        'totalAttempts': 50,
        'correctAttempts': 40,
        'accuracy': 80,
        'topicsStudied': 6,
        'weeklyActivity': 5,
        'totalStudyTimeHours': 12.5,
      });

      final tool = GetStudentStatsTool(
        progressTracker: tracker,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['totalAttempts'], equals(50));
      expect(result['correctAttempts'], equals(40));
      expect(result['accuracy'], equals(80));
      expect(result['topicsStudied'], equals(6));
      expect(result['weeklyActivity'], equals(5));
      expect(result['totalStudyTimeHours'], equals(12.5));
    });

    test('degrades gracefully when stats are empty (uses defaults)',
        () async {
      final tracker = FakeStudyProgressTracker(l10n, const {});

      final tool = GetStudentStatsTool(
        progressTracker: tracker,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['totalAttempts'], equals(0));
      expect(result['correctAttempts'], equals(0));
      expect(result['accuracy'], equals(0));
      expect(result['topicsStudied'], equals(0));
      expect(result['weeklyActivity'], equals(0));
      expect(result['totalStudyTimeHours'], equals(0));
    });
  });
}
