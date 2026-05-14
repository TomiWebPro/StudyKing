import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
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

      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
    });

    testWidgets('renders exercise block type', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.exercise)),
      ));

      expect(find.byIcon(Icons.note_add), findsOneWidget);
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

      expect(find.byIcon(Icons.question_answer), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
    });

    testWidgets('renders summary block type', (tester) async {
      await tester.pumpWidget(buildApp(
        LessonBlockCard(block: block(type: LessonBlockType.summary)),
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
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
}
