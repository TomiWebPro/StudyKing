import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/mentor/services/tools/create_practice_session_tool.dart';
import '../../../../helpers/fakes.dart';

Question _createQuestion({
  String id = 'q-1',
  String text = 'What is 2+2?',
  QuestionType type = QuestionType.singleChoice,
  int difficulty = 1,
  String topicId = 'topic-1',
  String subjectId = 'subj-1',
  DateTime? nextReview,
}) {
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    nextReview: nextReview,
  );
}

class MutableQuestionRepository extends FakeQuestionRepository {
  final List<Question> _questions = [];

  void setQuestions(List<Question> questions) {
    _questions.clear();
    _questions.addAll(questions);
  }

  @override
  Future<Result<List<Question>>> getAll() async =>
      Result.success(List.from(_questions));

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async =>
      Result.success(
        _questions.where((q) => q.subjectId == subjectId).toList(),
      );

  @override
  Future<Result<List<Question>>> getByTopic(String topicId) async =>
      Result.success(
        _questions.where((q) => q.topicId == topicId).toList(),
      );
}

class FakeMasteryForTool extends MasteryGraphService {
  Result<List<MasteryState>>? _weakTopicsResult;
  Result<List<QuestionMasteryState>>? _atRiskResult;
  List<MasteryState> _allTopicMastery = [];
  List<QuestionMasteryState> _allQuestionMastery = [];

  FakeMasteryForTool()
      : super(
          masteryStateRepo: null,
          questionMasteryRepo: null,
          topicDependencyRepo: null,
          questionEvaluationRepo: null,
        );

  void setWeakTopics(Result<List<MasteryState>> result) =>
      _weakTopicsResult = result;
  void setAtRiskQuestions(Result<List<QuestionMasteryState>> result) =>
      _atRiskResult = result;
  void setAllTopicMastery(List<MasteryState> data) =>
      _allTopicMastery = data;
  void setAllQuestionMastery(List<QuestionMasteryState> data) =>
      _allQuestionMastery = data;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async =>
      _weakTopicsResult ?? Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async =>
      _atRiskResult ?? Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async =>
      Result.success(_allTopicMastery);

  @override
  Future<Result<List<QuestionMasteryState>>> getAllQuestionMastery(
    String studentId,
  ) async =>
      Result.success(_allQuestionMastery);
}

class FakeSRService extends SpacedRepetitionService {
  Result<List<Question>>? _practiceQuestionsResult;

  FakeSRService()
      : super(
          questionRepo: FakeQuestionRepository(),
          attemptRepo: FakeAttemptRepository(),
        );

  void setPracticeQuestions(Result<List<Question>> result) =>
      _practiceQuestionsResult = result;

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async =>
      _practiceQuestionsResult ?? Result.success([]);
}

class FakeExamSessionService extends ExamSessionService {
  FakeExamSessionService()
      : super(
          sessionRepo: FakeSessionRepository(),
          studentIdService: FakeStudentIdService(),
        );
}

MasteryState _createMasteryState({
  String topicId = 'topic-1',
  double accuracy = 0.45,
  double reviewUrgency = 0.8,
  double readinessScore = 0.3,
}) {
  return MasteryState(
    studentId: 'student-1',
    topicId: topicId,
    accuracy: accuracy,
    lastAttempt: DateTime.now(),
    lastUpdated: DateTime.now(),
    reviewUrgency: reviewUrgency,
    readinessScore: readinessScore,
  );
}

QuestionMasteryState _createAtRiskQuestion({String questionId = 'q-1'}) {
  return QuestionMasteryState(
    studentId: 'student-1',
    questionId: questionId,
    masteryLevel: 0.3,
    lastAttempt: DateTime.now(),
    nextReview: DateTime.now().add(const Duration(hours: 1)),
  );
}

