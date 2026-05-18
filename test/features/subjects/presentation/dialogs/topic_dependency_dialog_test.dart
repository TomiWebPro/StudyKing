import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_dependency_dialog.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

/// Helper to pump a dialog via [showDialog] so [Navigator.pop] works.
Future<void> pumpDialog(WidgetTester tester, Widget dialog) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () => showDialog<TopicDependency>(
            context: context,
            builder: (_) => dialog,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Topic _topic(String id, String title, {String description = '', String? parentId, int sortOrder = 0}) {
  return Topic(
    id: id,
    subjectId: 'subj1',
    title: title,
    description: description,
    parentId: parentId,
    sortOrder: sortOrder,
    syllabusText: '',
  );
}

void main() {
  group('TopicDependencyDialog', () {
    final topic1 = _topic('t1', 'Topic 1', description: 'First topic');
    final topic2 = _topic('t2', 'Topic 2', description: 'Second topic');
    final topic3 = _topic('t3', 'Topic 3');
    final allTopics = [topic1, topic2, topic3];

    testWidgets('renders title with topic name and Dependencies', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Topic 1 — Dependencies'), findsOneWidget);
    });

    testWidgets('shows Prerequisites label', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Prerequisites'), findsOneWidget);
    });

    testWidgets('lists available topics as checkboxes excluding self', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Topic 2'), findsOneWidget);
      expect(find.text('Topic 3'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('shows description subtitle for prerequisite topics', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Second topic'), findsOneWidget);
    });

    testWidgets('shows No description when topic description is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No description'), findsOneWidget);
    });

    testWidgets('toggling a prerequisite checkbox adds/removes selection', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      final tile2 = find.ancestor(
        of: find.text('Topic 2'),
        matching: find.byType(CheckboxListTile),
      );
      expect(
        tester.widget<CheckboxListTile>(tile2).value,
        isFalse,
      );

      await tester.tap(find.text('Topic 2'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(tile2).value,
        isTrue,
      );

      await tester.tap(find.text('Topic 2'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(tile2).value,
        isFalse,
      );
    });

    testWidgets('shows No other topics available when only one topic exists', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: [topic1]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No other topics available for prerequisites.'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('shows mastery threshold label with initial value', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mastery Threshold: 80%'), findsOneWidget);
    });

    testWidgets('mastery threshold slider has correct configuration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider).first);
      expect(slider.min, 0.0);
      expect(slider.max, 1.0);
      expect(slider.divisions, 20);
      expect(slider.value, 0.8);
    });

    testWidgets('dragging mastery threshold slider changes saved value', (tester) async {
      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<TopicDependency>(
                  context: context,
                  builder: (_) => TopicDependencyDialog(topic: topic1, allTopics: allTopics),
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

      final slider = find.byType(Slider).first;
      final rect = tester.getRect(slider);
      await tester.drag(slider, Offset(-rect.width * 0.5, 0));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.masteryThreshold, lessThan(0.8));
    });

    testWidgets('required toggle shows correct subtitle based on state', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Student must master this topic'), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.text('Optional topic — can be skipped'), findsOneWidget);
    });

    testWidgets('syllabus weight slider has correct configuration', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2));

      final weightSlider = tester.widget<Slider>(sliders.at(1));
      expect(weightSlider.min, 0.1);
      expect(weightSlider.max, 3.0);
      expect(weightSlider.divisions, 29);
      expect(weightSlider.value, 1.0);
    });

    testWidgets('dragging syllabus weight slider changes saved value', (tester) async {
      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<TopicDependency>(
                  context: context,
                  builder: (_) => TopicDependencyDialog(topic: topic1, allTopics: allTopics),
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

      final sliders = find.byType(Slider);
      final weightSlider = sliders.at(1);
      final rect = tester.getRect(weightSlider);
      await tester.drag(weightSlider, Offset(rect.width * 0.3, 0));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.syllabusWeight, greaterThan(1.0));
    });

    testWidgets('shows syllabus weight label', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Syllabus Weight: 1.0'), findsOneWidget);
    });

    testWidgets('shows Cancel and Save buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Cancel pops null', (tester) async {
      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<TopicDependency>(
                  context: context,
                  builder: (_) => TopicDependencyDialog(topic: topic1, allTopics: allTopics),
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

    testWidgets('Save pops TopicDependency with default values', (tester) async {
      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<TopicDependency>(
                  context: context,
                  builder: (_) => TopicDependencyDialog(topic: topic1, allTopics: allTopics),
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

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.topicId, 't1');
      expect(result!.prerequisites, isEmpty);
      expect(result!.masteryThreshold, 0.8);
      expect(result!.isRequired, isTrue);
      expect(result!.syllabusWeight, 1.0);
      expect(result!.sortOrder, 0);
      expect(result!.parentTopicId, isNull);
    });

    testWidgets('pre-populates fields from existing dependency', (tester) async {
      final dep = TopicDependency(
        topicId: 't1',
        prerequisites: ['t2'],
        masteryThreshold: 0.9,
        isRequired: false,
        syllabusWeight: 2.0,
        sortOrder: 1,
      );

      await tester.pumpWidget(_buildTestApp(
        TopicDependencyDialog(topic: topic1, allTopics: allTopics, dependency: dep),
      ));
      await tester.pumpAndSettle();

      final tile2 = find.ancestor(
        of: find.text('Topic 2'),
        matching: find.byType(CheckboxListTile),
      );
      expect(tester.widget<CheckboxListTile>(tile2).value, isTrue);

      expect(find.text('Mastery Threshold: 90%'), findsOneWidget);
      expect(find.text('Optional topic — can be skipped'), findsOneWidget);
      expect(find.text('Syllabus Weight: 2.0'), findsOneWidget);
    });

    testWidgets('Save with selected prerequisites and toggled state returns correct data', (tester) async {
      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<TopicDependency>(
                  context: context,
                  builder: (_) => TopicDependencyDialog(topic: topic1, allTopics: allTopics),
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

      await tester.tap(find.text('Topic 2'));
      await tester.pump();
      await tester.tap(find.text('Topic 3'));
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.topicId, 't1');
      expect(result!.prerequisites, containsAll(['t2', 't3']));
      expect(result!.isRequired, isFalse);
    });

    testWidgets('preserves downstreamTopics and sortOrder from existing dependency on Save', (tester) async {
      final dep = TopicDependency(
        topicId: 't1',
        prerequisites: [],
        downstreamTopics: ['t2'],
        sortOrder: 5,
        parentTopicId: 'parent1',
      );

      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<TopicDependency>(
                  context: context,
                  builder: (_) => TopicDependencyDialog(
                    topic: topic1,
                    allTopics: allTopics,
                    dependency: dep,
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

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.downstreamTopics, ['t2']);
      expect(result!.sortOrder, 5);
      expect(result!.parentTopicId, topic1.parentId);
    });

    testWidgets('dependency uses topic sortOrder when no existing dependency sortOrder', (tester) async {
      final topicWithSort = _topic('t4', 'Topic 4', sortOrder: 7);

      TopicDependency? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<TopicDependency>(
                  context: context,
                  builder: (_) => TopicDependencyDialog(topic: topicWithSort, allTopics: [topicWithSort]),
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

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.sortOrder, 7);
    });
  });
}
