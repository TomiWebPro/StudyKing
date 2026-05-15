import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';

void main() {
  group('topicRepositoryProvider', () {
    test('creates a TopicRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(topicRepositoryProvider);
      expect(repo, isA<TopicRepository>());
    });

    test('returns the same instance on repeated reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo1 = container.read(topicRepositoryProvider);
      final repo2 = container.read(topicRepositoryProvider);
      expect(identical(repo1, repo2), isTrue);
    });
  });
}
