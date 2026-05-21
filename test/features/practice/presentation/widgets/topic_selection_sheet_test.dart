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
          topics: {'topic-algebra': 'Algebra', 'topic-geometry': 'Geometry'},
          onTopicSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
    });

    testWidgets('calls onTopicSelected with topic id when topic tapped', (tester) async {
      String? selected;
      await tester.pumpWidget(_buildTestApp(
        TopicSelectionSheet(
          topics: {'topic-algebra': 'Algebra'},
          onTopicSelected: (t) => selected = t,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();

      expect(selected, 'topic-algebra');
    });

    testWidgets('shows topic icon for each item', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicSelectionSheet(
          topics: {'topic-algebra': 'Algebra', 'topic-geometry': 'Geometry'},
          onTopicSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.topic), findsNWidgets(2));
    });

    testWidgets('renders select topic title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicSelectionSheet(
          topics: {'topic-algebra': 'Algebra'},
          onTopicSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Topic'), findsOneWidget);
    });

    testWidgets('renders empty topics list gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicSelectionSheet(
          topics: <String, String>{},
          onTopicSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Topic'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('static show displays bottom sheet', (tester) async {
      String? selected;
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              TopicSelectionSheet.show(
                context,
                topics: {'topic-algebra': 'Algebra', 'topic-geometry': 'Geometry'},
                onTopicSelected: (t) => selected = t,
              );
            },
            child: const Text('Show Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Select Topic'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);

      await tester.tap(find.text('Geometry'));
      await tester.pumpAndSettle();

      expect(selected, 'topic-geometry');
    });
  });
}
