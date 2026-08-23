import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/mentor/services/tools/get_syllabus_structure_tool.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import '../../../../helpers/fakes.dart';

class FakeSubjectRepo extends SubjectRepository {
  final Map<String, Subject> _subjects = {};

  void addSubject(Subject subject) => _subjects[subject.id] = subject;

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Subject subject) async {
    _subjects[subject.id] = subject;
    return Result.success(null);
  }

  @override
  Future<Result<Subject?>> get(String id) async =>
      Result.success(_subjects[id]);

  @override
  Future<Result<List<Subject>>> getAll() async =>
      Result.success(_subjects.values.toList());
}

class FakeTopicRepo extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Topic?>> get(String id) async =>
      Result.success(_topics[id]);

  @override
  Future<Result<List<Topic>>> getAll() async =>
      Result.success(_topics.values.toList());

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async =>
      Result.success(
        _topics.values.where((t) => t.subjectId == subjectId).toList(),
      );
}

class FakeDependencyRepo extends TopicDependencyRepository {
  final Map<String, TopicDependency> _deps = {};

  void addDependency(TopicDependency dep) => _deps[dep.topicId] = dep;

  @override
  Future<void> init() async {}

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    return Result.success(
      _deps[topicId] ?? TopicDependency(topicId: topicId),
    );
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async =>
      Result.success(_deps.values.toList());
}

class FakeMasteryForSyllabus extends MasteryGraphService {
  final Map<String, MasteryState> _masteryStates = {};

  FakeMasteryForSyllabus();

  void setMastery(String topicId, MasteryState state) =>
      _masteryStates[topicId] = state;

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(
      String studentId) async {
    return Result.success(
      _masteryStates.values.where((m) => m.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<MasteryState>> getTopicMastery(
      String studentId, String topicId) async {
    final state = _masteryStates[topicId];
    if (state != null) return Result.success(state);
    return Result.success(MasteryState.initial(
      studentId: studentId,
      topicId: topicId,
    ));
  }
}

MasteryState _mastery({
  required String topicId,
  double accuracy = 0.0,
  double readinessScore = 0.0,
  MasteryLevel level = MasteryLevel.novice,
  int totalAttempts = 0,
}) {
  return MasteryState(
    studentId: 'student-1',
    topicId: topicId,
    accuracy: accuracy,
    readinessScore: readinessScore,
    masteryLevel: level,
    totalAttempts: totalAttempts,
    lastAttempt: DateTime.now(),
    lastUpdated: DateTime.now(),
  );
}

Topic _topic({
  required String id,
  required String subjectId,
  String? title,
}) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: title ?? 'Topic $id',
    description: 'Description for $id',
    syllabusText: '',
  );
}

Subject _subject({required String id, required String name, List<String>? topicIds}) {
  return Subject(
    id: id,
    name: name,
    topicIds: topicIds ?? [],
    color: '#000000',
  );
}

void main() {
  group('GetSyllabusStructureTool', () {
    late FakeSubjectRepo subjectRepo;
    late FakeTopicRepo topicRepo;
    late FakeMasteryForSyllabus masteryService;
    late FakeDependencyRepo dependencyRepo;
    late FakeStudentIdService studentId;
    late GetSyllabusStructureTool tool;

    setUp(() {
      subjectRepo = FakeSubjectRepo();
      topicRepo = FakeTopicRepo();
      masteryService = FakeMasteryForSyllabus();
      dependencyRepo = FakeDependencyRepo();
      studentId = FakeStudentIdService()..setStudentId('student-1');
      tool = GetSyllabusStructureTool(
        subjectRepo: subjectRepo,
        topicRepo: topicRepo,
        masteryService: masteryService,
        dependencyRepo: dependencyRepo,
        studentIdService: studentId,
      );
    });

    test('name returns get_syllabus_structure', () {
      expect(tool.name, 'get_syllabus_structure');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['required'], []);
      final props = params['properties'] as Map;
      expect(props.containsKey('subjectId'), true);
      expect(props.containsKey('topicId'), true);
      expect(props.containsKey('includePrerequisites'), true);
      expect(props.containsKey('includeProgress'), true);
    });

    group('list all subjects', () {
      test('returns all subjects with topic counts', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1', 't2'],
        ));
        subjectRepo.addSubject(_subject(
          id: 'subj-2',
          name: 'Math',
          topicIds: ['t3'],
        ));

        final result = await tool.execute({});

        expect(result['subjectCount'], 2);
        final subjects = result['subjects'] as List;
        expect(subjects.length, 2);
        expect(subjects[0]['id'], 'subj-1');
        expect(subjects[0]['name'], 'Physics');
        expect(subjects[0]['topicCount'], 2);
        expect(subjects[1]['id'], 'subj-2');
        expect(subjects[1]['topicCount'], 1);
      });

      test('includes progress when includeProgress is true', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1', 't2'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        topicRepo.addTopic(_topic(id: 't2', subjectId: 'subj-1'));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1', readinessScore: 0.9, level: MasteryLevel.expert,
        ));
        masteryService.setMastery('t2', _mastery(
          topicId: 't2', readinessScore: 0.3, level: MasteryLevel.novice,
        ));

