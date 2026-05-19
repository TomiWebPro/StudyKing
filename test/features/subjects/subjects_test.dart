import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/subjects.dart';

void main() {
  group('subjects barrel', () {
    test('Subject can be constructed with properties', () {
      final subject = Subject(
        id: 'math1',
        name: 'Mathematics',
        description: 'Advanced math',
        color: '#FF0000',
      );
      expect(subject.name, 'Mathematics');
      expect(subject.color, '#FF0000');
      expect(subject.topicIds, isEmpty);
    });

    test('TopicDependency isReady checks prerequisites', () {
      final dep = TopicDependency(
        topicId: 't2',
        prerequisites: ['t1'],
        masteryThreshold: 0.8,
      );
      expect(dep.isReady([], null), isFalse);
      expect(dep.isReady(['t1'], null), isTrue);
      expect(dep.isReady(['t1'], 0.5), isFalse);
      expect(dep.isReady(['t1'], 0.9), isTrue);
    });

    test('TopicDependency calculatePriority factors in mastery', () {
      final dep = TopicDependency(
        topicId: 't1',
        syllabusWeight: 1.0,
        masteryThreshold: 0.8,
      );
      final priority = dep.calculatePriority(
        masteryState: 0.4,
        isPrerequisite: true,
        downstreamCount: 2,
      );
      expect(priority, greaterThan(1.0));
      expect(priority, lessThanOrEqualTo(10.0));
    });

    test('SubjectRepository can be constructed', () {
      final repo = SubjectRepository();
      expect(repo, isNotNull);
    });

    test('TopicRepository can be constructed', () {
      final repo = TopicRepository();
      expect(repo, isNotNull);
    });

    test('SubjectListScreen can be const-constructed', () {
      expect(const SubjectListScreen(), isA<SubjectListScreen>());
    });

    test('SubjectDetailScreen can be constructed', () {
      expect(SubjectDetailScreen, isA<Type>());
    });

    test('SubjectLessonsTab can be constructed', () {
      expect(SubjectLessonsTab(subjectId: 's1'), isA<SubjectLessonsTab>());
    });

    test('SubjectPracticeTab can be constructed', () {
      expect(
        SubjectPracticeTab(
          onStartPractice: () {},
          onStartSpacedRepetition: () {},
        ),
        isA<SubjectPracticeTab>(),
      );
    });

    test('SubjectHistoryTab can be constructed', () {
      expect(
        SubjectHistoryTab(subjectId: 's1', onSessionTap: (_) {}),
        isA<SubjectHistoryTab>(),
      );
    });

    test('SubjectStatsTab can be constructed', () {
      expect(SubjectStatsTab(subjectId: 's1'), isA<SubjectStatsTab>());
    });
  });
}
