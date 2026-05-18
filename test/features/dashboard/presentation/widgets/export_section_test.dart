import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/dashboard/presentation/widgets/export_section.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

AppLocalizations _testL10n() => lookupAppLocalizations(const Locale('en'));

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<void> init() async {}
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);
}

class _FakeTracker extends StudyProgressTracker {
  _FakeTracker() : super(attemptRepo: _FakeAttemptRepo(), l10n: lookupAppLocalizations(const Locale('en')));

  @override
  Future<String> exportProgressCSV(String studentId) async => 'progress,csv,data';
  @override
  Future<String> exportSessionHistoryCSV(String studentId) async => 'session,history,csv';
}

class _FakeInstrumentation extends InstrumentationService {
  _FakeInstrumentation() : super(repository: null);

  @override
  Future<Result<Map<String, dynamic>>> getInstrumentationDashboard(String studentId) async {
    return Result.success({
      'generatedAt': DateTime.now().toIso8601String(),
      'planAdherence': {},
      'masteryImprovement': {},
    });
  }
}

Widget _buildTestApp(Widget child, {InstrumentationService? instrumentation}) {
  return ProviderScope(
    overrides: [
      dashboardStudyProgressTrackerProvider.overrideWithValue(_FakeTracker()),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        instrumentation ?? _FakeInstrumentation(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('ExportSection', () {
    testWidgets('renders three export buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsNWidgets(5));
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('renders Export CSV button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('renders Session History button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session History'), findsOneWidget);
    });

    testWidgets('renders Instrumentation button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Instrumentation'), findsOneWidget);
    });
  });

  group('formatInstrumentation', () {
    test('formats instrumentation with complete data', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
        'planAdherence': {'overall': '85%', 'weekly': '72%'},
        'masteryImprovement': {'algebra': '+15%', 'geometry': '+8%'},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationGenerated('2024-06-15T10:00:00.000')));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains('overall: 85%'));
      expect(result, contains('weekly: 72%'));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
      expect(result, contains('algebra: +15%'));
      expect(result, contains('geometry: +8%'));
    });

    test('formats instrumentation with empty data', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationGenerated('2024-06-15T10:00:00.000')));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });

    test('formats instrumentation with null sections', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
        'planAdherence': null,
        'masteryImprovement': null,
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });

    test('formats instrumentation with empty map sections', () {
      final l10n = _testL10n();
      final data = {
        'generatedAt': '2024-06-15T10:00:00.000',
        'planAdherence': <String, dynamic>{},
        'masteryImprovement': <String, dynamic>{},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });

    test('formats instrumentation with generatedAt as empty string', () {
      final l10n = _testL10n();
      final Map<String, dynamic> data = {
        'generatedAt': '',
        'planAdherence': <String, dynamic>{'metric': 'value'},
        'masteryImprovement': <String, dynamic>{'topic': 'improvement'},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationGenerated('')));
    });

    test('formats instrumentation with missing generatedAt', () {
      final l10n = _testL10n();
      final Map<String, dynamic> data = {
        'planAdherence': <String, dynamic>{'overall': '80%'},
        'masteryImprovement': <String, dynamic>{},
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
    });

    test('formats instrumentation with generatedAt as null', () {
      final l10n = _testL10n();
      final Map<String, dynamic> data = {
        'generatedAt': null,
        'planAdherence': null,
        'masteryImprovement': null,
      };

      final result = ExportSection(studentId: 'test').formatInstrumentation(data, l10n);

      expect(result, contains(l10n.instrumentationDashboard));
      expect(result, contains(l10n.instrumentationPlanAdherence));
      expect(result, contains(l10n.instrumentationMasteryImprovement));
    });
  });
}
