import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class PracticeDataService {
  final SpacedRepetitionService _srService;
  final QuestionRepository _questionRepo;
  final SubjectRepository _subjectRepo;
  final StudentIdService _studentIdService;

  PracticeDataService({
    required SpacedRepetitionService srService,
    required QuestionRepository questionRepo,
    required SubjectRepository subjectRepo,
    required StudentIdService studentIdService,
  })  : _srService = srService,
        _questionRepo = questionRepo,
        _subjectRepo = subjectRepo,
        _studentIdService = studentIdService;

  Future<List<Subject>> fetchSubjects() async {
    final result = await _subjectRepo.getAll();
    return result.data ?? [];
  }

  Future<Map<String, int>> loadDueCounts(List<Subject> subjects) async {
    final dueCounts = <String, int>{};
    for (final subject in subjects) {
      final result = await _srService.getSubjectDueCount(subject.id);
      if (result.isSuccess && result.data != null) {
        dueCounts[subject.id] = result.data!;
      } else {
        dueCounts[subject.id] = 0;
      }
    }
    return dueCounts;
  }

  Future<Map<String, String>> loadTopicsWithNames(QuestionRepository questionRepo) async {
    final questionsResult = await questionRepo.getAll();
    final questions = questionsResult.data ?? [];
    if (questions.isEmpty) return {};
    final topicMap = <String, String>{};
    for (final q in questions) {
      if (q.topicId.isNotEmpty && (q.topic?.isNotEmpty == true)) {
        topicMap.putIfAbsent(q.topicId, () => q.topic!);
      }
    }
    return topicMap;
  }

  Future<List<String>> loadTopicIds(QuestionRepository questionRepo) async {
    final questionsResult = await questionRepo.getAll();
    final questions = questionsResult.data ?? [];
    if (questions.isEmpty) return [];
    return questions
        .where((q) => q.topicId.isNotEmpty)
        .map((q) => q.topicId)
        .toSet()
        .toList();
  }

  Future<List<Question>> loadWeakAreaQuestions(
      MasteryGraphService masteryService) async {
    final studentId = _studentIdService.getStudentId();
    final weakTopicsResult = await masteryService.getWeakTopics(studentId);
    if (weakTopicsResult.isFailure ||
        weakTopicsResult.data == null ||
        weakTopicsResult.data!.isEmpty) {
      return [];
    }
    final weakTopicIds =
        weakTopicsResult.data!.map((s) => s.topicId).toSet();
    final allQuestionsResult = await _questionRepo.getAll();
    final allQuestions = allQuestionsResult.data ?? [];
    return allQuestions
        .where((q) => weakTopicIds.contains(q.topicId))
        .toList();
  }
}
