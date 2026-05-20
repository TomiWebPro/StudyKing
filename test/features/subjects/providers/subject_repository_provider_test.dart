import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class FakeSubjectRepository extends SubjectRepository {
  @override
  Future<void> init() async {}
}

void main() {
  group('subjectRepositoryProvider', () {
    test('provides a SubjectRepository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(subjectRepositoryProvider);
      expect(repo, isA<SubjectRepository>());
    });

    test('singleton behavior - same instance across reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(subjectRepositoryProvider);
      final b = container.read(subjectRepositoryProvider);
      expect(identical(a, b), isTrue);
    });

    test('can be overridden via ProviderScope', () {
      final fake = FakeSubjectRepository();
      final container = ProviderContainer(overrides: [
        subjectRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(subjectRepositoryProvider);
      expect(repo, same(fake));
    });

    test('constructs without throwing', () {
      expect(() => SubjectRepository(), returnsNormally);
    });
  });
}
