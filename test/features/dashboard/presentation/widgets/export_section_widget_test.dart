import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/dashboard/presentation/widgets/export_section.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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

class _FakeProgressTracker {
  void updateLocalization(AppLocalizations l10n) {}
  Future<Result<String>> exportProgressCSV(String studentId) async =>
      Result.success('progress,csv,data');
  Future<Result<String>> exportSessionHistoryCSV(String studentId) async =>
      Result.success('session,history,csv');
}

class _FakeExportService {
  Future<String> exportComprehensiveCSV(String studentId, AppLocalizations l10n) async =>
      'csv,data';
  Future<List<int>> exportComprehensivePDF(
          String studentId, AppLocalizations l10n) async =>
      [1, 2, 3];
  Future<String> exportComprehensiveJSON(String studentId, AppLocalizations l10n) async =>
      '{}';
}

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    overrides: [
      dashboardStudyProgressTrackerProvider.overrideWithValue(
        _FakeProgressTracker() as dynamic,
      ),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        _FakeInstrumentation(),
      ),
      dashboardExportServiceProvider.overrideWithValue(
        _FakeExportService() as dynamic,
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

      expect(find.text('Comprehensive Report'), findsOneWidget);
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

      expect(find.text('Instrumentation'), findsOneWidget);
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
