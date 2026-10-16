import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/services/mastery_context_builder.dart';

void main() {
  group('MasteryContextBuilder', () {
    final builder = MasteryContextBuilder();

    TutorSession makeSession({
      required String topicTitle,
      int asked = 2,
      int correct = 1,
    }) =>
        TutorSession(
          id: 's1',
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: topicTitle,
          startTime: DateTime(2024, 1, 1),
          questionsAsked: asked,
          questionsCorrect: correct,
        );

    MasteryState makeWeakTopic({
      required String topicId,
      double accuracy = 0.4,
      int attempts = 5,
      List<String> weakSubtopics = const [],
    }) =>
        MasteryState(
          studentId: 'student-1',
          topicId: topicId,
          accuracy: accuracy,
          totalAttempts: attempts,
          lastAttempt: DateTime(2024, 1, 2),
          lastUpdated: DateTime(2024, 1, 2),
          weakSubtopics: weakSubtopics,
          subjectId: 'math',
        );

    test('returns null when both weak topics and history are empty', () {
      expect(builder.build(weakTopics: [], recentSessions: []), isNull);
    });

    test('includes weak topics with topic id, accuracy and attempts', () {
      final context = builder.build(
        weakTopics: [makeWeakTopic(topicId: 'topic-fractions', attempts: 7)],
        recentSessions: [],
      );

      expect(context, isNotNull);
      expect(context, contains('weak areas to watch'));
      expect(context, contains('topic-fractions'));
      // accuracy 0.4 -> 40%
      expect(context, contains('40%'));
      expect(context, contains('7 attempts'));
    });

    test('surfaces weak subtopics when present', () {
      final context = builder.build(
        weakTopics: [
          makeWeakTopic(
            topicId: 'topic-integrals',
            weakSubtopics: ['chain-rule', 'u-substitution'],
          ),
        ],
        recentSessions: [],
      );

      expect(context, isNotNull);
      expect(context, contains('weak in chain-rule, u-substitution'));
    });

    test('includes recent lesson history with title and accuracy', () {
      final context = builder.build(
        weakTopics: [],
        recentSessions: [
          makeSession(topicTitle: 'Algebra Basics', asked: 4, correct: 2),
        ],
      );

      expect(context, isNotNull);
      expect(context, contains('Recent lesson history'));
      expect(context, contains('Algebra Basics'));
      // 2/4 correct -> 50%
      expect(context, contains('2/4'));
      expect(context, contains('50%'));
    });

    test('excludes sessions with no questions asked', () {
      // The just-started in-session is saved with questionsAsked == 0 and
      // must NOT pollute the history note.
      final context = builder.build(
        weakTopics: [],
        recentSessions: [makeSession(topicTitle: 'Fresh lesson', asked: 0)],
      );

      expect(context, isNull);
    });

    test('limits to at most 3 weak topics and 3 recent sessions', () {
      final context = builder.build(
        weakTopics: List.generate(
          6,
          (i) => makeWeakTopic(topicId: 'topic-$i'),
        ),
        recentSessions: List.generate(
          6,
          (i) => makeSession(topicTitle: 'Lesson $i'),
        ),
      );

      expect(context, isNotNull);
      expect(context!.split('topic-4'), hasLength(1));
      expect(context.split('topic-5'), hasLength(1));
      expect(context.split('Lesson 3'), hasLength(1));
      expect(context.split('Lesson 4'), hasLength(1));
    });

    test('combines weak topics and recent history', () {
      final context = builder.build(
        weakTopics: [makeWeakTopic(topicId: 'topic-decimals')],
        recentSessions: [makeSession(topicTitle: 'Fractions')],
      );

      expect(context, isNotNull);
      expect(context, contains('weak areas to watch'));
      expect(context, contains('topic-decimals'));
      expect(context, contains('Recent lesson history'));
      expect(context, contains('Fractions'));
    });
  });
}
