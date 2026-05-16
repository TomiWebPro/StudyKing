import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/services/lesson_service.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

void main() {
  group('lessonRepositoryProvider', () {
    test('creates a LessonRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(lessonRepositoryProvider);
      expect(repo, isA<LessonRepository>());
    });
  });

  group('tutorSessionRepositoryProvider', () {
    test('creates a TutorSessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(tutorSessionRepositoryProvider);
      expect(repo, isA<TutorSessionRepository>());
    });
  });

  group('lessonServiceProvider', () {
    test('creates a LessonService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(lessonServiceProvider);
      expect(service, isA<LessonService>());
    });
  });
}
