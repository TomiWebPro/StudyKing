import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};
  bool throwOnGetBySubject = false;
  bool throwOnInit = false;

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<Result<void>> init() async {
    if (throwOnInit) throw Exception('init error');
    return Result.success(null);
  }

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async {
    if (throwOnGetBySubject) throw Exception('get by subject error');
    return Result.success(_topics.values.where((t) => t.subjectId == subjectId).toList());
  }

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(_topics[id]);
}

class _FakeMasteryRepository extends MasteryGraphRepository {
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

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions = [];
  bool throwOnInit = false;

  void addQuestion(Question q) => _questions.add(q);

  @override
  Future<void> init() async {
    if (throwOnInit) throw Exception('init error');
  }

  @override
  Future<Result<List<Question>>> getAll() async {
    return Result.success(_questions);
  }
}

class _FailingMasteryRepository extends _FakeMasteryRepository {
  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async =>
      Result.failure('Failed to get dependencies');
}

SyllabusTopicNode _weightedNode({
  required String id,
  List<String> prerequisiteTopicIds = const [],
  TopicDependency? dependency,
  double accuracy = 0.0,
}) {
  return SyllabusTopicNode(
    topic: Topic(
      id: id,
      subjectId: 'sub_physics',
      title: id,
      description: '',
      syllabusText: '',
    ),
    dependency: dependency,
    mastery: MasteryState.initial(studentId: 'student-1', topicId: id)
        .copyWith(accuracy: accuracy),
    prerequisiteTopicIds: prerequisiteTopicIds,
  );
}

TopicDependency _dependency(
  String topicId, {
  double syllabusWeight = 1.0,
  int estimatedMinutes = 45,
  int estimatedQuestions = 0,
}) {
  return TopicDependency(
    topicId: topicId,
    syllabusWeight: syllabusWeight,
    estimatedMinutes: estimatedMinutes,
    estimatedQuestions: estimatedQuestions,
  );
}

