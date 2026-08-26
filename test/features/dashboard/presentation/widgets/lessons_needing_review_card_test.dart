import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/dashboard/presentation/widgets/lessons_needing_review_card.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeRepo extends LessonFeedbackRepository {
  final List<LessonFeedbackModel> _store = [];

  @override
  Future<Result<List<LessonFeedbackModel>>> getReported() async {
    return Result.success(_store.where((f) => f.reportedIncorrect).toList());
  }

  @override
  Future<Result<List<LessonFeedbackModel>>> getAll() async {
    return Result.success(List.from(_store));
  }

  void add(LessonFeedbackModel f) => _store.add(f);
}

Widget wrap(Widget child, LessonFeedbackRepository repo) {
  return ProviderScope(
    overrides: [
      lessonFeedbackRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

LessonFeedbackModel fb({
  String id = 'f1',
  String studentId = 's1',
  String targetType = 'explanation',
  int starRating = 0,
  bool reportedIncorrect = false,
  String? comment,
}) =>
    LessonFeedbackModel(
      id: id,
      studentId: studentId,
      targetType: targetType,
      starRating: starRating,
      reportedIncorrect: reportedIncorrect,
      comment: comment,
    );

void main() {
  group('LessonsNeedingReviewCard', () {
    testWidgets('shows empty state when no feedback needs review', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(wrap(const LessonsNeedingReviewCard(studentId: 's1'), repo));
      await tester.pumpAndSettle();

      expect(find.text('No lessons flagged for review'), findsOneWidget);
      expect(find.text('Lessons needing review'), findsNothing);
    });

    testWidgets('shows reported and low-rated feedback with target labels',
        (tester) async {
      final repo = _FakeRepo();
      repo.add(fb(
        id: 'r1',
        targetType: 'explanation',
        reportedIncorrect: true,
        comment: 'The integral step was wrong',
      ));
      repo.add(fb(id: 'low1', targetType: 'lesson', starRating: 1));

      await tester.pumpWidget(wrap(const LessonsNeedingReviewCard(studentId: 's1'), repo));
      await tester.pumpAndSettle();

      expect(find.text('Lessons needing review'), findsOneWidget);
      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Lesson'), findsOneWidget);
      expect(find.text('The integral step was wrong'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('filters feedback by studentId', (tester) async {
      final repo = _FakeRepo();
      repo.add(fb(id: 'mine', studentId: 's1', reportedIncorrect: true));
      repo.add(fb(id: 'others', studentId: 'other', reportedIncorrect: true));

      await tester.pumpWidget(wrap(const LessonsNeedingReviewCard(studentId: 's1'), repo));
      await tester.pumpAndSettle();

      expect(find.text('Reported'), findsOneWidget);
    });
  });
}