void main() {
  group('CreatePracticeSessionTool', () {
    late MutableQuestionRepository fakeRepo;
    late FakeSRService fakeSrService;
    late FakeMasteryForTool fakeMastery;
    late FakeStudentIdService fakeStudentId;
    late CreatePracticeSessionTool tool;

    setUp(() {
      fakeRepo = MutableQuestionRepository();
      fakeSrService = FakeSRService();
      fakeMastery = FakeMasteryForTool();
      fakeStudentId = FakeStudentIdService()..setStudentId('student-1');
      final fakeScorer = ReadinessScorer(
        masteryService: fakeMastery,
        studentIdService: fakeStudentId,
      );
      tool = CreatePracticeSessionTool(
        questionRepo: fakeRepo,
        srService: fakeSrService,
        masteryService: fakeMastery,
        scorer: fakeScorer,
        examSessionService: FakeExamSessionService(),
        studentIdService: fakeStudentId,
      );
    });

    test('name returns create_practice_session', () {
      expect(tool.name, 'create_practice_session');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['required'], ['mode']);
      final properties = params['properties'] as Map<String, dynamic>;
      expect(properties.keys, containsAll([
        'mode',
        'subjectId',
        'topicId',
        'questionCount',
        'durationMinutes',
        'easyCount',
        'mediumCount',
        'hardCount',
      ]));
      expect(properties['mode']['type'], 'string');
      expect(properties['mode']['enum'], containsAll([
        'spaced_repetition',
        'weak_areas',
        'topic_focus',
        'at_risk',
        'exam',
      ]));
    });

    test('execute returns error when mode is missing', () async {
      final result = await tool.execute({});
      expect(result['success'], false);
      expect(result['error'], contains('mode'));
    });

    test('execute returns error for unknown mode', () async {
      final result = await tool.execute({'mode': 'unknown'});
      expect(result['success'], false);
      expect(result['error'], contains('Unknown mode'));
    });

    group('spaced_repetition mode', () {
      test('returns error when subjectId is missing', () async {
        final result = await tool.execute({'mode': 'spaced_repetition'});
        expect(result['success'], false);
        expect(result['error'], contains('subjectId'));
      });

      test('returns empty when no questions are due', () async {
        fakeSrService.setPracticeQuestions(Result.success([]));
        final result = await tool.execute({
          'mode': 'spaced_repetition',
          'subjectId': 'subj-1',
        });
        expect(result['success'], true);
        expect(result['questionCount'], 0);
        expect(result['isSpacedRepetition'], true);
      });

      test('returns questions sorted by nextReview', () async {
        final q1 = _createQuestion(
          id: 'q-1',
          nextReview: DateTime.now().add(const Duration(hours: 2)),
        );
        final q2 = _createQuestion(
          id: 'q-2',
          nextReview: DateTime.now(),
        );
        fakeSrService.setPracticeQuestions(Result.success([q1, q2]));

        final result = await tool.execute({
          'mode': 'spaced_repetition',
          'subjectId': 'subj-1',
        });
        expect(result['success'], true);
        expect(result['questionCount'], 2);
        expect(result['questionIds'], ['q-2', 'q-1']);
      });

      test('respects questionCount limit', () async {
        final questions = List.generate(
          20,
          (i) => _createQuestion(id: 'q-$i', nextReview: DateTime.now()),
        );
        fakeSrService.setPracticeQuestions(Result.success(questions));

        final result = await tool.execute({
          'mode': 'spaced_repetition',
          'subjectId': 'subj-1',
          'questionCount': 5,
        });
        expect(result['success'], true);
        expect(result['questionCount'], 5);
      });
    });

    group('weak_areas mode', () {
      test('returns error when subjectId is missing', () async {
        final result = await tool.execute({'mode': 'weak_areas'});
        expect(result['success'], false);
        expect(result['error'], contains('subjectId'));
      });

      test('returns empty message when no weak topics', () async {
        fakeMastery.setWeakTopics(Result.success([]));
        final result = await tool.execute({
          'mode': 'weak_areas',
          'subjectId': 'subj-1',
        });
        expect(result['success'], true);
        expect(result['questionCount'], 0);
        expect(result['message'], contains('No weak areas'));
      });

      test('returns weak area questions scored and ordered', () async {
        fakeMastery.setWeakTopics(Result.success([
          _createMasteryState(topicId: 'topic-1'),
        ]));
        fakeRepo.setQuestions([
          _createQuestion(id: 'q-1', topicId: 'topic-1', subjectId: 'subj-1'),
          _createQuestion(id: 'q-2', topicId: 'topic-1', subjectId: 'subj-1'),
        ]);

        final result = await tool.execute({
          'mode': 'weak_areas',
          'subjectId': 'subj-1',
        });
        expect(result['success'], true);
        expect(result['questionCount'], 2);
        expect(result['questionIds'], containsAll(['q-1', 'q-2']));
        expect(result['topicsCovered'], contains('topic-1'));
      });

      test('filters to correct subject', () async {
        fakeMastery.setWeakTopics(Result.success([
          _createMasteryState(topicId: 'topic-1'),
        ]));
        fakeRepo.setQuestions([
          _createQuestion(id: 'q-1', topicId: 'topic-1', subjectId: 'subj-1'),
          _createQuestion(id: 'q-2', topicId: 'topic-1', subjectId: 'subj-2'),
        ]);

        final result = await tool.execute({
          'mode': 'weak_areas',
          'subjectId': 'subj-1',
        });
        expect(result['questionCount'], 1);
        expect(result['questionIds'], ['q-1']);
      });
    });

    group('topic_focus mode', () {
      test('returns error when subjectId is missing', () async {
        final result = await tool.execute({
          'mode': 'topic_focus',
          'topicId': 'topic-1',
        });
        expect(result['success'], false);
        expect(result['error'], contains('subjectId'));
      });

      test('returns error when topicId is missing', () async {
        final result = await tool.execute({
          'mode': 'topic_focus',
          'subjectId': 'subj-1',
        });
        expect(result['success'], false);
        expect(result['error'], contains('topicId'));
      });

      test('returns empty when no questions for topic', () async {
        fakeRepo.setQuestions([]);
        final result = await tool.execute({
          'mode': 'topic_focus',
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
        });
        expect(result['success'], true);
        expect(result['questionCount'], 0);
      });

      test('returns questions for the specified topic', () async {
        fakeRepo.setQuestions([
          _createQuestion(id: 'q-1', topicId: 'topic-1', subjectId: 'subj-1'),
          _createQuestion(id: 'q-2', topicId: 'topic-1', subjectId: 'subj-1'),
          _createQuestion(id: 'q-3', topicId: 'topic-2', subjectId: 'subj-1'),
        ]);

        final result = await tool.execute({
          'mode': 'topic_focus',
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
        });
        expect(result['success'], true);
        expect(result['questionCount'], 2);
        expect(result['questionIds'], containsAll(['q-1', 'q-2']));
        expect(result['topicsCovered'], ['topic-1']);
      });
    });

    group('at_risk mode', () {
      test('returns empty message when no at-risk questions', () async {
        fakeMastery.setAtRiskQuestions(Result.success([]));
        final result = await tool.execute({'mode': 'at_risk'});
        expect(result['success'], true);
        expect(result['questionCount'], 0);
        expect(result['message'], contains('No at-risk'));
      });

      test('returns at-risk questions scored and ordered', () async {
        fakeMastery.setAtRiskQuestions(Result.success([
          _createAtRiskQuestion(questionId: 'q-1'),
          _createAtRiskQuestion(questionId: 'q-2'),
        ]));
        fakeRepo.setQuestions([
          _createQuestion(id: 'q-1', subjectId: 'subj-1'),
          _createQuestion(id: 'q-2', subjectId: 'subj-1'),
          _createQuestion(id: 'q-3', subjectId: 'subj-1'),
        ]);

        final result = await tool.execute({
          'mode': 'at_risk',
          'questionCount': 5,
        });
        expect(result['success'], true);
        expect(result['questionCount'], 2);
        expect(result['questionIds'], containsAll(['q-1', 'q-2']));
      });
    });

    group('exam mode', () {
      test('returns error when subjectId is missing', () async {
        final result = await tool.execute({'mode': 'exam'});
        expect(result['success'], false);
        expect(result['error'], contains('subjectId'));
      });

      test('returns empty when no questions available', () async {
        fakeRepo.setQuestions([]);
        final result = await tool.execute({
          'mode': 'exam',
          'subjectId': 'subj-1',
          'questionCount': 10,
          'durationMinutes': 30,
        });
        expect(result['success'], true);
        expect(result['questionCount'], 0);
      });

      test('returns questions with difficulty breakdown', () async {
        fakeRepo.setQuestions([
          _createQuestion(id: 'q-1', difficulty: 1, subjectId: 'subj-1'),
          _createQuestion(id: 'q-2', difficulty: 2, subjectId: 'subj-1'),
          _createQuestion(id: 'q-3', difficulty: 3, subjectId: 'subj-1'),
          _createQuestion(id: 'q-4', difficulty: 4, subjectId: 'subj-1'),
          _createQuestion(id: 'q-5', difficulty: 5, subjectId: 'subj-1'),
        ]);

        final result = await tool.execute({
          'mode': 'exam',
          'subjectId': 'subj-1',
          'questionCount': 5,
          'durationMinutes': 30,
        });
        expect(result['success'], true);
        expect(result['questionCount'], 5);
        expect(result['durationMinutes'], 30);
        expect(result['difficultyBreakdown'], isNotNull);
      });

      test('respects difficulty quotas', () async {
        fakeRepo.setQuestions([
          _createQuestion(id: 'q-1', difficulty: 1, subjectId: 'subj-1'),
          _createQuestion(id: 'q-2', difficulty: 1, subjectId: 'subj-1'),
          _createQuestion(id: 'q-3', difficulty: 3, subjectId: 'subj-1'),
          _createQuestion(id: 'q-4', difficulty: 3, subjectId: 'subj-1'),
          _createQuestion(id: 'q-5', difficulty: 5, subjectId: 'subj-1'),
          _createQuestion(id: 'q-6', difficulty: 5, subjectId: 'subj-1'),
        ]);

        final result = await tool.execute({
          'mode': 'exam',
          'subjectId': 'subj-1',
          'questionCount': 4,
          'durationMinutes': 20,
          'easyCount': 1,
          'mediumCount': 1,
          'hardCount': 1,
        });
        expect(result['success'], true);
        expect(result['questionCount'], lessThanOrEqualTo(4));
        expect(result['questionCount'], greaterThanOrEqualTo(3));
        final breakdown = result['difficultyBreakdown'] as Map<String, dynamic>;
        expect(breakdown['easy'], greaterThanOrEqualTo(0));
        expect(breakdown['medium'], greaterThanOrEqualTo(0));
        expect(breakdown['hard'], greaterThanOrEqualTo(0));
      });
    });
  });
}
