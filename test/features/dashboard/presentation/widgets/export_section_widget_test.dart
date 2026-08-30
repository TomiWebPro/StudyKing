import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/dashboard/presentation/widgets/export_section.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async =>
      Result.success([]);
}

class _FakeMasteryGraphService extends MasteryGraphService {
  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async =>
      Result.success([]);
}

class _FakeInstrumentation extends InstrumentationService {
  _FakeInstrumentation() : super(repository: null);

  @override
  Future<Result<Map<String, dynamic>>> getInstrumentationDashboard(
          String studentId) async =>
      Result.success({
        'generatedAt': DateTime.now().toIso8601String(),
        'planAdherence': {},
        'masteryImprovement': {},
      });
}

class _FakeProgressTracker extends StudyProgressTracker {
  _FakeProgressTracker()
      : super(
          attemptRepo: _FakeAttemptRepo(),
          masteryService: _FakeMasteryGraphService(),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

  @override
  Future<Result<String>> exportProgressCSV(String studentId) async =>
      Result.success('progress,csv,data');

  @override
  Future<Result<String>> exportSessionHistoryCSV(String studentId) async =>
      Result.success('session,history,csv');
}

class _FakeExportService extends ProgressExportService {
  _FakeExportService()
      : super(
          tracker: _FakeProgressTracker(),
          masteryService: _FakeMasteryGraphService(),
          attemptRepo: _FakeAttemptRepo(),
        );

  @override
  Future<Result<String>> exportComprehensiveCSV(String studentId,
          {AppLocalizations? l10n}) async =>
      Result.success('csv,data');

  @override
  Future<Result<List<int>>> exportComprehensivePDF(
          String studentId, AppLocalizations l10n) async =>
      Result.success([1, 2, 3]);

  @override
  Future<Result<String>> exportComprehensiveJSON(
          String studentId, AppLocalizations l10n) async =>
      Result.success('{}');
}

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    overrides: [
      dashboardStudyProgressTrackerProvider.overrideWithValue(
        _FakeProgressTracker(),
      ),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        _FakeInstrumentation(),
      ),
      dashboardExportServiceProvider.overrideWithValue(
        _FakeExportService(),
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
    testWidgets('renders Comprehensive Report title', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Export Full Progress Report'), findsWidgets);
    });

    testWidgets('renders Export CSV button', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('renders Session History button', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session History'), findsOneWidget);
    });

    testWidgets('renders Instrumentation button', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Progress Analytics'), findsOneWidget);
    });

    testWidgets('renders backup export button', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        const ExportSection(studentId: 'test-student'),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.backup), findsOneWidget);
    });
  });
}
