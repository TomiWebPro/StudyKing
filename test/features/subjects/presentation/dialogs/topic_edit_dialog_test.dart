import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_edit_dialog.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  group('TopicEditDialog', () {
    final existingTopics = [
      Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Algebra',
        description: 'Algebra basics',
        syllabusText: 'Algebra syllabus',
      ),
      Topic(
        id: 't-2',
        subjectId: 'sub-1',
        title: 'Geometry',
        description: 'Shapes',
        syllabusText: 'Geometry syllabus',
      ),
    ];

    Widget buildTestApp(Widget dialog) {
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

    testWidgets('displays title field', (tester) async {
      await tester.pumpWidget(buildTestApp(
        TopicEditDialog(
          title: 'Add Topic',
          existingTopics: existingTopics,
          existingDependencies: const [],
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add Topic'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(3));
    });

    testWidgets('title, description and syllabus text fields accept input',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        TopicEditDialog(
          title: 'Add Topic',
          existingTopics: existingTopics,
          existingDependencies: const [],
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'New Topic Title');
      await tester.enterText(textFields.at(1), 'New Description');
      await tester.enterText(textFields.at(2), 'New Syllabus');
      await tester.pumpAndSettle();

      expect(find.text('New Topic Title'), findsOneWidget);
      expect(find.text('New Description'), findsOneWidget);
      expect(find.text('New Syllabus'), findsOneWidget);
    });

    testWidgets('save button is disabled when title is empty', (tester) async {
      await tester.pumpWidget(buildTestApp(
        TopicEditDialog(
          title: 'Add Topic',
          existingTopics: existingTopics,
          existingDependencies: const [],
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(TopicEditDialog), findsOneWidget);
    });

    testWidgets('save returns Topic via Navigator.pop', (tester) async {
      Topic? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await showDialog<Topic>(
                context: context,
                builder: (_) => TopicEditDialog(
                  title: 'Add Topic',
                  existingTopics: existingTopics,
                  existingDependencies: const [],
                ),
              );
            },
            child: const Text('Open'),
          );
        }),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'New Topic');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'New Topic');
    });

    testWidgets('cancel pops without result', (tester) async {
      Topic? result = Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Placeholder',
        description: '',
        syllabusText: '',
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await showDialog<Topic>(
                context: context,
                builder: (_) => TopicEditDialog(
                  title: 'Add Topic',
                  existingTopics: existingTopics,
                  existingDependencies: const [],
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

    testWidgets('edit mode pre-fills existing topic data', (tester) async {
      final existingTopic = Topic(
        id: 't-3',
        subjectId: 'sub-1',
        title: 'Trigonometry',
        description: 'Angles and functions',
        syllabusText: 'Trig syllabus',
      );

      await tester.pumpWidget(buildTestApp(
        TopicEditDialog(
          title: 'Edit Topic',
          topic: existingTopic,
          existingTopics: existingTopics,
          existingDependencies: const [],
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Topic'), findsOneWidget);
      expect(find.text('Trigonometry'), findsOneWidget);
      expect(find.text('Angles and functions'), findsOneWidget);
      expect(find.text('Trig syllabus'), findsOneWidget);
    });

    testWidgets('parent topic dropdown is shown when other topics exist',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        TopicEditDialog(
          title: 'Add Topic',
          existingTopics: existingTopics,
          existingDependencies: const [],
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Parent Topic'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('None (Root Topic)'), findsOneWidget);
    });

    testWidgets('parent topic dropdown filters correctly', (tester) async {
      await tester.pumpWidget(buildTestApp(
        TopicEditDialog(
          title: 'Add Topic',
          existingTopics: existingTopics,
          existingDependencies: const [],
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
    });
  });
}
