import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/mentor/services/tools/get_weak_topics_tool.dart';
import 'test_helpers.dart';

void main() {
  group('GetWeakTopicsTool', () {
    late FakeStudentIdService studentIdService;

    setUp(() => studentIdService = FakeStudentIdService('student-1'));

    test('returns weak topics and at-risk counts from the mastery service',
        () async {
      final weak = <MasteryState>[
        MasteryState.initial(studentId: 'student-1', topicId: 't1')
            .copyWith(accuracy: 0.4, reviewUrgency: 0.8, readinessScore: 0.3),
        MasteryState.initial(studentId: 'student-1', topicId: 't2')
            .copyWith(accuracy: 0.2, reviewUrgency: 0.9, readinessScore: 0.1),
      ];
      final atRisk = <QuestionMasteryState>[
        QuestionMasteryState.initial(
          studentId: 'student-1',
          questionId: 'q1',
          now: DateTime.now(),
        ),
      ];

      final mastery = FakeMasteryGraphService(weakTopics: weak, atRisk: atRisk);
      final tool = GetWeakTopicsTool(
        masteryService: mastery,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['weakTopicCount'], equals(2));
      expect(result['atRiskQuestionCount'], equals(1));
      final topics = result['weakTopics'] as List;
      expect(topics.length, equals(2));
      expect(topics[0]['topicId'], equals('t1'));
      expect(topics[0]['accuracy'], equals(0.4));
      expect(topics[0]['reviewUrgency'], equals(0.8));
      expect(topics[0]['readinessScore'], equals(0.3));
    });

    test('degrades gracefully with no weak topics or at-risk questions',
        () async {
      final mastery = FakeMasteryGraphService();
      final tool = GetWeakTopicsTool(
        masteryService: mastery,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['weakTopicCount'], equals(0));
      expect(result['atRiskQuestionCount'], equals(0));
      expect(result['weakTopics'], equals([]));
      expect(result['weakTopics'], isA<List>());
    });
  });
}
