import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import '../../../helpers/fakes.dart';

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);
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
        studentIdService: FakeStudentIdService(),
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
        studentIdService: FakeStudentIdService(),
      );
      final dueCounts = await service.loadDueCounts(subjects);
      expect(dueCounts['missing'], 0);
    });

    test('loadTopicsWithNames extracts unique topic id->name mapping', () async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topic: 'Algebra', topicId: 't1'),
        _question(id: 'q2', topic: 'Geometry', topicId: 't2'),
        _question(id: 'q3', topic: 'Algebra', topicId: 't1'),
        _question(id: 'q4', topic: '', topicId: 't4'),
        _question(id: 'q5', topic: null, topicId: 't5'),
      ]);

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: FakeStudentIdService(),
      );
      final topics = await service.loadTopicsWithNames(questionRepo);
      expect(topics, hasLength(2));
      expect(topics['t1'], 'Algebra');
      expect(topics['t2'], 'Geometry');
    });

    test('loadTopicsWithNames returns empty map when getAll fails', () async {
      final questionRepo = _FakeFailingQuestionRepository();

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: FakeStudentIdService(),
      );
      final topics = await service.loadTopicsWithNames(questionRepo);
      expect(topics, isEmpty);
    });

    test('loadTopicIds returns topic IDs', () async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topicId: 't1'),
        _question(id: 'q2', topicId: 't1'),
        _question(id: 'q3', topicId: 't2'),
      ]);

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: FakeStudentIdService(),
      );
      final ids = await service.loadTopicIds(questionRepo);
      expect(ids, hasLength(2));
      expect(ids, containsAll(['t1', 't2']));
    });

    test('loadTopicIds returns empty list when getAll fails', () async {
      final failingRepo = _FakeFailingQuestionRepository();

      final service = PracticeDataService(
        srService: _FakeSpacedRepetitionService({}),
        questionRepo: failingRepo,
        subjectRepo: _FakeSubjectRepository([]),
        studentIdService: FakeStudentIdService(),
      );
      final result = await service.loadTopicIds(failingRepo);
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
        studentIdService: FakeStudentIdService(),
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
        studentIdService: FakeStudentIdService(),
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
        studentIdService: FakeStudentIdService(),
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
        studentIdService: FakeStudentIdService(),
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
        studentIdService: FakeStudentIdService(),
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
        studentIdService: FakeStudentIdService(),
      );
      final result = await service.loadWeakAreaQuestions(masteryService);
      expect(result, isEmpty);
    });
  });


  group('PracticeDataService - coverage gaps', () {
  test('loadTopicsWithNames returns empty when questions empty', () async {
    final questionRepo = _FakeQuestionRepo4([]);
    final service = PracticeDataService(
      srService: _FakeSrService2({}),
      questionRepo: questionRepo,
      subjectRepo: _FakeSubjectRepo2([]),
      studentIdService: FakeStudentIdService(),
    );
    final topics = await service.loadTopicsWithNames(questionRepo);
    expect(topics, isEmpty);
  });

  test('loadTopicsWithNames returns map of topic id to name', () async {
    final questionRepo = _FakeQuestionRepo4([
      Question(
        id: 'q1',
        text: 'Q',
        type: QuestionType.singleChoice,
        subjectId: 's1',
        topicId: 't1',
        topic: null,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      Question(
        id: 'q2',
        text: 'Q2',
        type: QuestionType.singleChoice,
        subjectId: 's1',
        topicId: 't2',
        topic: 'Algebra',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ]);
    final service = PracticeDataService(
      srService: _FakeSrService2({}),
      questionRepo: questionRepo,
      subjectRepo: _FakeSubjectRepo2([]),
      studentIdService: FakeStudentIdService(),
    );
    final topics = await service.loadTopicsWithNames(questionRepo);
    expect(topics, hasLength(1));
    expect(topics['t2'], 'Algebra');
  });

  test('loadDueCounts handles empty subjects list', () async {
    final srService = _FakeSrService2({});
    final service = PracticeDataService(
      srService: srService,
      questionRepo: _FakeQuestionRepo4([]),
      subjectRepo: _FakeSubjectRepo2([]),
      studentIdService: FakeStudentIdService(),
    );
    final dueCounts = await service.loadDueCounts([]);
    expect(dueCounts, isEmpty);
  });

  test('loadWeakAreaQuestions returns empty when getWeakTopics returns empty list',
      () async {
    FakeStudentIdService().setStudentId('test-student');
    final masteryService = _FakeMasteryGraphSvc2();
    final service = PracticeDataService(
      srService: _FakeSrService2({}),
      questionRepo: _FakeQuestionRepo4([]),
      subjectRepo: _FakeSubjectRepo2([]),
      studentIdService: FakeStudentIdService(),
    );
    final result = await service.loadWeakAreaQuestions(masteryService);
    expect(result, isEmpty);
  });
});
}

class _FakeFailingQuestionRepository extends QuestionRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Question>>> getAll() async => Result.failure('Failed to load');
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final Result<List<MasteryState>> _result;

  _FakeMasteryGraphService(this._result);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return _result;
  }
}

class _FakeMasteryGraphServiceFailure extends MasteryGraphService {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.failure('error');
  }
}

class _FakeQuestionRepo4 extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepo4(this._questions);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);
}

class _FakeSrService2 extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;

  _FakeSrService2(this._dueCounts)
      : super(
          questionRepo: QuestionRepository(),
          attemptRepo: AttemptRepository(),
        );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }
}

class _FakeSubjectRepo2 extends SubjectRepository {
  final List<Subject> _subjects;
  _FakeSubjectRepo2(this._subjects);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_subjects);
}

class _FakeMasteryGraphSvc2 extends MasteryGraphService {
  _FakeMasteryGraphSvc2();

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(<MasteryState>[]);
  }
}
