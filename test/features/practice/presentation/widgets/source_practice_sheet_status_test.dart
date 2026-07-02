import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/presentation/widgets/source_practice_sheet.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SourcePracticeSheet status labels', () {
    testWidgets('shows pending status label', (tester) async {
      final sources = [
        const SourceItemData(id: 's1', title: 'Source 1', questionCount: 0, status: ProcessingStatus.pending),
      ];
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows extracting status label', (tester) async {
      final sources = [
        const SourceItemData(id: 's1', title: 'Source 1', questionCount: 0, status: ProcessingStatus.extracting),
      ];
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Extracting'), findsOneWidget);
    });

    testWidgets('shows generating questions status label', (tester) async {
      final sources = [
        const SourceItemData(id: 's1', title: 'Source 1', questionCount: 0, status: ProcessingStatus.generatingQuestions),
      ];
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Generating Questions'), findsOneWidget);
    });

    testWidgets('shows summarizing status label', (tester) async {
      final sources = [
        const SourceItemData(id: 's1', title: 'Source 1', questionCount: 0, status: ProcessingStatus.summarizing),
      ];
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Summarizing'), findsOneWidget);
    });

    testWidgets('shows validating status label', (tester) async {
      final sources = [
        const SourceItemData(id: 's1', title: 'Source 1', questionCount: 0, status: ProcessingStatus.validating),
      ];
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Validating...'), findsOneWidget);
    });
  });
}
