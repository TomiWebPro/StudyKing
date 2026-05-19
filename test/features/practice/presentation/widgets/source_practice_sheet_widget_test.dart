import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  group('SourcePracticeSheet', () {
    final sources = [
      const SourceItemData(id: 's1', title: 'Textbook Ch.1', questionCount: 15),
      const SourceItemData(id: 's2', title: 'Past Paper 2024', questionCount: 30),
    ];

    testWidgets('shows empty state when no sources', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: [], onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.source), findsNothing);
    });

    testWidgets('shows source titles when sources are provided', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Textbook Ch.1'), findsOneWidget);
      expect(find.text('Past Paper 2024'), findsOneWidget);
    });

    testWidgets('shows question count for each source', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Questions: 15'), findsOneWidget);
      expect(find.text('Questions: 30'), findsOneWidget);
    });

    testWidgets('shows zero-question message for sources without questions', (tester) async {
      final zeroSources = [
        const SourceItemData(id: 's1', title: 'Textbook Ch.1', questionCount: 0),
      ];
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: zeroSources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.text('0 questions — generate questions from this source'), findsOneWidget);
    });

    testWidgets('shows source icon for each source item', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.source), findsWidgets);
    });

    testWidgets('shows chevron icon for each source item', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: sources, onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('calls onSourceSelected when source is tapped', (tester) async {
      String? selectedId;
      String? selectedTitle;
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(
          sources: sources,
          onSourceSelected: (id, title) {
            selectedId = id;
            selectedTitle = title;
          },
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Textbook Ch.1'));
      await tester.pumpAndSettle();
      expect(selectedId, equals('s1'));
      expect(selectedTitle, equals('Textbook Ch.1'));
    });

    testWidgets('renders empty state text when no sources', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SourcePracticeSheet(sources: [], onSourceSelected: (_, __) {}),
      ));
      await tester.pumpAndSettle();
      expect(find.text('No sources available'), findsOneWidget);
    });

    testWidgets('static show displays bottom sheet', (tester) async {
      String? capturedId;
      String? capturedTitle;
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              SourcePracticeSheet.show(
                context,
                sources: sources,
                onSourceSelected: (id, title) {
                  capturedId = id;
                  capturedTitle = title;
                },
              );
            },
            child: const Text('Show Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Textbook Ch.1'), findsOneWidget);
      expect(find.text('Questions: 15'), findsOneWidget);

      await tester.tap(find.text('Textbook Ch.1'));
      await tester.pumpAndSettle();

      expect(capturedId, equals('s1'));
      expect(capturedTitle, equals('Textbook Ch.1'));
    });
  });
}
