import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/presentation/widgets/lesson_block_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  Widget buildApp(Widget widget) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
    );
  }

  LessonBlock block({
    LessonBlockType type = LessonBlockType.text,
    String content = 'Sample lesson content',
  }) {
    return LessonBlock(
      id: 'block-1',
      subjectId: 'subj-1',
      lessonId: 'lesson-1',
      type: type,
      content: content,
    );
  }

  group('LessonBlockCard', () {
    testWidgets('renders text block type with content', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.text)),
      ));

      expect(find.text('Sample lesson content'), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.text('Explanation'), findsOneWidget);
    });

    testWidgets('renders example block type', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.example)),
      ));

      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
    });

    testWidgets('renders exercise block type', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.exercise)),
      ));

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
    });

    testWidgets('renders slide block type', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.slide)),
      ));

      expect(find.byIcon(Icons.slideshow), findsOneWidget);
      expect(find.text('Slide'), findsOneWidget);
    });

    testWidgets('renders quiz block type', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.quiz)),
      ));

      expect(find.byIcon(Icons.quiz), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
    });

    testWidgets('renders summary block type', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.summary)),
      ));

      expect(find.byIcon(Icons.checklist), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
    });

    testWidgets('displays long content text', (tester) async {
      final longContent = 'A' * 500;
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(content: longContent)),
      ));

      expect(find.text(longContent), findsOneWidget);
    });
  });

  group('LessonBlockCard - Quiz', () {
    testWidgets('submit button is disabled when answer is empty', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.quiz, content: 'What is 2+2?')),
      ));

      final submitBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit Answer'),
      );
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('scores correct answer with answerKey (short answer)', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(
          block: LessonBlock(
            id: 'q1', subjectId: 's1', lessonId: 'l1',
            type: LessonBlockType.quiz,
            content: 'What is 2+2?',
            answerKey: '4||four',
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Correct'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('scores incorrect answer with answerKey', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(
          block: LessonBlock(
            id: 'q2', subjectId: 's1', lessonId: 'l1',
            type: LessonBlockType.quiz,
            content: 'What is 2+2?',
            answerKey: '4||four',
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'five');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect answer'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('scores correct answer using fallback content parsing', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(
          type: LessonBlockType.quiz,
          content: 'What is the capital of France?\nanswer: Paris',
        )),
      ));

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('scores incorrect answer using fallback content parsing', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(
          type: LessonBlockType.quiz,
          content: 'What is the capital of France?\nanswer: Paris',
        )),
      ));

      await tester.enterText(find.byType(TextField), 'London');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect answer'), findsOneWidget);
    });

    testWidgets('shows AI tutor button when onStartTutor provided after correct answer', (tester) async {
      bool tutorTapped = false;
      await tester.pumpWidget(buildApp(
        LessonBlockCard(
          block: LessonBlock(
            id: 'q3', subjectId: 's1', lessonId: 'l1',
            type: LessonBlockType.quiz,
            content: 'What is 2+2?',
            answerKey: '4',
          ),
          onStartTutor: () => tutorTapped = true,
        ),
      ));

      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);

      await tester.tap(find.text('AI Tutor'));
      expect(tutorTapped, isTrue);
    });
  });

  group('LessonBlockCard - Exercise', () {
    testWidgets('submit button is disabled when answer is empty', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.exercise)),
      ));

      final submitBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit Answer'),
      );
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('typing answer and submitting shows submitted state', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.exercise)),
      ));

      await tester.enterText(find.byType(TextField), 'My answer here');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('My answer here'), findsOneWidget);
      expect(find.text('Your Answer'), findsOneWidget);
    });

    testWidgets('shows AI tutor button with onStartTutor', (tester) async {
      bool tutorTapped = false;
      await tester.pumpWidget(buildApp(
        LessonBlockCard(
          block: block(type: LessonBlockType.exercise),
          onStartTutor: () => tutorTapped = true,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'My answer');
      await tester.pump();
      await tester.tap(find.text('AI Tutor'));
      expect(tutorTapped, isTrue);
    });
  });

  group('LessonBlockCard - Slide', () {
    testWidgets('tapping slide opens full screen dialog with content', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.slide)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('Sample lesson content'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('full screen dialog shows page indicator for single slide', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.slide)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('1 / 1'), findsWidgets);
    });

    testWidgets('single slide does not show navigation buttons', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.slide)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('multi-slide mode shows page indicator and navigation', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(
          block: block(type: LessonBlockType.slide, content: 'First slide'),
          allBlocks: [
            LessonBlock(id: 's1', subjectId: 's1', lessonId: 'l1',
                type: LessonBlockType.slide, content: 'First slide', order: 0),
            LessonBlock(id: 's2', subjectId: 's1', lessonId: 'l1',
                type: LessonBlockType.slide, content: 'Second slide', order: 1),
          ],
          blockIndex: 0,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('First slide'), findsAtLeastNWidgets(1));
      expect(find.text('1 / 2'), findsWidgets);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('navigating to next slide shows second slide content', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(
          block: block(type: LessonBlockType.slide, content: 'First slide'),
          allBlocks: [
            LessonBlock(id: 's1', subjectId: 's1', lessonId: 'l1',
                type: LessonBlockType.slide, content: 'First slide', order: 0),
            LessonBlock(id: 's2', subjectId: 's1', lessonId: 'l1',
                type: LessonBlockType.slide, content: 'Second slide', order: 1),
          ],
          blockIndex: 0,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsWidgets);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Second slide'), findsAtLeastNWidgets(1));
    });

    testWidgets('close button exits the full screen dialog', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.slide)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
