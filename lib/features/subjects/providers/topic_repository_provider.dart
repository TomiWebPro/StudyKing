import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository();
});
