import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';

/// Aggregate result of analyzing a student's lesson feedback.
class FeedbackAnalysis {
  final String studentId;
  final int feedbackCount;
  final int reportedCount;
  final int negativeCount;
  final double averageRating;
  final List<LessonFeedbackModel> reported;
  final List<LessonFeedbackModel> negative;

  const FeedbackAnalysis({
    required this.studentId,
    required this.feedbackCount,
    required this.reportedCount,
    required this.negativeCount,
    required this.averageRating,
    required this.reported,
    required this.negative,
  });

  /// A non-empty, human/LLM-readable note describing recurring quality issues,
  /// suitable for injecting into the tutor system prompt. Empty when there is
  /// nothing notable to surface.
  String get contextNote => _buildNote(this);

  bool get hasConcerns => reported.isNotEmpty || negative.isNotEmpty;

  static String _buildNote(FeedbackAnalysis analysis) {
    if (!analysis.hasConcerns) return '';
    final buffer = StringBuffer();
    buffer.writeln(
      'Quality feedback: the student has previously flagged some explanations as '
      'unhelpful or incorrect. Provide clearer, step-by-step explanations and '
      'double-check factual accuracy.',
    );
    final concerns = <String>[];
    for (final item in analysis.reported.take(2)) {
      if (item.comment != null && item.comment!.trim().isNotEmpty) {
        concerns.add(item.comment!.trim());
      }
    }
    for (final item in analysis.negative.take(2)) {
      if (item.comment != null && item.comment!.trim().isNotEmpty) {
        concerns.add(item.comment!.trim());
      }
    }
    if (concerns.isNotEmpty) {
      buffer.writeln('Specific concerns reported:');
      for (final concern in concerns.take(3)) {
        buffer.writeln('- $concern');
      }
    }
    return buffer.toString().trim();
  }
}

/// Analyzes lesson feedback trends and derives actionable insights that the
/// tutor can use to improve future explanations for a given student.
class FeedbackAnalyzer {
  static final Logger _logger = const Logger('FeedbackAnalyzer');
  final LessonFeedbackRepository _repository;

  FeedbackAnalyzer(this._repository);

  Future<Result<FeedbackAnalysis>> analyzeStudent(String studentId) {
    return Result.capture(() async {
      final allResult = await _repository.getByStudent(studentId);
      final reportedResult = await _repository.getReportedByStudent(studentId);

      final all = allResult.fold(
        (data) => data,
        (error) {
          _logger.w('Failed to load feedback for $studentId: $error');
          return <LessonFeedbackModel>[];
        },
      );
      final reported = reportedResult.fold(
        (data) => data,
        (error) {
          _logger.w('Failed to load reported feedback for $studentId: $error');
          return <LessonFeedbackModel>[];
        },
      );

      final rated = all.where((f) => f.starRating > 0).toList();
      final averageRating = rated.isEmpty
          ? 0.0
          : rated.map((f) => f.starRating).reduce((a, b) => a + b) / rated.length;

      final negative = all
          .where((f) =>
              f.sentimentEnum == FeedbackSentiment.negative ||
              (f.starRating > 0 && f.starRating <= 2))
          .toList();

      return FeedbackAnalysis(
        studentId: studentId,
        feedbackCount: all.length,
        reportedCount: reported.length,
        negativeCount: negative.length,
        averageRating: averageRating,
        reported: reported,
        negative: negative,
      );
    }, context: 'analyzeStudent');
  }

  /// Convenience helper returning just the tutor-context note (empty string when
  /// there are no notable concerns). Never throws; failures degrade gracefully.
  Future<Result<String>> buildTutorContextNote(String studentId) async {
    final result = await analyzeStudent(studentId);
    return result.map((analysis) => analysis.contextNote);
  }
}
