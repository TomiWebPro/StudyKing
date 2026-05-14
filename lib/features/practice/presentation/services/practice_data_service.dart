import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';

class PracticeDataService {
  final SpacedRepetitionRepository _srRepo;
  final QuestionRepository _questionRepo;
  final WidgetRef _ref;

  PracticeDataService(WidgetRef ref)
      : _ref = ref,
        _srRepo = ref.read(spacedRepetitionRepositoryProvider),
        _questionRepo = ref.read(questionRepositoryProvider);

  Future<List<Subject>> fetchSubjects() async {
    final repo = await _ref.read(subjectsRepositoryProvider.future);
    return repo.getAll();
  }

  Future<Map<String, int>> loadDueCounts(List<Subject> subjects) async {
    final dueCounts = <String, int>{};
    for (final subject in subjects) {
      final result = await _srRepo.getSubjectDueCount(subject.id);
      if (result.isSuccess && result.data != null) {
        dueCounts[subject.id] = result.data!;
      } else {
        dueCounts[subject.id] = 0;
      }
    }
    return dueCounts;
  }

  Future<List<String>> loadTopics(QuestionRepository questionRepo) async {
    final result = await questionRepo.getAll();
    if (result.isFailure || result.data == null || result.data!.isEmpty) {
      return [];
    }
    return result.data!
        .where((q) => q.topic != null && q.topic!.isNotEmpty)
        .map((q) => q.topic!)
        .toSet()
        .toList();
  }

  Future<List<Question>> loadTopicQuestions(String topic) async {
    final result = await _questionRepo.getAll();
    if (result.isFailure || result.data == null) return [];
    return result.data!.where((q) => q.topic == topic).toList();
  }

  Future<List<Question>> loadWeakAreaQuestions(MasteryGraphService masteryService, BuildContext context) async {
    final studentId = StudentIdService().getStudentId();
    final weakTopicsResult = await masteryService.getWeakTopics(studentId);
    if (weakTopicsResult.isFailure || weakTopicsResult.data == null || weakTopicsResult.data!.isEmpty) {
      return [];
    }
    final weakTopicIds = weakTopicsResult.data!.map((s) => s.topicId).toSet();
    final questionsResult = await _questionRepo.getAll();
    if (questionsResult.isFailure || questionsResult.data == null) return [];
    return questionsResult.data!.where((q) => weakTopicIds.contains(q.topicId)).toList();
  }
}
