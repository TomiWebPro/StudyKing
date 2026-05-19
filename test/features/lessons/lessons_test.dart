import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/lessons/lessons.dart';

void main() {
  group('lessons barrel', () {
    test('exports LessonRepository', () => expect(LessonRepository, isNotNull));
    test('exports TopicListScreen', () => expect(TopicListScreen, isNotNull));
    test('exports LessonListScreen', () => expect(LessonListScreen, isNotNull));
    test('exports LessonDetailScreen', () => expect(LessonDetailScreen, isNotNull));
    test('exports SessionQueryService', () => expect(SessionQueryService, isNotNull));
    test('exports lessonServiceProvider', () => expect(lessonServiceProvider, isNotNull));
    test('exports LessonListItem', () => expect(LessonListItem, isNotNull));

    test('lessonServiceProvider is a Provider<SessionQueryService>', () {
      expect(lessonServiceProvider, isA<Provider<SessionQueryService>>());
    });

    test('SessionQueryService is a class type', () {
      expect(SessionQueryService, isA<Type>());
    });
  });
}
