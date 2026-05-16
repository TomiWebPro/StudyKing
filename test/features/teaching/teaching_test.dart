import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/teaching.dart';

void main() {
  group('teaching barrel', () {
    test('exports ConversationMessage', () {
      expect(ConversationMessage, isA<Type>());
    });

    test('exports TutorSession', () {
      expect(TutorSession, isA<Type>());
    });

    test('exports ConversationRepository', () {
      expect(ConversationRepository, isA<Type>());
    });

    test('exports TutorSessionRepository', () {
      expect(TutorSessionRepository, isA<Type>());
    });

    test('exports EvaluationResult', () {
      expect(EvaluationResult, isA<Type>());
    });

    test('exports LessonPlan', () {
      expect(LessonPlan, isA<Type>());
    });

    test('exports ConversationManager', () {
      expect(ConversationManager, isA<Type>());
    });

    test('exports ExerciseEvaluator', () {
      expect(ExerciseEvaluator, isA<Type>());
    });

    test('exports TutorService', () {
      expect(TutorService, isA<Type>());
    });

    test('exports VoiceController', () {
      expect(VoiceController, isA<Type>());
    });

    test('exports ChatBubble', () {
      expect(ChatBubble, isA<Type>());
    });

    test('exports LessonProgressBar', () {
      expect(LessonProgressBar, isA<Type>());
    });

    test('exports VoiceBar', () {
      expect(VoiceBar, isA<Type>());
    });

    test('exports TutorScreen', () {
      expect(TutorScreen, isA<Type>());
    });

    test('exports ConversationPromptSet', () {
      expect(ConversationPromptSet, isA<Type>());
    });

    test('exports PromptEntry', () {
      expect(PromptEntry, isA<Type>());
    });
  });
}
