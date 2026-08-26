import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/mentor/services/tools/create_practice_session_tool.dart';
import 'test_helpers.dart';

Question _q(String id, String subjectId, String topicId, int difficulty) {
  final now = DateTime.now();
  return Question(
    id: id,
    text: 'Q $id',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    difficulty: difficulty,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CreatePracticeSessionTool', () {
    late FakeStudentIdService studentIdService;
    late FakeQuestionRepository questionRepo;
    late FakeMasteryGraphService mastery;
    late FakeReadinessScorer scorer;
    late FakeExamSessionService examSession;

    setUp(() {
      studentIdService = FakeStudentIdService('student-1');
      questionRepo = FakeQuestionRepository();
      mastery = FakeMasteryGraphService();
      scorer = FakeReadinessScorer();
      examSession = FakeExamSessionService();
    });

    test('spaced_repetition mode returns due question ids', () async {
      final due = [_q('q1', 's1', 't1', 1), _q('q2', 's1', 't1', 2)];
      final sr = FakeSpacedRepetitionService(due);
      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: sr,
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({
        'mode': 'spaced_repetition',
        'subjectId': 's1',
      });

      expect(result['success'], isTrue);
      expect(result['mode'], equals('spaced_repetition'));
      expect(result['questionCount'], equals(2));
      expect(result['questionIds'], equals(['q1', 'q2']));
      expect(result['topicsCovered'], equals(['t1']));
    });

    test('spaced_repetition mode requires subjectId', () async {
      final sr = FakeSpacedRepetitionService(const []);
      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: sr,
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'mode': 'spaced_repetition'});
      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId is required'));
    });

    test('weak_areas mode targets weak topics in the subject', () async {
      final weak = [
        MasteryState.initial(studentId: 'student-1', topicId: 't1')
            .copyWith(readinessScore: 0.2),
      ];
      mastery.weakTopics = weak;
      questionRepo.setQuestions([
        _q('q1', 's1', 't1', 1),
        _q('q2', 's1', 't2', 1),
      ]);

      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: FakeSpacedRepetitionService(const []),
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({
        'mode': 'weak_areas',
        'subjectId': 's1',
      });

      expect(result['success'], isTrue);
      expect(result['questionIds'], equals(['q1']));
    });

    test('at_risk mode matches at-risk question ids to the bank', () async {
      final atRisk = [
        QuestionMasteryState.initial(
          studentId: 'student-1',
          questionId: 'qA',
          now: DateTime.now(),
        ),
      ];
      mastery.atRisk = atRisk;
      questionRepo.setQuestions([_q('qA', 's1', 't1', 3)]);

      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: FakeSpacedRepetitionService(const []),
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'mode': 'at_risk'});
      expect(result['success'], isTrue);
      expect(result['questionIds'], equals(['qA']));
    });

    test('topic_focus mode filters by topic and subject', () async {
      questionRepo.setQuestions([
        _q('q1', 's1', 't1', 1),
        _q('q2', 's1', 't2', 1),
      ]);
      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: FakeSpacedRepetitionService(const []),
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({
        'mode': 'topic_focus',
        'subjectId': 's1',
        'topicId': 't1',
      });
      expect(result['success'], isTrue);
      expect(result['questionIds'], equals(['q1']));
    });

    test('exam mode returns a difficulty breakdown', () async {
      questionRepo.setQuestions([
        _q('q1', 's1', 't1', 1),
        _q('q2', 's1', 't1', 3),
        _q('q3', 's1', 't1', 5),
      ]);
      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: FakeSpacedRepetitionService(const []),
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({
        'mode': 'exam',
        'subjectId': 's1',
        'durationMinutes': 30,
      });
      expect(result['success'], isTrue);
      expect(result['questionCount'], equals(3));
      final breakdown = result['difficultyBreakdown'] as Map;
      expect(breakdown['easy'], equals(1));
      expect(breakdown['medium'], equals(1));
      expect(breakdown['hard'], equals(1));
    });

    test('weak_areas degrades gracefully when there are no weak topics',
        () async {
      mastery.weakTopics = const [];
      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: FakeSpacedRepetitionService(const []),
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({
        'mode': 'weak_areas',
        'subjectId': 's1',
      });
      expect(result['success'], isTrue);
      expect(result['questionCount'], equals(0));
      expect(result['questionIds'], equals([]));
      expect(result['message'], contains('No weak areas'));
    });

    test('reports an error when no mode is supplied', () async {
      final tool = CreatePracticeSessionTool(
        questionRepo: questionRepo,
        srService: FakeSpacedRepetitionService(const []),
        masteryService: mastery,
        scorer: scorer,
        examSessionService: examSession,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});
      expect(result['success'], isFalse);
      expect(result['error'], contains('required'));
    });
  });
}
