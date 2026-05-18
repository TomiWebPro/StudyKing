import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/prerequisite_check_service.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};
  bool shouldThrow = false;

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<Topic?>> get(String id) async {
    if (shouldThrow) throw Exception('Topic error');
    return Result.success(_topics[id]);
  }
}

class _FakeMasteryGraphRepository extends MasteryGraphRepository {
  Result<List<TopicDependency>>? dependenciesResult;
  Result<List<MasteryState>>? masteryStatesResult;
  bool failOnGenerate = false;

  _FakeMasteryGraphRepository()
      : super(
          masteryStateRepo: null,
          questionMasteryRepo: null,
          topicDependencyRepo: null,
          questionEvaluationRepo: null,
        );

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    if (failOnGenerate) return Result.failure('Error');
    return dependenciesResult ?? Result.success([]);
  }

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(
      String studentId) async {
    if (failOnGenerate) return Result.failure('Error');
    return masteryStatesResult ?? Result.success([]);
  }
}

Topic _topic(String id, String subjectId, String title) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: title,
    syllabusText: '',
    description: '',
  );
}

void main() {
  group('PrerequisiteCheckResult', () {
    test('creates result with isReady true', () {
      final result = const PrerequisiteCheckResult(isReady: true);
      expect(result.isReady, isTrue);
      expect(result.unmetPrerequisiteTopics, isEmpty);
    });

    test('creates result with isReady false and unmet topics', () {
      final topic = _topic('t1', 's1', 'Algebra');
      final result = PrerequisiteCheckResult(
        isReady: false,
        unmetPrerequisiteTopics: [topic],
      );
      expect(result.isReady, isFalse);
      expect(result.unmetPrerequisiteTopics, [topic]);
    });
  });

  group('PrerequisiteCheckService', () {
    late _FakeTopicRepository fakeTopicRepo;
    late _FakeMasteryGraphRepository fakeMasteryRepo;
    late PrerequisiteCheckService service;

    setUp(() {
      fakeTopicRepo = _FakeTopicRepository();
      fakeMasteryRepo = _FakeMasteryGraphRepository();
      service = PrerequisiteCheckService(
        topicRepository: fakeTopicRepo,
        masteryRepository: fakeMasteryRepo,
      );
    });

    test('returns isReady true when topic has no dependencies', () async {
      fakeTopicRepo.addTopic(_topic('t1', 's1', 'Intro'));

      final result = await service.checkPrerequisites(
        topicId: 't1',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isReady, isTrue);
    });

    test('returns isReady true when all prerequisites are mastered', () async {
      fakeTopicRepo.addTopic(_topic('advanced', 's1', 'Advanced Topic'));
      fakeTopicRepo.addTopic(_topic('basic', 's1', 'Basic Topic'));

      fakeMasteryRepo.dependenciesResult = Result.success([
        TopicDependency(
          topicId: 'advanced',
          prerequisites: ['basic'],
        ),
      ]);

      final now = DateTime.now();
      fakeMasteryRepo.masteryStatesResult = Result.success([
        MasteryState(
          studentId: 'student1',
          topicId: 'basic',
          masteryLevel: MasteryLevel.proficient,
          lastAttempt: now,
          lastUpdated: now,
        ),
      ]);

      final result = await service.checkPrerequisites(
        topicId: 'advanced',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isReady, isTrue);
    });

    test('returns isReady false when prerequisites are not mastered', () async {
      fakeTopicRepo.addTopic(_topic('advanced', 's1', 'Advanced Topic'));
      fakeTopicRepo.addTopic(_topic('basic', 's1', 'Basic Topic'));

      fakeMasteryRepo.dependenciesResult = Result.success([
        TopicDependency(
          topicId: 'advanced',
          prerequisites: ['basic'],
        ),
      ]);

      final now = DateTime.now();
      fakeMasteryRepo.masteryStatesResult = Result.success([
        MasteryState(
          studentId: 'student1',
          topicId: 'basic',
          masteryLevel: MasteryLevel.novice,
          lastAttempt: now,
          lastUpdated: now,
        ),
      ]);

      final result = await service.checkPrerequisites(
        topicId: 'advanced',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isReady, isFalse);
      expect(result.data!.unmetPrerequisiteTopics.length, 1);
      expect(result.data!.unmetPrerequisiteTopics.first.id, 'basic');
    });

    test('returns isReady true when topic result is failure', () async {
      fakeTopicRepo.shouldThrow = true;

      final result = await service.checkPrerequisites(
        topicId: 'nonexistent',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isReady, isTrue);
    });

    test('handles error from dependencies gracefully', () async {
      fakeTopicRepo.addTopic(_topic('t1', 's1', 'Topic'));
      fakeMasteryRepo.failOnGenerate = true;

      final result = await service.checkPrerequisites(
        topicId: 't1',
        studentId: 'student1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.isReady, isTrue);
    });
  });

  group('showPrerequisiteDialog', () {
    testWidgets('shows dialog with unmet topics', (tester) async {
      final topics = <Topic>[
        _topic('t1', 's1', 'Algebra'),
        _topic('t2', 's1', 'Geometry'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await PrerequisiteCheckService
                      .showPrerequisiteDialog(
                    context,
                    unmetTopics: topics,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Prerequisites Not Met'), findsOneWidget);
      expect(find.textContaining('Algebra'), findsOneWidget);
      expect(find.textContaining('Geometry'), findsOneWidget);
      expect(find.text('Continue Anyway'), findsOneWidget);
      expect(find.text('Practice Prerequisites'), findsOneWidget);
    });

    testWidgets('tapping Practice Prerequisites returns true', (tester) async {
      final topics = <Topic>[
        _topic('t1', 's1', 'Algebra'),
      ];

      bool? dialogResult;
      bool callbackCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await PrerequisiteCheckService
                      .showPrerequisiteDialog(
                    context,
                    unmetTopics: topics,
                    onPracticePrerequisites: () {
                      callbackCalled = true;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice Prerequisites'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(callbackCalled, isTrue);
    });

    testWidgets('tapping Continue Anyway returns false', (tester) async {
      final topics = <Topic>[
        _topic('t1', 's1', 'Algebra'),
      ];

      bool? dialogResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await PrerequisiteCheckService
                      .showPrerequisiteDialog(
                    context,
                    unmetTopics: topics,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Anyway'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });
  });
}
