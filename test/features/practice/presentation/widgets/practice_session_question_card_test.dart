import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/service_providers.dart'
    show visionInterpretationServiceProvider;
import 'package:studyking/core/services/vision_interpretation_service.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/questions/presentation/widgets/canvas_drawing_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/graph_drawing_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/single_answer_widget.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Hand-written fake that parks [interpretImage] on a caller-controlled
/// future so widget tests can dispose the card mid-interpretation.
class FakeVisionInterpretationService extends VisionInterpretationService {
  FakeVisionInterpretationService(this._interpretation)
      : super(ocrExtractor: OcrExtractor(modelId: 'test-model', localeName: 'en'));

  final Future<Result<String>> _interpretation;

  @override
  Future<Result<String>> interpretImage(Uint8List image) => _interpretation;
}

void main() {
  Widget buildApp(Widget widget, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsController(SettingsRepository()),
        ),
        ...overrides,
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

    testWidgets('calls onAnswerSelected when multi choice option tapped', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(
            type: QuestionType.multiChoice,
            options: ['Option A', 'Option B', 'Option C'],
            correctAnswer: 'Option B',
          ),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option B'));
      expect(captured, 'Option B');
    });

    testWidgets('does not call onAnswerSelected when submitted for multi choice', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(
            type: QuestionType.multiChoice,
            options: ['Option A', 'Option B'],
            correctAnswer: 'Option A',
          ),
          currentAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option A'));
      expect(captured, isNull);
    });

    testWidgets('shows feedback when submitted and feedback is visible for multi choice', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(
            type: QuestionType.multiChoice,
            options: ['Option A', 'Option B'],
            correctAnswer: 'Option A',
          ),
          currentAnswer: 'Option A',
          isSubmitted: true,
          isFeedbackVisible: true,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
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

    testWidgets('renders file upload button for fileUpload type', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.fileUpload),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));

      expect(find.textContaining('Upload file'), findsOneWidget);
    });

    testWidgets('renders audio recording button for audioRecording type', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.audioRecording),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));

      expect(find.textContaining('Start recording'), findsOneWidget);
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

      expect(find.text('What is 2+2?'), findsOneWidget);
      expect(find.text('Multiple Choice'), findsOneWidget);
      expect(find.byType(SingleAnswerWidget), findsOneWidget);
    });

    testWidgets('renders math expression question type', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.mathExpression),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Math'), findsOneWidget);
      expect(find.text('What is 2+2?'), findsOneWidget);
    });

    testWidgets('shows no options available for single choice without options', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.singleChoice, options: []),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No options available'), findsOneWidget);
    });

    testWidgets('calls onAnswerSelected when single choice option tapped', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(
            type: QuestionType.singleChoice,
            options: ['3', '4', '5'],
            correctAnswer: '4',
          ),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4'));
      expect(captured, '4');
    });

    testWidgets('renders canvas drawing question type', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.canvas),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Diagram'), findsOneWidget);
      expect(find.text('What is 2+2?'), findsAtLeastNWidgets(1));
    });

    testWidgets('canvas onDrawingComplete calls onAnswerSelected with base64 encoded data', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.canvas),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      final canvas = tester.widget<CanvasDrawingWidget>(find.byType(CanvasDrawingWidget));
      canvas.onDrawingComplete(Uint8List(0));

      expect(captured, equals(''));
    });

    testWidgets('canvas onTextRecognized routes recognized handwriting to onAnswerSelected', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.canvas),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      final canvas = tester.widget<CanvasDrawingWidget>(find.byType(CanvasDrawingWidget));
      canvas.onTextRecognized?.call('3x + 2');

      expect(captured, equals('3x + 2'));
    });

    testWidgets('shows image vision upload affordance for canvas questions', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.canvas),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Upload a photo of your work'), findsOneWidget);
    });

    testWidgets('renders graph drawing question type', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.graphDrawing),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Graph'), findsOneWidget);
      expect(find.text('What is 2+2?'), findsAtLeastNWidgets(1));
      expect(find.byType(GraphDrawingWidget), findsOneWidget);
    });

    testWidgets('graph onDrawingComplete calls onAnswerSelected with base64 encoded data', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.graphDrawing),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      final graph = tester.widget<GraphDrawingWidget>(find.byType(GraphDrawingWidget));
      graph.onDrawingComplete(Uint8List(0));

      expect(captured, equals(''));
    });

    testWidgets('renders step by step input', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.stepByStep),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows no options for multi choice with empty options', (tester) async {
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(
            type: QuestionType.multiChoice,
            options: [],
            correctAnswer: '4',
          ),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No options available'), findsOneWidget);
    });

    testWidgets('handles multi choice deselecting an option', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(
            type: QuestionType.multiChoice,
            options: ['Option A', 'Option B'],
            correctAnswer: 'Option A',
          ),
          currentAnswer: 'Option A||Option B',
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option A'));
      expect(captured, 'Option B');
    });

    testWidgets('handles essay onChanged callback', (tester) async {
      String? captured;
      await tester.pumpWidget(buildApp(
        PracticeSessionQuestionCard(
          question: question(type: QuestionType.essay),
          currentAnswer: null,
          isSubmitted: false,
          isFeedbackVisible: false,
          onAnswerSelected: (v) => captured = v,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'my essay');
      expect(captured, 'my essay');
    });

    // The file_picker platform channel the canvas answer's image
    // upload goes through.
    const pickerChannel = MethodChannel('miguelruivo.flutter.plugins.filepicker');

    testWidgets(
      'does not setState after dispose when the file picker resolves after the card is disposed',
      (tester) async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };
        addTearDown(() {
          tester.binding.defaultBinaryMessenger
              .setMockMethodCallHandler(pickerChannel, null);
        });
        try {
          final pick = Completer<List<Map<Object?, Object?>?>?>();
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            pickerChannel,
            (call) => pick.future,
          );
          await tester.pumpWidget(buildApp(
            PracticeSessionQuestionCard(
              question: question(type: QuestionType.canvas),
              currentAnswer: null,
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Upload a photo of your work'));
          await tester.pump();

          // The user leaves the practice session while the native
          // picker is still in flight, then cancels it.
          await tester.pumpWidget(const SizedBox());
          logs.clear();
          pick.complete(null);
          await tester.pump();

          expect(
            logs.where((line) => line.contains('CanvasAnswerWithVision')),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        } finally {
          debugPrint = previousDebugPrint;
        }
      },
    );

    testWidgets(
      'does not setState after dispose when image interpretation completes after the card is disposed',
      (tester) async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };
        addTearDown(() {
          tester.binding.defaultBinaryMessenger
              .setMockMethodCallHandler(pickerChannel, null);
        });
        try {
          final interpretation = Completer<Result<String>>();
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            pickerChannel,
            (call) async => <Map<Object?, Object?>>[
              <Object?, Object?>{
                'name': 'work.png',
                'path': '/work.png',
                'bytes': Uint8List.fromList(<int>[1, 2, 3]),
                'size': 3,
              },
            ],
          );
          await tester.pumpWidget(buildApp(
            PracticeSessionQuestionCard(
              question: question(type: QuestionType.canvas),
              currentAnswer: null,
              isSubmitted: false,
              isFeedbackVisible: false,
              onAnswerSelected: (_) {},
            ),
            overrides: [
              visionInterpretationServiceProvider.overrideWithValue(
                FakeVisionInterpretationService(interpretation.future),
              ),
            ],
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Upload a photo of your work'));
          await tester.pump();

          // The OCR/LLM interpretation is still running when the card
          // is disposed (session exit), then it completes.
          await tester.pumpWidget(const SizedBox());
          logs.clear();
          interpretation.complete(Result.success('4'));
          await tester.pump();

          expect(
            logs.where((line) => line.contains('CanvasAnswerWithVision')),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        } finally {
          debugPrint = previousDebugPrint;
        }
      },
    );
  });
}
