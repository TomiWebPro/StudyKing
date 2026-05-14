import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';

class _MockTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<void> init() async {}

  @override
  Future<List<Topic>> getBySubject(String subjectId) async {
    return _topics.values.where((t) => t.subjectId == subjectId).toList();
  }

  @override
  Future<Topic?> get(String id) async => _topics[id];
}

class _MockMasteryRepository extends MasteryGraphRepository {
  final List<TopicDependency> _dependencies = [];
  final Map<String, MasteryState> _masteryStates = {};

  void addDependency(TopicDependency dep) => _dependencies.add(dep);

  void addMasteryState(MasteryState state) {
    _masteryStates['${state.studentId}_${state.topicId}'] = state;
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success(_dependencies);
  }

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success(
      _masteryStates.values.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final key = '${studentId}_$topicId';
    if (_masteryStates.containsKey(key)) {
      return Result.success(_masteryStates[key]!);
    }
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }
}

class _MockQuestionRepository extends QuestionRepository {
  final List<Question> _questions = [];

  void addQuestion(Question q) => _questions.add(q);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async {
    return Result.success(_questions);
  }
}

void main() {
  group('SyllabusResolver', () {
    late _MockTopicRepository topicRepo;
    late _MockMasteryRepository masteryRepo;
    late _MockQuestionRepository questionRepo;
    late SyllabusResolver resolver;

    setUp(() {
      topicRepo = _MockTopicRepository();
      masteryRepo = _MockMasteryRepository();
      questionRepo = _MockQuestionRepository();
      resolver = SyllabusResolver(
        topicRepository: topicRepo,
        masteryRepository: masteryRepo,
        questionRepository: questionRepo,
      );
    });

    group('resolveSyllabus', () {
      test('returns failure when no topics exist for subject', () async {
        final result = await resolver.resolveSyllabus(subjectId: 'empty_subject');
        expect(result.isFailure, true);
      });

      test('returns topics in topological order', () async {
        topicRepo.addTopic(Topic(
          id: 'topic-1',
          subjectId: 'sub_physics',
          title: 'Advanced',
          description: '',
          syllabusText: '',
        ));
        topicRepo.addTopic(Topic(
          id: 'topic-2',
          subjectId: 'sub_physics',
          title: 'Foundation',
          description: '',
          syllabusText: '',
        ));

        masteryRepo.addDependency(TopicDependency(
          topicId: 'topic-1',
          prerequisites: ['topic-2'],
          downstreamTopics: [],
        ));

        final result = await resolver.resolveSyllabus(
          subjectId: 'sub_physics',
          studentId: 'student-1',
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 2);
      });

      test('includes mastery state when studentId provided', () async {
        topicRepo.addTopic(Topic(
          id: 'topic-1',
          subjectId: 'sub_physics',
          title: 'Kinematics',
          description: '',
          syllabusText: '',
        ));

        masteryRepo.addMasteryState(
          MasteryState.initial(studentId: 'student-1', topicId: 'topic-1')
              .copyWith(accuracy: 0.9),
        );

        final result = await resolver.resolveSyllabus(
          subjectId: 'sub_physics',
          studentId: 'student-1',
        );

        expect(result.isSuccess, true);
        expect(result.data!.first.mastery, isNotNull);
        expect(result.data!.first.mastery!.accuracy, 0.9);
      });

      test('isReady is true when no dependencies exist', () async {
        topicRepo.addTopic(Topic(
          id: 'topic-1',
          subjectId: 'sub_physics',
          title: 'Kinematics',
          description: '',
          syllabusText: '',
        ));

        final result = await resolver.resolveSyllabus(subjectId: 'sub_physics');
        expect(result.isSuccess, true);
        expect(result.data!.first.isReady, true);
      });
    });

    group('getQuestionsForTopic', () {
      test('returns empty list when no questions exist', () async {
        final result = await resolver.getQuestionsForTopic('topic-1');
        expect(result.isSuccess, true);
        expect(result.data!, isEmpty);
      });

      test('returns questions for the given topic', () async {
        final now = DateTime.now();
        questionRepo.addQuestion(Question(
          id: 'q-1',
          subjectId: 'sub_physics',
          topicId: 'topic-1',
          type: QuestionType.multiChoice,
          text: 'Test question',
          createdAt: now,
          updatedAt: now,
        ));
        questionRepo.addQuestion(Question(
          id: 'q-2',
          subjectId: 'sub_physics',
          topicId: 'topic-2',
          type: QuestionType.multiChoice,
          text: 'Other question',
          createdAt: now,
          updatedAt: now,
        ));

        final result = await resolver.getQuestionsForTopic('topic-1');
        expect(result.isSuccess, true);
        expect(result.data!, hasLength(1));
        expect(result.data!.first.id, 'q-1');
      });
    });

    group('getQuestionsForTopics', () {
      test('returns empty map for empty input', () async {
        final result = await resolver.getQuestionsForTopics([]);
        expect(result.isSuccess, true);
        expect(result.data!, isEmpty);
      });

      test('returns questions grouped by topic', () async {
        final now = DateTime.now();
        questionRepo.addQuestion(Question(
          id: 'q-1',
          subjectId: 'sub_physics',
          topicId: 'topic-1',
          type: QuestionType.multiChoice,
          text: 'Q1',
          createdAt: now,
          updatedAt: now,
        ));
        questionRepo.addQuestion(Question(
          id: 'q-2',
          subjectId: 'sub_physics',
          topicId: 'topic-1',
          type: QuestionType.multiChoice,
          text: 'Q2',
          createdAt: now,
          updatedAt: now,
        ));
        questionRepo.addQuestion(Question(
          id: 'q-3',
          subjectId: 'sub_physics',
          topicId: 'topic-2',
          type: QuestionType.multiChoice,
          text: 'Q3',
          createdAt: now,
          updatedAt: now,
        ));

        final result = await resolver.getQuestionsForTopics(['topic-1', 'topic-2']);
        expect(result.isSuccess, true);
        expect(result.data!['topic-1'], hasLength(2));
        expect(result.data!['topic-2'], hasLength(1));
      });
    });

    group('buildLearningLevels', () {
      test('builds levels from nodes with prerequisites', () async {
        topicRepo.addTopic(Topic(
          id: 'topic-a', subjectId: 'sub', title: 'A', description: '',
          syllabusText: '',
        ));
        topicRepo.addTopic(Topic(
          id: 'topic-b', subjectId: 'sub', title: 'B', description: '',
          syllabusText: '',
        ));
        topicRepo.addTopic(Topic(
          id: 'topic-c', subjectId: 'sub', title: 'C', description: '',
          syllabusText: '',
        ));

        masteryRepo.addDependency(TopicDependency(
          topicId: 'topic-b',
          prerequisites: ['topic-a'],
          downstreamTopics: [],
        ));
        masteryRepo.addDependency(TopicDependency(
          topicId: 'topic-c',
          prerequisites: ['topic-b'],
          downstreamTopics: [],
        ));

        final result = await resolver.resolveSyllabus(
          subjectId: 'sub',
          studentId: 'student-1',
        );

        final levels = resolver.buildLearningLevels(result.data!);
        expect(levels, isNotEmpty);
      });
    });

    group('estimateWorkload', () {
      test('returns positive value for valid inputs', () {
        final workload = resolver.estimateWorkload(
          totalTopics: 30,
          targetDays: 180,
          hoursPerDay: 2,
        );
        expect(workload, greaterThan(0));
      });

      test('returns 0 when target days is 0', () {
        final workload = resolver.estimateWorkload(
          totalTopics: 30,
          targetDays: 0,
          hoursPerDay: 2,
        );
        expect(workload, 0);
      });

      test('returns 3.0 when workload is very light', () {
        final workload = resolver.estimateWorkload(
          totalTopics: 1,
          targetDays: 30,
          hoursPerDay: 8,
        );
        expect(workload, 3.0);
      });
    });
  });
}
