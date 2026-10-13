import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'curriculum_seed_data.dart';

/// Creates the seed topics and subtopics of [entry] under [subjectId].
///
/// Returns the IDs of every created topic/subtopic in creation order.
///
/// [TopicRepository.create] catches Hive write errors internally and
/// returns [Result.failure] instead of throwing, so every write result
/// is checked: the first failure aborts the seeding and is propagated
/// as [Result.failure] rather than being masked as success (which
/// would leave the subject referencing topics that were never
/// persisted).
///
/// IDs are generated with [IdGenerator], whose monotonic process-wide
/// counter guarantees uniqueness even when topics are created within
/// the same millisecond (e.g. two subjects seeded back-to-back).
/// Clock-based IDs would collide in that case and, because
/// [TopicRepository.create] saves by ID, silently overwrite each
/// other in the topics box.
Future<Result<List<String>>> createSeedTopics(
  TopicRepository topicRepo,
  String subjectId,
  CurriculumSeedEntry entry,
) async {
  final createdTopicIds = <String>[];
  for (final seedTopic in entry.topics) {
    final topicId = IdGenerator.generate('topic');
    final topic = Topic(
      id: topicId,
      subjectId: subjectId,
      title: seedTopic.title,
      description: seedTopic.description,
      syllabusText: seedTopic.syllabusText,
      sortOrder: seedTopic.sortOrder,
    );
    final created = await topicRepo.create(topic);
    if (created.isFailure) {
      return Result.failure(
        'Failed to create seed topic "$topicId" for subject "$subjectId": ${created.error}',
      );
    }
    createdTopicIds.add(topicId);

    for (final sub in seedTopic.subtopics) {
      final subId = IdGenerator.generate('topic');
      final subtopic = Topic(
        id: subId,
        subjectId: subjectId,
        title: sub.title,
        description: sub.description,
        syllabusText: sub.syllabusText,
        sortOrder: sub.sortOrder,
        parentId: topicId,
      );
      final createdSubtopic = await topicRepo.create(subtopic);
      if (createdSubtopic.isFailure) {
        return Result.failure(
          'Failed to create seed topic "$subId" for subject "$subjectId": ${createdSubtopic.error}',
        );
      }
      createdTopicIds.add(subId);
    }
  }
  return Result.success(createdTopicIds);
}
