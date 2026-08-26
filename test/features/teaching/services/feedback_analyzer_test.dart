import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/teaching/services/feedback_analyzer.dart';

class _FakeRepo extends LessonFeedbackRepository {
  final List<LessonFeedbackModel> _store = [];
  bool failGetByStudent = false;
  bool failGetReported = false;

  @override
  Future<Result<List<LessonFeedbackModel>>> getByStudent(String studentId) async {
    if (failGetByStudent) return Result.failure('boom');
    return Result.success(
        _store.where((f) => f.studentId == studentId).toList());
  }

  @override
  Future<Result<List<LessonFeedbackModel>>> getReportedByStudent(
      String studentId) async {
    if (failGetReported) return Result.failure('boom');
    return Result.success(_store
        .where((f) => f.reportedIncorrect && f.studentId == studentId)
        .toList());
  }

  void add(LessonFeedbackModel f) => _store.add(f);
}

LessonFeedbackModel feedback({
  String id = 'f1',
  String studentId = 's1',
  int starRating = 0,
  String sentiment = 'none',
  bool reportedIncorrect = false,
  String? comment,
}) =>
    LessonFeedbackModel(
      id: id,
      studentId: studentId,
      targetType: 'explanation',
      starRating: starRating,
      sentiment: sentiment,
      reportedIncorrect: reportedIncorrect,
      comment: comment,
    );

void main() {
  group('FeedbackAnalyzer', () {
    late _FakeRepo repo;
    late FeedbackAnalyzer analyzer;

    setUp(() {
      repo = _FakeRepo();
      analyzer = FeedbackAnalyzer(repo);
    });

    test('returns empty note when there are no concerns', () async {
      repo.add(feedback(id: 'a', starRating: 5, sentiment: 'positive'));
      final result = await analyzer.analyzeStudent('s1');
      expect(result.isSuccess, isTrue);
      final analysis = result.data!;
      expect(analysis.feedbackCount, 1);
      expect(analysis.hasConcerns, isFalse);
      expect(analysis.contextNote, isEmpty);
    });

    test('flags reported and low-rated feedback and builds a note', () async {
      repo.add(feedback(
        id: 'r1',
        starRating: 5,
        reportedIncorrect: true,
        comment: 'The derivative step was wrong',
      ));
      repo.add(feedback(id: 'low1', starRating: 2, sentiment: 'negative'));
      repo.add(feedback(id: 'ok1', starRating: 5, sentiment: 'positive'));

      final result = await analyzer.analyzeStudent('s1');
      expect(result.isSuccess, isTrue);
      final analysis = result.data!;
      expect(analysis.reportedCount, 1);
      expect(analysis.negativeCount, 1);
      expect(analysis.averageRating, closeTo((5 + 2 + 5) / 3, 0.001));
      expect(analysis.contextNote, contains('The derivative step was wrong'));
      expect(analysis.contextNote, contains('step-by-step'));
    });

    test('buildTutorContextNote degrades to empty on repository failure',
        () async {
      repo.failGetByStudent = true;
      repo.failGetReported = true;
      final result = await analyzer.buildTutorContextNote('s1');
      expect(result.isSuccess, isTrue);
      expect(result.data, '');
    });

    test('analyzeStudent degrades gracefully on repository failure', () async {
      repo.failGetByStudent = true;
      repo.failGetReported = true;
      final result = await analyzer.analyzeStudent('s1');
      expect(result.isSuccess, isTrue);
      expect(result.data!.feedbackCount, 0);
      expect(result.data!.hasConcerns, isFalse);
    });
  });
}
