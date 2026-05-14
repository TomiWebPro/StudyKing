import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  Widget buildApp(Widget widget) {
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsController(SettingsRepository()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: SingleChildScrollView(child: widget)),
      ),
    );
  }

  Question question({
    String id = 'q1',
    String text = 'What is 2+2?',
    QuestionType type = QuestionType.singleChoice,
    String correctAnswer = '4',
    List<String> options = const ['3', '4', '5', '6'],
  }) {
    return Question(
      id: id,
      text: text,
      type: type,
      subjectId: 'subj-1',
      topicId: 'topic-1',
      markscheme: Markscheme(questionId: id, correctAnswer: correctAnswer),
      options: options,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('PracticeSessionQuestionCard', () {
    testWidgets('renders question text and type badge', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));

      expect(find.text('What is 2+2?'), findsOneWidget);
      expect(find.text('Multiple Choice'), findsOneWidget);
    });

    testWidgets('renders multi choice options', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.multiChoice),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));

      expect(find.text('Multiple Select'), findsOneWidget);
    });

    testWidgets('renders typed answer input', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.typedAnswer),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders essay input with character count', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.essay),
          currentAnswer: 'Hello',
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders fallback for unsupported type', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.fileUpload),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));

      expect(find.textContaining('Unsupported question type'), findsOneWidget);
    });

    testWidgets('onAnswerSelected is called for typed answer', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.typedAnswer),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'my answer');
      expect(captured, 'my answer');
    });

    testWidgets('shows selected answer for single choice', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(),
          currentAnswer: '4',
          isSubmitted: true,
          isFeedbackVisible: true,
          onAnswerSelected: (_) {},
        ),
      ));
    });
  });
}
