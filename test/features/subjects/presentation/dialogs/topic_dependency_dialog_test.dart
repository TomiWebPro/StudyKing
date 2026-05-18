import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_dependency_dialog.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget dialog) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => dialog),
        child: const Text('Open'),
      );
    })),
  );
}

Topic _topic(String id, String title, {String description = ''}) {
  return Topic(
    id: id,
    subjectId: 'sub-1',
    title: title,
    description: description,
    syllabusText: 'Syllabus',
  );
}

void main() {
  group('TopicDependencyDialog', () {
    final topicA = _topic('t-a', 'Algebra');
    final topicB = _topic('t-b', 'Geometry');
    final topicC = _topic('t-c', 'Calculus');
    final allTopics = [topicA, topicB, topicC];

    testWidgets('displays prerequisites section', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: allTopics,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Algebra — Dependencies'), findsOneWidget);
      expect(find.text('Prerequisites'), findsOneWidget);
    });

    testWidgets('shows other topics as checkboxes for prerequisites',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: allTopics,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Calculus'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('prerequisite checkboxes toggle correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: allTopics,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final geometryCheckbox = find.ancestor(
        of: find.text('Geometry'),
        matching: find.byType(CheckboxListTile),
      );
      await tester.tap(geometryCheckbox);
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(geometryCheckbox);
      expect(checkbox.value, isTrue);
    });

    testWidgets('mastery threshold slider updates percentage display',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: allTopics,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mastery Threshold'), findsOneWidget);

      final slider = find.byType(Slider).first;

      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('required toggle switch works', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: allTopics,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsOneWidget);
      expect(find.text('Required Topic'), findsOneWidget);
    });

    testWidgets('toggling required switch changes subtitle', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: allTopics,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.textContaining('Optional topic'), findsOneWidget);
    });

    testWidgets('save button returns a TopicDependency via Navigator.pop',
        (tester) async {
      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await showDialog<TopicDependency>(
                context: context,
                builder: (_) => TopicDependencyDialog(
                  topic: topicA,
                  allTopics: allTopics,
                ),
              );
            },
            child: const Text('Open'),
          );
        }),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.topicId, 't-a');
      expect(result!.isRequired, isTrue);
    });

    testWidgets('cancel button pops without result', (tester) async {
      TopicDependency? result = TopicDependency(topicId: 'placeholder');
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await showDialog<TopicDependency>(
                context: context,
                builder: (_) => TopicDependencyDialog(
                  topic: topicA,
                  allTopics: allTopics,
                ),
              );
            },
            child: const Text('Open'),
          );
        }),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('shows syllabus weight slider', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: allTopics,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Syllabus Weight'), findsOneWidget);
    });

    testWidgets('shows no topics message when no other topics', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(
          topic: topicA,
          allTopics: [topicA],
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No other topics'), findsOneWidget);
    });
  });
}
