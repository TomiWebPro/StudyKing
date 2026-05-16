import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/data.dart';

void main() {
  group('data.dart barrel exports', () {
    test('exports enums', () {
      expect(QuestionType.values.isNotEmpty, isTrue);
      expect(SourceType.values.isNotEmpty, isTrue);
      expect(LessonBlockType.values.isNotEmpty, isTrue);
      expect(GeneratedBy.values.isNotEmpty, isTrue);
      expect(ProcessingStatus.values.isNotEmpty, isTrue);
    });

    test('exports HiveBoxNames', () {
      expect(HiveBoxNames.answers, 'answers');
      expect(HiveBoxNames.topics, 'topics');
    });

    test('exports DatabaseService as type', () {
      expect(DatabaseService, isA<Type>());
    });

    test('exports HiveInitializer', () {
      expect(HiveInitializer, isA<Type>());
    });

    test('exports Repository', () {
      expect(Repository, isA<Type>());
    });

    test('exports models', () {
      expect(Topic, isA<Type>());
      expect(Question, isA<Type>());
      expect(Session, isA<Type>());
      expect(Subject, isA<Type>());
    });
  });
}
