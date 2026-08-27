import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/providers/service_providers.dart' show studentIdServiceProvider;
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider, mentorProgressTrackerProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'mentor_screen_test_helpers.dart';

class ThrowingStudentIdService extends StudentIdService {
  @override
  Result<String> getStudentId() {
    throw Exception('RAW_EXCEPTION_SHOULD_NOT_APPEAR_HIVE_STACK');
  }
}

Widget _buildThrowingApp() {
  return ProviderScope(
    overrides: [
      studentIdServiceProvider.overrideWithValue(ThrowingStudentIdService()),
      llmServiceProvider.overrideWithValue(FakeLlmService()),
      settingsProvider.overrideWith(
        (ref) => SettingsController(FakeSettingsRepo()),
      ),
      plannerServiceProvider.overrideWithValue(FakePlannerService()),
      mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
      mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
      masteryGraphServiceProvider.overrideWithValue(FakeMasteryGraphService()),
      mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const MentorScreen(),
    ),
  );
}

void main() {
  group('MentorScreen init error generic message', () {
    testWidgets('catch path shows generic message and hides raw exception', (tester) async {
      await tester.pumpWidget(_buildThrowingApp());
      await tester.pumpAndSettle();

      // Generic l10n message should be visible
      expect(
        find.text('Failed to initialize mentor. Please check your API configuration in Settings and try again.'),
        findsOneWidget,
      );
      // Raw exception text must not leak to UI
      expect(find.textContaining('RAW_EXCEPTION_SHOULD_NOT_APPEAR'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('generic error card still offers retry and settings actions', (tester) async {
      await tester.pumpWidget(_buildThrowingApp());
      await tester.pumpAndSettle();

      // From _buildInitErrorCard: goToSettings and retry buttons exist
      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
