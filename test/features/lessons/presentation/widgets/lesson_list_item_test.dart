import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/presentation/widgets/lesson_list_item.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  Lesson createLesson({String id = 'lesson-1', int blockCount = 3}) {
    return Lesson(
      id: id,
      subjectId: 'subj-1',
      title: 'Algebra Basics',
      topicId: 'topic-1',
      blocks: List.generate(
        blockCount,
        (i) => LessonBlock(
          id: 'block-$i',
          subjectId: 'subj-1',
          lessonId: id,
          type: LessonBlockType.text,
          content: 'Content $i',
        ),
      ),
      createdAt: DateTime.now(),
    );
  }

  Widget buildApp(Widget widget) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
    );
  }

  group('LessonListItem', () {
    testWidgets('renders lesson title and block count', (tester) async {
      final lesson = createLesson(blockCount: 5);
      await tester.pumpWidget(buildApp(
        LessonListItem(lesson: lesson, topicTitle: 'Topic 1'),
      ));

      expect(find.text('Algebra Basics'), findsOneWidget);
      expect(find.text('5 blocks'), findsOneWidget);
    });

    testWidgets('shows play arrow icon', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonListItem(lesson: createLesson(), topicTitle: 'Topic 1'),
      ));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildApp(
        LessonListItem(
          lesson: createLesson(),
          topicTitle: 'Topic 1',
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows completed status icon and chip', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonListItem(
          lesson: createLesson(),
          topicTitle: 'Topic 1',
          status: LessonStatusDisplay.completed,
        ),
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows inProgress status icon and chip', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonListItem(
          lesson: createLesson(),
          topicTitle: 'Topic 1',
          status: LessonStatusDisplay.inProgress,
        ),
      ));

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('shows notStarted status icon', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonListItem(
          lesson: createLesson(),
          topicTitle: 'Topic 1',
          status: LessonStatusDisplay.notStarted,
        ),
      ));

      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.text('Not Started'), findsOneWidget);
    });

    testWidgets('defaults to book icon when status is null', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonListItem(lesson: createLesson(), topicTitle: 'Topic 1'),
      ));

      expect(find.byIcon(Icons.book), findsOneWidget);
    });
  });
}
