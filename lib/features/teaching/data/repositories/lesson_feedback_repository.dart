import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:uuid/uuid.dart';

class LessonFeedbackRepository extends Repository<LessonFeedbackModel> {
  static final Logger _logger = const Logger('LessonFeedbackRepository');
  final Uuid _uuid;

  LessonFeedbackRepository({Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(boxName: HiveBoxNames.lessonFeedback);

  Future<void> init() async {
    await openBox(HiveBoxNames.lessonFeedback);
  }

  Future<Result<void>> saveFeedback(LessonFeedbackModel feedback) async {
    try {
      if (!isOpen) {
        _logger.w('lessonFeedback box not open; attempting lazy open');
        await openBox(HiveBoxNames.lessonFeedback);
      }
      if (!isOpen) {
        return Result.failure('Lesson feedback box unavailable');
      }
      await put(feedback.id, feedback);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to save lesson feedback: $e', e);
      return Result.failure('Failed to save lesson feedback: $e');
    }
  }

  Future<Result<String>> submitFeedback({
    required String studentId,
    required String targetType,
    String? lessonId,
    String? messageId,
    String sentiment = 'none',
    int starRating = 0,
    String? comment,
    bool reportedIncorrect = false,
  }) async {
    final id = _uuid.v4();
    final feedback = LessonFeedbackModel(
      id: id,
      studentId: studentId,
      targetType: targetType,
      lessonId: lessonId,
      messageId: messageId,
      sentiment: sentiment,
      starRating: starRating,
      comment: comment,
      reportedIncorrect: reportedIncorrect,
    );
    final result = await saveFeedback(feedback);
    if (result.isFailure) {
      _logger.w('saveFeedback failed for $studentId: ${result.error}');
      return Result.failure(result.error);
    }
    return Result.success(id);
  }

  Future<Result<List<LessonFeedbackModel>>> getByStudent(
      String studentId) async {
    return Result.capture(() async {
      if (!isOpen) {
        _logger.w('lessonFeedback box not open for getByStudent');
        return <LessonFeedbackModel>[];
      }
      final all = filterBy((f) => f.studentId, studentId)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }, context: 'getByStudent');
  }

  Future<Result<List<LessonFeedbackModel>>> getByLesson(
      String lessonId) async {
    return Result.capture(() async {
      if (!isOpen) return <LessonFeedbackModel>[];
      final all = filterBy((f) => f.lessonId, lessonId)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }, context: 'getByLesson');
  }

  Future<Result<List<LessonFeedbackModel>>> getByMessage(
      String messageId) async {
    return Result.capture(() async {
      if (!isOpen) return <LessonFeedbackModel>[];
      final all = filterBy((f) => f.messageId, messageId)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }, context: 'getByMessage');
  }

  Future<Result<List<LessonFeedbackModel>>> getReported() async {
    return Result.capture(() async {
      if (!isOpen) return <LessonFeedbackModel>[];
      final all = box.values
          .where((f) => f.reportedIncorrect)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }, context: 'getReported');
  }

  Future<Result<List<LessonFeedbackModel>>> getReportedByStudent(
      String studentId) async {
    return Result.capture(() async {
      if (!isOpen) return <LessonFeedbackModel>[];
      final all = box.values
          .where((f) => f.reportedIncorrect && f.studentId == studentId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }, context: 'getReportedByStudent');
  }

  Future<Result<void>> deleteFeedback(String id) async {
    return Result.capture(() async {
      if (!isOpen) return;
      await delete(id);
    }, context: 'deleteFeedback');
  }
}
