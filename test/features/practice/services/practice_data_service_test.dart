import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepository(this._questions);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);
}

class _FakeStudentIdService extends StudentIdService {
  String _studentId = 'test-student';
  @override
  void setStudentId(String id) => _studentId = id;
  @override
  String getStudentId() => _studentId;
  @override
  Future<void> init() async {}
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;

  _FakeSpacedRepetitionService(this._dueCounts) : super(
    questionRepo: QuestionRepository(),
    attemptRepo: AttemptRepository(),
  );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }
}

class _FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects;
  _FakeSubjectRepository(this._subjects);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_subjects);
}

Question _question({
  String id = 'q1',
  String text = 'Question',
  String? topic,
  String topicId = 'topic-1',
}) {
  return Question(
    id: id,
    text: text,
    type: QuestionType.singleChoice,
    subjectId: 'subj-1',
    topicId: topicId,
    topic: topic,
    markscheme: Markscheme(questionId: id, correctAnswer: 'A'),
    options: ['A', 'B'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('PracticeDataService', () {
    test('loadDueCounts returns counts per subject', () async {
      final srService = _FakeSpacedRepetitionService({'subj-1': 5, 'subj-2': 3});
      final subjects = [
        Subject(id: 'subj-1', name: 'Math'),
        Subject(id: 'subj-2', name: 'Physics'),
      ];

      final service = PracticeDataService(
        srService: srService,
        questionRepo: _FakeQuestionRepository([]),
        subjectRepo: _FakeSubjectRepository(subjects),
        studentIdService: _FakeStudentIdService(),
      );
      final dueCounts = await service.loadDueCounts(subjects);
      expect(dueCounts['subj-1'], 5);
      expect(dueCounts['subj-2'], 3);
    });

    test('loadDueCounts defaults to 0 on failure', () async {
      final srService = _FakeSpacedRepetitionService({'subj-1': 5});
      final subjects = [Subject(id: 'missing', name: 'Unknown')];

      final service = PracticeDataService(
        srService: srService,
        questionRepo: _FakeQuestionRepository([]),
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final dueCounts = await service.loadDueCounts(subjects);
      expect(dueCounts['missing'], 0);
    });

    test('loadTopics extracts unique non-empty topics', () async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topic: 'Algebra'),
        _question(id: 'q2', topic: 'Geometry'),
        _question(id: 'q3', topic: 'Algebra'),
        _question(id: 'q4', topic: ''),
        _question(id: 'q5', topic: null),
      ]);

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final topics = await service.loadTopics(questionRepo);
      expect(topics, hasLength(2));
      expect(topics, containsAll(['Algebra', 'Geometry']));
    });

    test('loadTopics returns empty list when getAll fails', () async {
      final questionRepo = _FakeFailingQuestionRepository();

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final topics = await service.loadTopics(questionRepo);
      expect(topics, isEmpty);
    });

    test('loadTopicQuestions filters questions by topic', () async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topic: 'Algebra'),
        _question(id: 'q2', topic: 'Algebra'),
        _question(id: 'q3', topic: 'Geometry'),
      ]);

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final algebraQs = await service.loadTopicQuestions('Algebra');
      expect(algebraQs, hasLength(2));
    });

    test('loadTopicQuestions returns empty list when getAll fails', () async {
      final failingRepo = _FakeFailingQuestionRepository();

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: failingRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.loadTopicQuestions('Algebra');
      expect(result, isEmpty);
    });

    test('fetchSubjects returns subjects from repository', () async {
      final subjects = [
        Subject(id: 's1', name: 'Math'),
        Subject(id: 's2', name: 'Physics'),
      ];
      final subjectRepo = _FakeSubjectRepository(subjects);

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: _FakeQuestionRepository([]),
        subjectRepo: subjectRepo,
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.fetchSubjects();
      expect(result, hasLength(2));
      expect(result[0].id, 's1');
      expect(result[1].id, 's2');
    });

    test('fetchSubjects returns empty list when no subjects', () async {
      final subjectRepo = _FakeSubjectRepository([]);

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: _FakeQuestionRepository([]),
        subjectRepo: subjectRepo,
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.fetchSubjects();
      expect(result, isEmpty);
    });

    test('loadWeakAreaQuestions returns questions for weak topics', () async {
      // Student ID is handled by _FakeStudentIdService
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(Result.success([
        MasteryState(
          studentId: 'test-student', topicId: 'weak-topic',
          masteryLevel: MasteryLevel.novice,
          accuracy: 0.3, reviewUrgency: 0.9,
          lastAttempt: now.subtract(const Duration(days: 7)),
          lastUpdated: now.subtract(const Duration(days: 7)),
        ),
      ]));
      final questions = [
        _question(id: 'q1', topic: 'Algebra', topicId: 'weak-topic'),
        _question(id: 'q2', topic: 'Geometry', topicId: 'other-topic'),
      ];
      final questionRepo = _FakeQuestionRepository(questions);

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.loadWeakAreaQuestions(masteryService);
      expect(result, hasLength(1));
      expect(result.first.id, 'q1');
    });

    test('loadWeakAreaQuestions returns empty when no weak topics', () async {
      // Student ID is handled by _FakeStudentIdService
      final masteryService = _FakeMasteryGraphService(Result.success([]));

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: _FakeQuestionRepository([]),
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.loadWeakAreaQuestions(masteryService);
      expect(result, isEmpty);
    });

    test('loadWeakAreaQuestions returns empty when getWeakTopics fails', () async {
      // Student ID is handled by _FakeStudentIdService
      final masteryService = _FakeMasteryGraphServiceFailure();

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: _FakeQuestionRepository([]),
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.loadWeakAreaQuestions(masteryService);
      expect(result, isEmpty);
    });

    test('loadWeakAreaQuestions returns empty when getAll fails', () async {
      // Student ID is handled by _FakeStudentIdService
      final now = DateTime.now();
      final masteryService = _FakeMasteryGraphService(Result.success([
        MasteryState(
          studentId: 'test-student', topicId: 'weak-topic',
          masteryLevel: MasteryLevel.novice,
          accuracy: 0.3, reviewUrgency: 0.9,
          lastAttempt: now.subtract(const Duration(days: 7)),
          lastUpdated: now.subtract(const Duration(days: 7)),
        ),
      ]));
      final failingRepo = _FakeFailingQuestionRepository();

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: failingRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.loadWeakAreaQuestions(masteryService);
      expect(result, isEmpty);
    });
  });
}

class _FakeFailingQuestionRepository extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => throw Exception('Failed to load');
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final Result<List<MasteryState>> _result;

  _FakeMasteryGraphService(this._result);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return _result;
  }
}

class _FakeMasteryGraphServiceFailure extends MasteryGraphService {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.failure('error');
  }
}
