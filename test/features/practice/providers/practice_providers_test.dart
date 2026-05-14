import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';

void main() {
  group('PracticeProviders', () {
    test('spacedRepetitionRepositoryProvider creates SpacedRepetitionRepository', () {
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
}
