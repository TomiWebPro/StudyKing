import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/topic_readiness_service.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';

class _FakeReadinessTopicRepository extends TopicRepository {
  final List<Topic> _topics = [];
  bool shouldThrow = false;

  void addTopic(Topic topic) => _topics.add(topic);

  @override
  Future<Result<void>> init() async {
    if (shouldThrow) throw Exception('Init failed');
    return Result.success(null);
  }

  @override
  Future<Result<Topic?>> get(String id) async =>
      Result.success(_topics.cast<Topic?>().firstWhere((t) => t?.id == id, orElse: () => null));

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(_topics);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async {
    return Result.success(_topics.where((t) => t.subjectId == subjectId).toList());
  }
}

class _FakeReadinessMasteryRepo extends MasteryGraphRepository {
  final List<MasteryState> _states = [];
  final List<TopicDependency> _deps = [];
  bool failOnStates = false;

  void addState(MasteryState state) => _states.add(state);
  void addDependency(TopicDependency dep) => _deps.add(dep);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    if (failOnStates) return Result.failure('Failed');
    return Result.success(_states.where((s) => s.studentId == studentId).toList());
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success(List.from(_deps));
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final state = _states.where((s) => s.studentId == studentId && s.topicId == topicId).firstOrNull;
    if (state != null) return Result.success(state);
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }
}

void main() {
  late _FakeReadinessTopicRepository topicRepo;
  late _FakeReadinessMasteryRepo masteryRepo;
  late TopicReadinessService service;

  setUp(() {
    topicRepo = _FakeReadinessTopicRepository();
    masteryRepo = _FakeReadinessMasteryRepo();
    service = TopicReadinessService(
      topicRepository: topicRepo,
      masteryRepository: masteryRepo,
    );
  });

  group('TopicReadinessService', () {
    test('getReadyTopics returns empty list when no topics exist', () async {
      final result = await service.getReadyTopics(
        subjectId: 'subj1',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('getReadyTopics returns topics sorted by priority', () async {
      topicRepo.addTopic(Topic(id: 't1', subjectId: 'subj1', title: 'Topic A', description: 'Desc A', syllabusText: 'Syll A'));
      topicRepo.addTopic(Topic(id: 't2', subjectId: 'subj1', title: 'Topic B', description: 'Desc B', syllabusText: 'Syll B'));

      final result = await service.getReadyTopics(
        subjectId: 'subj1',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
    });

    test('getReadyTopics handles prerequisite requirements', () async {
      topicRepo.addTopic(Topic(id: 't1', subjectId: 'subj1', title: 'Basic', description: 'Desc', syllabusText: 'Syll'));
      topicRepo.addTopic(Topic(id: 't2', subjectId: 'subj1', title: 'Advanced', description: 'Desc', syllabusText: 'Syll'));
      masteryRepo.addDependency(TopicDependency(
        topicId: 't2',
        prerequisites: ['t1'],
        downstreamTopics: [],
      ));

      final result = await service.getReadyTopics(
        subjectId: 'subj1',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      final advanced = result.data!.firstWhere((r) => r.topicId == 't2');
      expect(advanced.unmetPrerequisites, contains('t1'));
      expect(advanced.isReady, isFalse);
    });

    test('getNextRecommendedTopics returns only ready topics', () async {
      topicRepo.addTopic(Topic(id: 't1', subjectId: 'subj1', title: 'Ready Topic', description: 'Desc', syllabusText: 'Syll'));
      topicRepo.addTopic(Topic(id: 't2', subjectId: 'subj1', title: 'Not Ready', description: 'Desc', syllabusText: 'Syll'));
      masteryRepo.addDependency(TopicDependency(
        topicId: 't2',
        prerequisites: ['t1'],
        downstreamTopics: [],
      ));

      final result = await service.getNextRecommendedTopics(
        subjectId: 'subj1',
        studentId: 'student1',
        maxCount: 3,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.every((r) => r.isReady), isTrue);
    });

    test('getReadyTopics returns failure when repository throws', () async {
      topicRepo.shouldThrow = true;

      final result = await service.getReadyTopics(
        subjectId: 'subj1',
        studentId: 'student1',
      );

      expect(result.isFailure, isTrue);
    });

    test('getNextRecommendedTopics returns failure when getReadyTopics fails', () async {
      topicRepo.shouldThrow = true;

      final result = await service.getNextRecommendedTopics(
        subjectId: 'subj1',
        studentId: 'student1',
      );

      expect(result.isFailure, isTrue);
    });
  });
}