        final result = await tool.execute({
          'includeProgress': true,
        });

        final subjects = result['subjects'] as List;
        expect(subjects[0]['completedTopics'], 1);
        expect(subjects[0]['overallProgress'], 0.5);
      });

      test('excludes progress when includeProgress is false', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1'],
        ));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1', readinessScore: 0.9,
        ));

        final result = await tool.execute({
          'includeProgress': false,
        });

        final subjects = result['subjects'] as List;
        expect(subjects[0].containsKey('completedTopics'), false);
        expect(subjects[0].containsKey('overallProgress'), false);
      });

      test('returns empty list when no subjects exist', () async {
        final result = await tool.execute({});

        expect(result['subjectCount'], 0);
        expect(result['subjects'], []);
      });
    });

    group('get subject topic tree', () {
      test('returns topic tree for a subject', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1', 't2'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1', title: 'Kinematics'));
        topicRepo.addTopic(_topic(id: 't2', subjectId: 'subj-1', title: 'Dynamics'));

        final result = await tool.execute({
          'subjectId': 'subj-1',
        });

        expect(result['subjectId'], 'subj-1');
        expect(result['subjectName'], 'Physics');
        expect(result['topicCount'], 2);
        final topics = result['topics'] as List;
        expect(topics.length, 2);
        expect(topics[0]['id'], 't1');
        expect(topics[0]['name'], 'Kinematics');
      });

      test('returns error when subject not found', () async {
        final result = await tool.execute({
          'subjectId': 'nonexistent',
        });

        expect(result.containsKey('error'), true);
      });

      test('includes prerequisite info when includePrerequisites is true', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1', 't2'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        topicRepo.addTopic(_topic(id: 't2', subjectId: 'subj-1'));
        dependencyRepo.addDependency(TopicDependency(
          topicId: 't2',
          prerequisites: ['t1'],
          estimatedMinutes: 60,
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'includePrerequisites': true,
        });

        final topics = result['topics'] as List;
        final t2 = topics.firstWhere((t) => t['id'] == 't2');
        expect(t2['prerequisites'], ['t1']);
        expect(t2['estimatedMinutes'], 60);
        expect(t2['isReady'], false);
        expect(t2['blockedBy'], ['t1']);
      });

      test('topic isReady when prerequisites are completed', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1', 't2'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        topicRepo.addTopic(_topic(id: 't2', subjectId: 'subj-1'));
        dependencyRepo.addDependency(TopicDependency(
          topicId: 't2',
          prerequisites: ['t1'],
        ));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1', readinessScore: 0.9,
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'includePrerequisites': true,
          'includeProgress': true,
        });

        final topics = result['topics'] as List;
        final t2 = topics.firstWhere((t) => t['id'] == 't2');
        expect(t2['isReady'], true);
      });

      test('includes progress when includeProgress is true', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1',
          accuracy: 0.72,
          readinessScore: 0.8,
          level: MasteryLevel.developing,
          totalAttempts: 15,
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'includeProgress': true,
        });

        final topics = result['topics'] as List;
        expect(topics[0]['mastery'], 'developing');
        expect(topics[0]['accuracy'], 0.72);
        expect(topics[0]['readinessScore'], 0.8);
        expect(topics[0]['totalAttempts'], 15);
      });

      test('suggests next topic based on readiness', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1', 't2'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        topicRepo.addTopic(_topic(id: 't2', subjectId: 'subj-1'));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1', readinessScore: 0.9, level: MasteryLevel.expert,
        ));
        masteryService.setMastery('t2', _mastery(
          topicId: 't2', readinessScore: 0.3, level: MasteryLevel.novice,
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'includeProgress': true,
          'includePrerequisites': true,
        });

        expect(result['suggestedNextTopic'], 't2');
        expect(result.containsKey('explanation'), true);
        expect(result['explanation'], isA<String>());
        expect((result['explanation'] as String).isNotEmpty, true);
      });

      test('includes explanation when prerequisites are absent', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1', 't2'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        topicRepo.addTopic(_topic(id: 't2', subjectId: 'subj-1'));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'includeProgress': true,
          'includePrerequisites': true,
        });

        expect(result['suggestedNextTopic'], 't1');
        expect(result.containsKey('explanation'), true);
        expect((result['explanation'] as String).isNotEmpty, true);
      });

      test('omits suggestedNextTopic when all topics are mastered', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1', readinessScore: 0.9, level: MasteryLevel.expert,
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'includeProgress': true,
          'includePrerequisites': true,
        });

        expect(result.containsKey('suggestedNextTopic'), false);
        expect(result.containsKey('explanation'), false);
      });

      test('returns empty topics list when subject has no topics', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: [],
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
        });

        expect(result['topicCount'], 0);
        expect(result['topics'], []);
      });
    });

    group('get topic details', () {
      test('returns details for a specific topic', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1'],
        ));
        topicRepo.addTopic(_topic(
          id: 't1',
          subjectId: 'subj-1',
          title: 'Kinematics',
        ));
        dependencyRepo.addDependency(TopicDependency(
          topicId: 't1',
          prerequisites: [],
          downstreamTopics: ['t2'],
          estimatedMinutes: 90,
        ));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1',
          accuracy: 0.72,
          readinessScore: 0.8,
          level: MasteryLevel.developing,
          totalAttempts: 20,
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 't1',
        });

        expect(result['id'], 't1');
        expect(result['name'], 'Kinematics');
        expect(result['subjectId'], 'subj-1');
        expect(result['prerequisites'], []);
        expect(result['downstreamTopics'], ['t2']);
        expect(result['estimatedMinutes'], 90);
        expect(result['mastery'], 'developing');
        expect(result['accuracy'], 0.72);
      });

      test('returns error when topic not found', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'nonexistent',
        });

        expect(result.containsKey('error'), true);
      });

      test('skips progress when includeProgress is false', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        masteryService.setMastery('t1', _mastery(
          topicId: 't1', accuracy: 0.9,
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 't1',
          'includeProgress': false,
        });

        expect(result.containsKey('mastery'), false);
        expect(result.containsKey('accuracy'), false);
      });

      test('skips prerequisites when includePrerequisites is false', () async {
        subjectRepo.addSubject(_subject(
          id: 'subj-1',
          name: 'Physics',
          topicIds: ['t1'],
        ));
        topicRepo.addTopic(_topic(id: 't1', subjectId: 'subj-1'));
        dependencyRepo.addDependency(TopicDependency(
          topicId: 't1',
          prerequisites: ['t0'],
        ));

        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 't1',
          'includePrerequisites': false,
        });

        expect(result.containsKey('prerequisites'), false);
        expect(result.containsKey('downstreamTopics'), false);
      });
    });
  });
}