void main() {
  group('SyllabusResolver', () {
    late _FakeTopicRepository topicRepo;
    late _FakeMasteryRepository masteryRepo;
    late _FakeQuestionRepository questionRepo;
    late SyllabusResolver resolver;

    setUp(() {
      topicRepo = _FakeTopicRepository();
      masteryRepo = _FakeMasteryRepository();
      questionRepo = _FakeQuestionRepository();
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

      test('returns topics in dependency-ordered output', () async {
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
        final ids = result.data!.map((n) => n.topic.id).toList();
        // The prerequisite (topic-2) must precede the dependent (topic-1).
        expect(ids.indexOf('topic-2'), lessThan(ids.indexOf('topic-1')));
      });

      test('detects cyclic dependencies and returns failure', () async {
        topicRepo.addTopic(Topic(
          id: 'topic-a',
          subjectId: 'sub_physics',
          title: 'A',
          description: '',
          syllabusText: '',
        ));
        topicRepo.addTopic(Topic(
          id: 'topic-b',
          subjectId: 'sub_physics',
          title: 'B',
          description: '',
          syllabusText: '',
        ));

        masteryRepo.addDependency(TopicDependency(
          topicId: 'topic-a',
          prerequisites: ['topic-b'],
          downstreamTopics: [],
        ));
        masteryRepo.addDependency(TopicDependency(
          topicId: 'topic-b',
          prerequisites: ['topic-a'],
          downstreamTopics: [],
        ));

        final result = await resolver.resolveSyllabus(
          subjectId: 'sub_physics',
          studentId: 'student-1',
        );

        expect(result.isFailure, true);
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

      test('falls back to the flat 45-minute estimate without topic data',
          () {
        // 2 topics * 45 min = 90 needed; 1 day * 1 hour = 60 available.
        final workload = resolver.estimateWorkload(
          totalTopics: 2,
          targetDays: 1,
          hoursPerDay: 1,
        );
        expect(workload, closeTo(60 / 90, 1e-9));
      });
    });

    group('estimateWorkload weighted estimation', () {
      test('hard syllabus estimates a lower ratio than an easy one '
          'with the same topic count', () {
        const targetDays = 10;
        const hoursPerDay = 2;
        const available = targetDays * hoursPerDay * 60.0; // 1200 min

        final easyTopics = List.generate(
          10,
          (i) => _weightedNode(id: 'easy-$i'),
        );
        final easy = resolver.estimateWorkload(
          totalTopics: 10,
          targetDays: targetDays,
          hoursPerDay: hoursPerDay,
          topics: easyTopics,
        );
        // 10 plain topics * 45 min = 450 needed -> 1200/450.
        expect(easy, closeTo(available / 450, 1e-9));

        final hardTopics = List.generate(
          10,
          (i) => _weightedNode(
            id: 'hard-$i',
            dependency: _dependency(
              'hard-$i',
              syllabusWeight: 2.0,
              estimatedMinutes: 60,
              estimatedQuestions: 20,
            ),
          ),
        );
        final hard = resolver.estimateWorkload(
          totalTopics: 10,
          targetDays: targetDays,
          hoursPerDay: hoursPerDay,
          topics: hardTopics,
        );
        // Per hard topic: 60 min * 2.0 (weight) * 1.5 (20 questions)
        // = 180 min -> 1800 needed -> 1200/1800.
        expect(hard, closeTo(available / 1800, 1e-9));
        expect(hard, lessThan(easy));
      });

      test('high mastery lowers the estimated minutes per topic', () {
        final fresh = resolver.estimateWorkload(
          totalTopics: 1,
          targetDays: 1,
          hoursPerDay: 2,
          topics: [
            _weightedNode(
              id: 't1',
              dependency: _dependency('t1'),
              accuracy: 0.0,
            ),
          ],
        );
        // 45 min needed vs 120 available -> 120/45.
        expect(fresh, closeTo(120 / 45, 1e-9));

        final mastered = resolver.estimateWorkload(
          totalTopics: 1,
          targetDays: 1,
          hoursPerDay: 2,
          topics: [
            _weightedNode(
              id: 't1',
              dependency: _dependency('t1'),
              accuracy: 1.0,
            ),
          ],
        );
        // Mastery factor 0.25 -> 11.25 min needed -> 120/11.25 > 3,
        // clamped to the maximum.
        expect(mastered, 3.0);
        expect(mastered, greaterThan(fresh));
      });

      test('deeper prerequisite chains increase the estimate', () {
        // Chain: c depends on b depends on a (depths 0, 1, 2).
        final chain = [
          _weightedNode(id: 'a', dependency: _dependency('a')),
          _weightedNode(
            id: 'b',
            prerequisiteTopicIds: ['a'],
            dependency: _dependency('b'),
          ),
          _weightedNode(
            id: 'c',
            prerequisiteTopicIds: ['b'],
            dependency: _dependency('c'),
          ),
        ];
        final chainRatio = resolver.estimateWorkload(
          totalTopics: 3,
          targetDays: 3,
          hoursPerDay: 2,
          topics: chain,
        );
        // Minutes: 45 + 45*1.1 + 45*1.2 = 148.5 -> 360/148.5.
        expect(chainRatio, closeTo(360 / 148.5, 1e-9));

        final flat = resolver.estimateWorkload(
          totalTopics: 3,
          targetDays: 3,
          hoursPerDay: 2,
          topics: [
            _weightedNode(id: 'a', dependency: _dependency('a')),
            _weightedNode(id: 'b', dependency: _dependency('b')),
            _weightedNode(id: 'c', dependency: _dependency('c')),
          ],
        );
        // No depth: 3 * 45 = 135 -> 360/135.
        expect(flat, closeTo(360 / 135, 1e-9));
        expect(chainRatio, lessThan(flat));
      });

      test('question counts raise the estimate, capped at the ceiling',
          () {
        final noQuestions = resolver.estimateWorkload(
          totalTopics: 1,
          targetDays: 1,
          hoursPerDay: 2,
          topics: [
            _weightedNode(id: 't1', dependency: _dependency('t1')),
          ],
        );
        expect(noQuestions, closeTo(120 / 45, 1e-9));

        // Explicit counts take precedence over the dependency default.
        final withCounts = resolver.estimateWorkload(
          totalTopics: 1,
          targetDays: 1,
          hoursPerDay: 2,
          questionCounts: {'t1': 40},
          topics: [
            _weightedNode(id: 't1', dependency: _dependency('t1')),
          ],
        );
        // 45 min * 2.0 (40 questions) = 90 needed -> 120/90.
        expect(withCounts, closeTo(120 / 90, 1e-9));

        // Counts above the cap behave like the cap itself.
        final capped = resolver.estimateWorkload(
          totalTopics: 1,
          targetDays: 1,
          hoursPerDay: 2,
          questionCounts: {'t1': 4000},
          topics: [
            _weightedNode(id: 't1', dependency: _dependency('t1')),
          ],
        );
        expect(capped, closeTo(120 / 90, 1e-9));

        // Dependency-declared question estimates are used as fallback.
        final withDeclared = resolver.estimateWorkload(
          totalTopics: 1,
          targetDays: 1,
          hoursPerDay: 2,
          topics: [
            _weightedNode(
              id: 't1',
              dependency: _dependency('t1', estimatedQuestions: 40),
            ),
          ],
        );
        expect(withDeclared, closeTo(120 / 90, 1e-9));
      });

      test('terminates on cyclic prerequisite lists', () {
        final cyclic = [
          _weightedNode(
            id: 'a',
            prerequisiteTopicIds: ['b'],
            dependency: _dependency('a'),
          ),
          _weightedNode(
            id: 'b',
            prerequisiteTopicIds: ['a'],
            dependency: _dependency('b'),
          ),
        ];
        // Cycle guard: b resolves depth 1, a resolves depth 2.
        // Minutes: 45*1.2 + 45*1.1 = 103.5 -> 120/103.5.
        final workload = resolver.estimateWorkload(
          totalTopics: 2,
          targetDays: 1,
          hoursPerDay: 2,
          topics: cyclic,
        );
        expect(workload, closeTo(120 / 103.5, 1e-9));
      });

      test('weighted estimate matches the flat path for unweighted topics',
          () {
        final flat = resolver.estimateWorkload(
          totalTopics: 4,
          targetDays: 7,
          hoursPerDay: 3,
        );
        final weighted = resolver.estimateWorkload(
          totalTopics: 4,
          targetDays: 7,
          hoursPerDay: 3,
          topics: List.generate(4, (i) => _weightedNode(id: 't$i')),
        );
        // 4 plain nodes average to the same 45 min/topic.
        expect(weighted, closeTo(flat, 1e-9));
      });
    });

    group('resolveSyllabus error cases', () {
      test('catches generic exception and returns failure', () async {
        topicRepo.throwOnGetBySubject = true;
        final result = await resolver.resolveSyllabus(subjectId: 'sub_physics');
        expect(result.isFailure, true);
      });

      test('rethrows SyllabusException', () async {
        final throwingResolver = SyllabusResolver(
          topicRepository: _FakeTopicRepository()..throwOnGetBySubject = true,
          masteryRepository: masteryRepo,
          questionRepository: questionRepo,
        );
        final result = await throwingResolver.resolveSyllabus(subjectId: 'sub_physics');
        expect(result.isFailure, true);
      });
    });

    group('getQuestionsForTopic edge cases', () {
      test('returns failure when questionRepo init throws', () async {
        questionRepo.throwOnInit = true;
        final result = await resolver.getQuestionsForTopic('topic-1');
        expect(result.isFailure, true);
      });
    });

    group('getQuestionsForTopics edge cases', () {
      test('returns failure when questionRepo init throws', () async {
        questionRepo.throwOnInit = true;
        final result = await resolver.getQuestionsForTopics(['topic-1']);
        expect(result.isFailure, true);
      });
    });

    group('buildLearningLevels edge cases', () {
      test('builds simple flat structure with no dependencies', () async {
        topicRepo.addTopic(Topic(
          id: 'topic-a', subjectId: 'sub', title: 'A', description: '',
          syllabusText: '',
        ));
        topicRepo.addTopic(Topic(
          id: 'topic-b', subjectId: 'sub', title: 'B', description: '',
          syllabusText: '',
        ));

        final result = await resolver.resolveSyllabus(
          subjectId: 'sub',
          studentId: 'student-1',
        );
        final levels = resolver.buildLearningLevels(result.data!);
        expect(levels, hasLength(1));
        expect(levels.first, containsAll(['topic-a', 'topic-b']));
      });

      test('returns empty list when no level can be formed', () {
        final nodeA = SyllabusTopicNode(
          topic: Topic(id: 'topic-a', subjectId: 'sub', title: 'A', description: '', syllabusText: ''),
          prerequisiteTopicIds: ['topic-b'],
        );
        final nodeB = SyllabusTopicNode(
          topic: Topic(id: 'topic-b', subjectId: 'sub', title: 'B', description: '', syllabusText: ''),
          prerequisiteTopicIds: ['topic-a'],
        );
        final levels = resolver.buildLearningLevels([nodeA, nodeB]);
        expect(levels, isEmpty);
      });
    });

    group('resolveSyllabus with empty dep results', () {
      test('handles failed dependency fetching gracefully', () async {
        topicRepo.addTopic(Topic(
          id: 'topic-1', subjectId: 'sub_phys', title: 'T1', description: '',
          syllabusText: '',
        ));
        final failingMasteryRepo = _FailingMasteryRepository();
        final res = SyllabusResolver(
          topicRepository: topicRepo,
          masteryRepository: failingMasteryRepo,
          questionRepository: questionRepo,
        );
        final result = await res.resolveSyllabus(subjectId: 'sub_phys');
        expect(result.isSuccess, isTrue);
        expect(result.data!.first.isReady, isTrue);
      });
    });

    group('resolveSyllabus priority with dependencies', () {
      test('calculates priority with dependency', () async {
        topicRepo.addTopic(Topic(
          id: 't1', subjectId: 'sub', title: 'T1', description: '',
          syllabusText: '',
        ));
        masteryRepo.addDependency(TopicDependency(
          topicId: 't1',
          prerequisites: [],
          downstreamTopics: ['t2'],
          syllabusWeight: 1.0,
        ));
        masteryRepo.addMasteryState(
          MasteryState.initial(studentId: 's1', topicId: 't1')
              .copyWith(accuracy: 0.5),
        );
        final result = await resolver.resolveSyllabus(
          subjectId: 'sub', studentId: 's1',
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!.first.priority, greaterThan(0.0));
      });
    });

    group('topological sort with multi-level deps', () {
      test('sorts three levels correctly', () async {
        topicRepo.addTopic(Topic(
          id: 'level3', subjectId: 'sub', title: 'L3', description: '',
          syllabusText: '',
        ));
        topicRepo.addTopic(Topic(
          id: 'level2', subjectId: 'sub', title: 'L2', description: '',
          syllabusText: '',
        ));
        topicRepo.addTopic(Topic(
          id: 'level1', subjectId: 'sub', title: 'L1', description: '',
          syllabusText: '',
        ));
        masteryRepo.addDependency(TopicDependency(
          topicId: 'level2', prerequisites: ['level1'], downstreamTopics: ['level3'],
        ));
        masteryRepo.addDependency(TopicDependency(
          topicId: 'level3', prerequisites: ['level2'], downstreamTopics: [],
        ));
        final result = await resolver.resolveSyllabus(
          subjectId: 'sub', studentId: 's1',
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!, hasLength(3));
      });
    });

    group('additional edge cases', () {
      test('resolveSyllabus catches topicRepository init failure', () async {
        final throwingTopicRepo = _FakeTopicRepository();
        throwingTopicRepo.throwOnInit = true;
        final res = SyllabusResolver(
          topicRepository: throwingTopicRepo,
          masteryRepository: masteryRepo,
          questionRepository: questionRepo,
        );
        final result = await res.resolveSyllabus(subjectId: 'sub_physics');
        expect(result.isFailure, isTrue);
      });

      test('getQuestionsForTopics returns failure when init throws', () async {
        questionRepo.throwOnInit = true;
        final result = await resolver.getQuestionsForTopics(['topic-1']);
        expect(result.isFailure, isTrue);
      });

      test('buildLearningLevels returns empty when all ids already visited', () {
        final node = SyllabusTopicNode(
          topic: Topic(id: 'only', subjectId: 'sub', title: 'Only', description: '', syllabusText: ''),
        );
        final levels = resolver.buildLearningLevels([node]);
        expect(levels, hasLength(1));
      });

      test('estimateWorkload returns max with zero topics', () {
        final workload = resolver.estimateWorkload(totalTopics: 0, targetDays: 10, hoursPerDay: 2);
        expect(workload, equals(3.0));
      });

      test('resolveSyllabus handles empty topic list from repo', () async {
        final emptyRepo = _FakeTopicRepository();
        final res = SyllabusResolver(
          topicRepository: emptyRepo,
          masteryRepository: masteryRepo,
          questionRepository: questionRepo,
        );
        final result = await res.resolveSyllabus(subjectId: 'nonexistent');
        expect(result.isFailure, isTrue);
      });
    });
  });
}
