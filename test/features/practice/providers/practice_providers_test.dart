import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';

void main() {
  group('PracticeProviders', () {
    test('spacedRepetitionRepositoryProvider creates SpacedRepetitionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(spacedRepetitionRepositoryProvider),
        isA<SpacedRepetitionRepository>(),
      );
    });

    test('questionRepositoryProvider creates QuestionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(questionRepositoryProvider),
        isA<QuestionRepository>(),
      );
    });

    test('masteryGraphServiceProvider creates MasteryGraphService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(masteryGraphServiceProvider),
        isA<MasteryGraphService>(),
      );
    });

    test('sessionRepositoryProvider creates SessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(sessionRepositoryProvider),
        isA<SessionRepository>(),
      );
    });
  });
}
