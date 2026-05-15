import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepository(this._questions);

  @override
  Future<void> init() async {}

  @override
  Future<List<Question>> getAll() async => _questions;
}

class _FakeSpacedRepetitionRepository extends SpacedRepetitionRepository {
  final Map<String, int> _dueCounts;

  _FakeSpacedRepetitionRepository(this._dueCounts);

  @override
  Future<void> init() async {}

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }
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
    testWidgets('loadDueCounts returns counts per subject', (tester) async {
      final srRepo = _FakeSpacedRepetitionRepository({'subj-1': 5, 'subj-2': 3});
      final subjects = [
        Subject(id: 'subj-1', name: 'Math'),
        Subject(id: 'subj-2', name: 'Physics'),
      ];

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          spacedRepetitionRepositoryProvider.overrideWithValue(srRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final dueCounts = await service.loadDueCounts(subjects);
      expect(dueCounts['subj-1'], 5);
      expect(dueCounts['subj-2'], 3);
    });

    testWidgets('loadDueCounts defaults to 0 on failure', (tester) async {
      final srRepo = _FakeSpacedRepetitionRepository({'subj-1': 5});
      final subjects = [Subject(id: 'missing', name: 'Unknown')];

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          spacedRepetitionRepositoryProvider.overrideWithValue(srRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final dueCounts = await service.loadDueCounts(subjects);
      expect(dueCounts['missing'], 0);
    });

    testWidgets('loadTopics extracts unique non-empty topics', (tester) async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topic: 'Algebra'),
        _question(id: 'q2', topic: 'Geometry'),
        _question(id: 'q3', topic: 'Algebra'),
        _question(id: 'q4', topic: ''),
        _question(id: 'q5', topic: null),
      ]);

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final topics = await service.loadTopics(questionRepo);
      expect(topics, hasLength(2));
      expect(topics, containsAll(['Algebra', 'Geometry']));
    });

    testWidgets('loadTopics returns empty list when getAll fails', (tester) async {
      final questionRepo = _FakeFailingQuestionRepository();

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final topics = await service.loadTopics(questionRepo);
      expect(topics, isEmpty);
    });

    testWidgets('loadTopicQuestions filters questions by topic', (tester) async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topic: 'Algebra'),
        _question(id: 'q2', topic: 'Algebra'),
        _question(id: 'q3', topic: 'Geometry'),
      ]);

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final algebraQs = await service.loadTopicQuestions('Algebra');
      expect(algebraQs, hasLength(2));
    });

    testWidgets('loadTopicQuestions returns empty list when getAll fails', (tester) async {
      final failingRepo = _FakeFailingQuestionRepository();

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(failingRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.loadTopicQuestions('Algebra');
      expect(result, isEmpty);
    });

    testWidgets('fetchSubjects returns subjects from repository', (tester) async {
      final subjects = [
        Subject(id: 's1', name: 'Math'),
        Subject(id: 's2', name: 'Physics'),
      ];
      final subjectRepo = _FakeSubjectRepository(subjects);

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          subjectsRepositoryProvider.overrideWith(
            () => _FakeSubjectsRepositoryNotifier(subjectRepo),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.fetchSubjects();
      expect(result, hasLength(2));
      expect(result[0].id, 's1');
      expect(result[1].id, 's2');
    });

    testWidgets('fetchSubjects returns empty list when no subjects', (tester) async {
      final subjectRepo = _FakeSubjectRepository([]);

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          subjectsRepositoryProvider.overrideWith(
            () => _FakeSubjectsRepositoryNotifier(subjectRepo),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.fetchSubjects();
      expect(result, isEmpty);
    });

    testWidgets('loadWeakAreaQuestions returns questions for weak topics', (tester) async {
      StudentIdService().setStudentId('test-student');
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

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.loadWeakAreaQuestions(masteryService, tester.binding.rootElement! as BuildContext);
      expect(result, hasLength(1));
      expect(result.first.id, 'q1');
    });

    testWidgets('loadWeakAreaQuestions returns empty when no weak topics', (tester) async {
      StudentIdService().setStudentId('test-student');
      final masteryService = _FakeMasteryGraphService(Result.success([]));

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.loadWeakAreaQuestions(masteryService, tester.binding.rootElement! as BuildContext);
      expect(result, isEmpty);
    });

    testWidgets('loadWeakAreaQuestions returns empty when getWeakTopics fails', (tester) async {
      StudentIdService().setStudentId('test-student');
      final masteryService = _FakeMasteryGraphServiceFailure();

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.loadWeakAreaQuestions(masteryService, tester.binding.rootElement! as BuildContext);
      expect(result, isEmpty);
    });

    testWidgets('loadWeakAreaQuestions returns empty when getAll fails', (tester) async {
      StudentIdService().setStudentId('test-student');
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

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(failingRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.loadWeakAreaQuestions(masteryService, tester.binding.rootElement! as BuildContext);
      expect(result, isEmpty);
    });
  });
}

class _FakeFailingQuestionRepository extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<Question>> getAll() async => throw Exception('Failed to load');
}

class _FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects;
  _FakeSubjectRepository(this._subjects);

  @override
  Future<List<Subject>> getAll() async => _subjects;
}

class _FakeSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _FakeSubjectsRepositoryNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
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
