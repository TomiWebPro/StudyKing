import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_edit_dialog.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

Topic _topic(String id, String title, {
  String description = '',
  String syllabusText = '',
  String? parentId,
  int sortOrder = 0,
  String subjectId = 'subj1',
}) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: title,
    description: description,
    parentId: parentId,
    sortOrder: sortOrder,
    syllabusText: syllabusText,
  );
}

// ignore: unused_element
TopicDependency _dep(String topicId, {List<String> prerequisites = const []}) {
  return TopicDependency(topicId: topicId, prerequisites: prerequisites);
}

void main() {
  group('TopicEditDialog', () {
    final rootTopic1 = _topic('r1', 'Root Topic 1', parentId: null);
    final rootTopic2 = _topic('r2', 'Root Topic 2', parentId: null);
    final childTopic = _topic('c1', 'Child Topic', parentId: 'r1');
    final existingTopics = [rootTopic1, rootTopic2, childTopic];

    testWidgets('renders dialog title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'Edit Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Topic'), findsOneWidget);
    });

    testWidgets('renders text fields for title, description, syllabus', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('shows hint texts for all text fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('e.g. Atomic Structure'), findsOneWidget);
      expect(find.text('Describe the topic scope'), findsOneWidget);
      expect(find.text('Syllabus points covered'), findsOneWidget);
    });

    testWidgets('shows label texts for all text fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Topic Title'), findsOneWidget);
      expect(find.text('Topic Description'), findsOneWidget);
      expect(find.text('Syllabus Text'), findsOneWidget);
    });

    testWidgets('shows parent topic dropdown when there are other root topics', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Parent Topic'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('hides parent topic dropdown when no other root topics exist', (tester) async {
      final onlyChildTopics = [
        _topic('c1', 'Child 1', parentId: 'r1'),
        _topic('c2', 'Child 2', parentId: 'r1'),
      ];
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: onlyChildTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Parent Topic'), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('selecting a parent topic from dropdown updates saved parentId', (tester) async {
      Topic? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Topic>(
                  context: context,
                  builder: (_) => TopicEditDialog(
                    title: 'New Topic',
                    existingTopics: existingTopics,
                    existingDependencies: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).at(0), 'New Topic');
      await tester.pump();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Root Topic 2').last);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.parentId, 'r2');
    });

    testWidgets('parent dropdown still shows when editing a root topic with other roots', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'Edit Topic',
          topic: rootTopic1,
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Parent Topic'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows sort order when editing an existing topic', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'Edit Topic',
          topic: rootTopic1,
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sort Order:'), findsOneWidget);
    });

    testWidgets('hides sort order when creating a new topic', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sort Order:'), findsNothing);
    });

    testWidgets('pre-populates fields when editing an existing topic', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'Edit Topic',
          topic: rootTopic1,
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      final titleField = tester.widget<TextField>(find.byType(TextField).at(0));
      final descField = tester.widget<TextField>(find.byType(TextField).at(1));

      expect(titleField.controller!.text, 'Root Topic 1');
      expect(descField.controller!.text, '');
    });

    testWidgets('accepts input in title field', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Quantum Physics');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        'Quantum Physics',
      );
    });

    testWidgets('accepts input in description field', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'Advanced quantum concepts');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        'Advanced quantum concepts',
      );
    });

    testWidgets('accepts input in syllabus field', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), 'Wave-particle duality');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
        'Wave-particle duality',
      );
    });

    testWidgets('shows Cancel and Save buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Cancel pops null', (tester) async {
      Topic? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Topic>(
                  context: context,
                  builder: (_) => TopicEditDialog(
                    title: 'New Topic',
                    existingTopics: existingTopics,
                    existingDependencies: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNull);
    });

    testWidgets('Save with empty title does not pop', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final r = await showDialog<Topic>(
                  context: context,
                  builder: (_) => TopicEditDialog(
                    title: 'New Topic',
                    existingTopics: existingTopics,
                    existingDependencies: [],
                  ),
                );
                // ignore: unused_local_variable
                final _ = r;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Save with title pops a Topic with correct values', (tester) async {
      Topic? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Topic>(
                  context: context,
                  builder: (_) => TopicEditDialog(
                    title: 'New Topic',
                    existingTopics: existingTopics,
                    existingDependencies: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).at(0), 'Quantum Physics');
      await tester.enterText(find.byType(TextField).at(1), 'Quantum concepts');
      await tester.enterText(find.byType(TextField).at(2), 'Wave-particle duality');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.title, 'Quantum Physics');
      expect(result!.description, 'Quantum concepts');
      expect(result!.syllabusText, 'Wave-particle duality');
      expect(result!.parentId, isNull);
    });

    testWidgets('Save when editing returns Topic with same id', (tester) async {
      Topic? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Topic>(
                  context: context,
                  builder: (_) => TopicEditDialog(
                    title: 'Edit Topic',
                    topic: rootTopic1,
                    existingTopics: existingTopics,
                    existingDependencies: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).at(0), 'Updated Title');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.id, rootTopic1.id);
      expect(result!.subjectId, rootTopic1.subjectId);
      expect(result!.title, 'Updated Title');
    });

    testWidgets('description and syllabus fields have correct maxLines', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      final descField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(descField.maxLines, 2);

      final syllabusField = tester.widget<TextField>(find.byType(TextField).at(2));
      expect(syllabusField.maxLines, 3);
    });

    testWidgets('parentId is set to empty string when creating and no parent selected', (tester) async {
      Topic? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Topic>(
                  context: context,
                  builder: (_) => TopicEditDialog(
                    title: 'New Topic',
                    topic: null,
                    existingTopics: existingTopics,
                    existingDependencies: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).at(0), 'New Topic');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.parentId, isNull);
    });

    testWidgets('title field uses TextCapitalization.sentences', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      final titleField = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(titleField.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('title field autofocus is enabled', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicEditDialog(
          title: 'New Topic',
          existingTopics: existingTopics,
          existingDependencies: [],
        ),
      ));
      await tester.pumpAndSettle();

      final titleField = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(titleField.autofocus, isTrue);
    });
  });
}
