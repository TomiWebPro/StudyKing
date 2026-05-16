import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class PracticeDataService {
  final Logger _logger = const Logger('PracticeDataService');
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
    return _subjectRepo.getAll();
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

  Future<List<String>> loadTopics(QuestionRepository questionRepo) async {
    try {
      final questions = await questionRepo.getAll();
      if (questions.isEmpty) return [];
      return questions
          .where((q) => q.topic != null && q.topic!.isNotEmpty)
          .map((q) => q.topic!)
          .toSet()
          .toList();
    } catch (e) {
      _logger.w('Failed to load topics: $e');
      return [];
    }
  }

  Future<List<Question>> loadTopicQuestions(String topic) async {
    try {
      final questions = await _questionRepo.getAll();
      return questions.where((q) => q.topic == topic).toList();
    } catch (e) {
      _logger.w('Failed to load topic questions: $e');
      return [];
    }
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
    try {
      final allQuestions = await _questionRepo.getAll();
      return allQuestions
          .where((q) => weakTopicIds.contains(q.topicId))
          .toList();
    } catch (e) {
      _logger.w('Failed to load weak area questions: $e');
      return [];
    }
  }
}
