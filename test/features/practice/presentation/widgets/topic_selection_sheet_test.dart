import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/topic_selection_sheet.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('TopicSelectionSheet', () {
    testWidgets('renders topic list', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicSelectionSheet(
          topics: ['Algebra', 'Geometry'],
          onTopicSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
    });

    testWidgets('calls onTopicSelected when topic tapped', (tester) async {
      String? selected;
      await tester.pumpWidget(_buildTestApp(
        TopicSelectionSheet(
          topics: ['Algebra'],
          onTopicSelected: (t) => selected = t,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();

      expect(selected, 'Algebra');
    });

    testWidgets('shows topic icon for each item', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicSelectionSheet(
          topics: ['Algebra', 'Geometry'],
          onTopicSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.topic), findsNWidgets(2));
    });
  });
}
