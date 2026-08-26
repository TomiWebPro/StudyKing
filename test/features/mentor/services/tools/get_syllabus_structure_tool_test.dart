import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/mentor/services/tools/get_syllabus_structure_tool.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'test_helpers.dart';

void main() {
  group('GetSyllabusStructureTool', () {
    late FakeStudentIdService studentIdService;
    late FakeSubjectRepository subjectRepo;
    late FakeTopicRepository topicRepo;
    late FakeMasteryGraphService mastery;
    late FakeTopicDependencyRepository dependencyRepo;

    setUp(() {
      studentIdService = FakeStudentIdService('student-1');
      mastery = FakeMasteryGraphService();
    });

    test('lists all subjects with topic counts and progress', () async {
      final subject = Subject(
        id: 's1',
        name: 'Math',
        topicIds: ['t1', 't2'],
      );
      final t1 = MasteryState.initial(studentId: 'student-1', topicId: 't1')
          .copyWith(readinessScore: 0.9);
      final t2 = MasteryState.initial(studentId: 'student-1', topicId: 't2')
          .copyWith(readinessScore: 0.5);
      mastery.allMastery = [t1, t2];
      subjectRepo = FakeSubjectRepository([subject]);
      topicRepo = FakeTopicRepository();
      dependencyRepo = FakeTopicDependencyRepository();

      final tool = GetSyllabusStructureTool(
        subjectRepo: subjectRepo,
        topicRepo: topicRepo,
        masteryService: mastery,
        dependencyRepo: dependencyRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      expect(result['subjectCount'], equals(1));
      final subjects = result['subjects'] as List;
      final first = subjects.first as Map<String, dynamic>;
      expect(first['id'], equals('s1'));
      expect(first['name'], equals('Math'));
      expect(first['topicCount'], equals(2));
      expect(first['completedTopics'], equals(1));
      expect(first['overallProgress'], equals(0.5));
    });

    test('returns topic details with mastery and prerequisites', () async {
      final subject = Subject(id: 's1', name: 'Math', topicIds: ['t1', 't2']);
      final topic = Topic(
        id: 't1',
        subjectId: 's1',
        title: 'Algebra',
        description: 'Desc',
        syllabusText: '',
      );
      final t1Mastery = MasteryState.initial(studentId: 'student-1', topicId: 't1')
          .copyWith(
        accuracy: 0.7,
        readinessScore: 0.9,
        reviewUrgency: 0.3,
        totalAttempts: 5,
        masteryLevel: MasteryLevel.proficient,
      );
      final t2 = MasteryState.initial(studentId: 'student-1', topicId: 't2')
          .copyWith(readinessScore: 0.5);
      mastery.allMastery = [t1Mastery, t2];
      mastery.topicMastery = t1Mastery;

      subjectRepo = FakeSubjectRepository([subject]);
      topicRepo = FakeTopicRepository([topic]);
      dependencyRepo = FakeTopicDependencyRepository(
        const [],
        TopicDependency(
          topicId: 't1',
          prerequisites: ['t0'],
          estimatedMinutes: 30,
        ),
      );

      final tool = GetSyllabusStructureTool(
        subjectRepo: subjectRepo,
        topicRepo: topicRepo,
        masteryService: mastery,
        dependencyRepo: dependencyRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({
        'subjectId': 's1',
        'topicId': 't1',
      });

      expect(result['id'], equals('t1'));
      expect(result['name'], equals('Algebra'));
      expect(result['description'], equals('Desc'));
      expect(result['mastery'], equals('proficient'));
      expect(result['accuracy'], equals(0.7));
      expect(result['readinessScore'], equals(0.9));
      expect(result['prerequisites'], equals(['t0']));
      expect(result['isReady'], isFalse);
      expect(result['blockedBy'], equals(['t0']));
    });

    test('degrades gracefully when there are no subjects', () async {
      subjectRepo = FakeSubjectRepository();
      topicRepo = FakeTopicRepository();
      dependencyRepo = FakeTopicDependencyRepository();

      final tool = GetSyllabusStructureTool(
        subjectRepo: subjectRepo,
        topicRepo: topicRepo,
        masteryService: mastery,
        dependencyRepo: dependencyRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});
      expect(result['subjectCount'], equals(0));
      expect(result['subjects'], equals([]));
    });

    test('returns an error entry for an unknown subject', () async {
      subjectRepo = FakeSubjectRepository();
      topicRepo = FakeTopicRepository();
      dependencyRepo = FakeTopicDependencyRepository();

      final tool = GetSyllabusStructureTool(
        subjectRepo: subjectRepo,
        topicRepo: topicRepo,
        masteryService: mastery,
        dependencyRepo: dependencyRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'subjectId': 'missing'});
      expect(result['error'], contains('Subject not found'));
    });
  });
}
