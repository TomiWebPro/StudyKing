import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'curriculum_seed_data.dart';

/// Creates the seed topics and subtopics of [entry] under [subjectId].
///
/// Returns the IDs of every created topic/subtopic in creation order.
///
/// IDs are generated with [IdGenerator], whose monotonic process-wide
/// counter guarantees uniqueness even when topics are created within
/// the same millisecond (e.g. two subjects seeded back-to-back).
/// Clock-based IDs would collide in that case and, because
/// [TopicRepository.create] saves by ID, silently overwrite each
/// other in the topics box.
Future<List<String>> createSeedTopics(
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
    await topicRepo.create(topic);
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
      await topicRepo.create(subtopic);
      createdTopicIds.add(subId);
    }
  }
  return createdTopicIds;
}
