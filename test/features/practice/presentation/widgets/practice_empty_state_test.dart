import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_empty_state.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeEmptyState', () {
    testWidgets('renders empty state icon and text', (tester) async {
      await tester.pumpWidget(_buildTestApp(const PracticeEmptyState()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.book_online_outlined), findsOneWidget);
    });

    testWidgets('renders add subject button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const PracticeEmptyState()));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('calls onAddSubject when provided', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(PracticeEmptyState(onAddSubject: () => called = true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Subject'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('renders descriptive text', (tester) async {
      await tester.pumpWidget(_buildTestApp(const PracticeEmptyState()));
      await tester.pumpAndSettle();

      expect(find.text('No Practice Sessions Yet'), findsOneWidget);
      expect(find.text('Add subjects and questions to start practicing'), findsOneWidget);
    });
  });
}
