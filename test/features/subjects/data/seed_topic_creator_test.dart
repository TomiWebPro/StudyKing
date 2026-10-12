import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/curriculum_seed_data.dart';
import 'package:studyking/features/subjects/data/seed_topic_creator.dart';

/// Hand-written fake that mirrors [TopicRepository.create]'s
/// Hive put-by-key semantics: records whose IDs collide
/// overwrite each other, so lost records are detectable
/// through the stored count.
class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> storage = {};

  _FakeTopicRepository() : super();

  @override
  Future<Result<void>> create(Topic topic) async {
    storage[topic.id] = topic;
    return Result.success(null);
  }
}

void main() {
  group('createSeedTopics', () {
    int recordCount(CurriculumSeedEntry entry) => entry.topics
        .fold(0, (sum, topic) => sum + 1 + topic.subtopics.length);

    test('creates every topic and subtopic of a multi-subtopic seed', () async {
      final repo = _FakeTopicRepository();
      final chemistry = findSeedEntry('IB Chemistry')!;

      final ids = await createSeedTopics(repo, 'subject-chemistry', chemistry);

      // Every seeded topic/subtopic is persisted exactly once.
      expect(ids, hasLength(recordCount(chemistry)));
      expect(repo.storage.length, recordCount(chemistry));
      expect(repo.storage.keys.toSet(), ids.toSet());

      // All generated IDs are distinct and topic-prefixed.
      expect(ids.toSet().length, ids.length);
      for (final id in ids) {
        expect(id.startsWith('topic_'), isTrue);
      }

      // Records are scoped to the subject they were seeded for.
      for (final id in ids) {
        expect(repo.storage[id]!.subjectId, 'subject-chemistry');
      }

      // Subtopics are linked to an existing parent topic of
      // the same subject.
      for (final topic in repo.storage.values) {
        if (topic.parentId != null) {
          expect(repo.storage[topic.parentId], isNotNull);
          expect(repo.storage[topic.parentId]!.subjectId, topic.subjectId);
        }
      }

      // Root topics match the seed titles, in seed order.
      final roots = repo.storage.values
          .where((t) => t.parentId == null)
          .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(roots.map((t) => t.title), chemistry.topics.map((t) => t.title));
    });

    test('gives concurrently seeded subjects unique IDs (same-millisecond creation)', () async {
      final repo = _FakeTopicRepository();
      final entry = findSeedEntry('IB Physics')!;

      // Seed several subjects concurrently, the way two
      // subjects seeded back-to-back on a fast device
      // create their topics within the same millisecond.
      // Clock-based IDs would collide across invocations
      // (each starts its per-call counter at 0) and,
      // because create saves by ID, overwrite each other.
      const subjects = 10;
      final results = await Future.wait(
        List.generate(
          subjects,
          (i) => createSeedTopics(repo, 'subject-$i', entry),
        ),
      );

      final allIds = results.expand((ids) => ids).toList();
      final expectedTotal = subjects * recordCount(entry);

      // Every seeded record is persisted exactly once —
      // colliding IDs would have overwritten earlier records.
      expect(allIds, hasLength(expectedTotal));
      expect(repo.storage.length, expectedTotal);
      expect(repo.storage.keys.toSet(), allIds.toSet());

      // All generated IDs are distinct.
      expect(allIds.toSet().length, allIds.length);

      // Each subject's records are scoped to its own ID.
      for (var i = 0; i < subjects; i++) {
        final subjectIds = results[i];
        expect(subjectIds, hasLength(recordCount(entry)));
        for (final id in subjectIds) {
          expect(repo.storage[id]!.subjectId, 'subject-$i');
        }
      }
    });
  });
}
