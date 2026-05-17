import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/subjects.dart';

void main() {
  group('subjects barrel', () {
    test('exports TopicDependency', () {
      expect(TopicDependency, isA<Type>());
    });

    test('exports Subject', () {
      expect(Subject, isA<Type>());
    });

    test('exports SubjectRepository', () {
      expect(SubjectRepository, isA<Type>());
    });

    test('exports TopicRepository', () {
      expect(TopicRepository, isA<Type>());
    });

    test('exports SubjectListScreen', () {
      expect(SubjectListScreen, isA<Type>());
    });

    test('exports SubjectDetailScreen', () {
      expect(SubjectDetailScreen, isA<Type>());
    });

    test('exports SubjectLessonsTab', () {
      expect(SubjectLessonsTab, isA<Type>());
    });

    test('exports SubjectPracticeTab', () {
      expect(SubjectPracticeTab, isA<Type>());
    });

    test('exports SubjectHistoryTab', () {
      expect(SubjectHistoryTab, isA<Type>());
    });

    test('exports SubjectStatsTab', () {
      expect(SubjectStatsTab, isA<Type>());
    });
  });
}
