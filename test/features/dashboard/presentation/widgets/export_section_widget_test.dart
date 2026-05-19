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

      expect(find.byType(TextButton), findsNWidgets(7));
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
}
