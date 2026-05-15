import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';

void main() {
  group('PracticeProviders', () {
    group('provider resolution', () {
      test('spacedRepetitionRepositoryProvider creates SpacedRepetitionRepository',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(spacedRepetitionRepositoryProvider);
        expect(repo, isA<SpacedRepetitionRepository>());
      });

      test('questionRepositoryProvider creates QuestionRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(questionRepositoryProvider);
        expect(repo, isA<QuestionRepository>());
      });

      test('masteryGraphServiceProvider creates MasteryGraphService', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(masteryGraphServiceProvider);
        expect(service, isA<MasteryGraphService>());
      });

      test('studySessionRepositoryProvider creates StudySessionRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(studySessionRepositoryProvider);
        expect(repo, isA<StudySessionRepository>());
      });
    });

    group('override', () {
      test('can override spacedRepetitionRepositoryProvider', () {
        final override = SpacedRepetitionRepository();
        final container = ProviderContainer(
          overrides: [
            spacedRepetitionRepositoryProvider.overrideWithValue(override),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(spacedRepetitionRepositoryProvider),
          same(override),
        );
      });

      test('can override questionRepositoryProvider', () {
        final override = QuestionRepository();
        final container = ProviderContainer(
          overrides: [
            questionRepositoryProvider.overrideWithValue(override),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(questionRepositoryProvider), same(override));
      });

      test('can override masteryGraphServiceProvider', () {
        final override = MasteryGraphService();
        final container = ProviderContainer(
          overrides: [
            masteryGraphServiceProvider.overrideWithValue(override),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(masteryGraphServiceProvider), same(override));
      });

      test('can override studySessionRepositoryProvider', () {
        final override = StudySessionRepository();
        final container = ProviderContainer(
          overrides: [
            studySessionRepositoryProvider.overrideWithValue(override),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(studySessionRepositoryProvider), same(override));
      });
    });

    group('singleton behavior', () {
      final allProviders = <String, ProviderBase>{
        'spacedRepetitionRepositoryProvider':
            spacedRepetitionRepositoryProvider,
        'questionRepositoryProvider': questionRepositoryProvider,
        'masteryGraphServiceProvider': masteryGraphServiceProvider,
        'studySessionRepositoryProvider': studySessionRepositoryProvider,
      };

      for (final entry in allProviders.entries) {
        test('${entry.key} returns same instance on repeated reads', () {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final a = container.read(entry.value);
          final b = container.read(entry.value);
          expect(a, same(b));
        });

        test('${entry.key} returns different instances in different containers',
            () {
          final c1 = ProviderContainer();
          final c2 = ProviderContainer();
          addTearDown(c1.dispose);
          addTearDown(c2.dispose);

          expect(c1.read(entry.value), isNot(same(c2.read(entry.value))));
        });
      }
    });

    group('container isolation', () {
      test('overrides in one container do not affect another', () {
        final override = SpacedRepetitionRepository();
        final withOverride = ProviderContainer(
          overrides: [
            spacedRepetitionRepositoryProvider.overrideWithValue(override),
          ],
        );
        final withoutOverride = ProviderContainer();
        addTearDown(withOverride.dispose);
        addTearDown(withoutOverride.dispose);

        expect(
          withOverride.read(spacedRepetitionRepositoryProvider),
          same(override),
        );
        expect(
          withoutOverride.read(spacedRepetitionRepositoryProvider),
          isNot(same(override)),
        );
      });
    });

    group('lifecycle', () {
      test('disposed container throws on read', () {
        final container = ProviderContainer();
        container.dispose();

        expect(
          () => container.read(spacedRepetitionRepositoryProvider),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
