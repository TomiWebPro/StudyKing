import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/services/lesson_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

void main() {
  group('lessonRepositoryProvider', () {
    test('creates a LessonRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(lessonRepositoryProvider);
      expect(repo, isA<LessonRepository>());
    });

    test('returns the same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo1 = container.read(lessonRepositoryProvider);
      final repo2 = container.read(lessonRepositoryProvider);
      expect(repo1, same(repo2));
    });

    test('can be overridden with custom repository', () {
      final fakeRepo = LessonRepository();
      final container = ProviderContainer(
        overrides: [
          lessonRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(lessonRepositoryProvider), same(fakeRepo));
    });

    test('resolves without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(lessonRepositoryProvider),
        returnsNormally,
      );
    });
  });

  group('tutorSessionRepositoryProvider', () {
    test('creates a TutorSessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(tutorSessionRepositoryProvider);
      expect(repo, isA<TutorSessionRepository>());
    });

    test('can be overridden with custom repository', () {
      final fakeRepo = TutorSessionRepository();
      final container = ProviderContainer(
        overrides: [
          tutorSessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(tutorSessionRepositoryProvider), same(fakeRepo));
    });
  });

  group('lessonServiceProvider', () {
    test('creates a LessonService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(lessonServiceProvider);
      expect(service, isA<LessonService>());
    });

    test('is wired to lessonRepositoryProvider', () {
      final fakeRepo = LessonRepository();
      final container = ProviderContainer(
        overrides: [
          lessonRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(lessonServiceProvider);
      expect(service, isA<LessonService>());
    });

    test('is wired to tutorSessionRepositoryProvider', () {
      final fakeRepo = TutorSessionRepository();
      final container = ProviderContainer(
        overrides: [
          tutorSessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(lessonServiceProvider);
      expect(service, isA<LessonService>());
    });

    test('is wired to sessionRepositoryProvider', () {
      final fakeRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(lessonServiceProvider);
      expect(service, isA<LessonService>());
    });
  });
}
