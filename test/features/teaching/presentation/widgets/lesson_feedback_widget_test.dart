import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/teaching/presentation/widgets/lesson_feedback_widget.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeRepo extends LessonFeedbackRepository {
  final List<LessonFeedbackModel> stored = [];
  bool open = true;

  @override
  bool get isOpen => open;

  @override
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
    if (!open) return Result.failure('closed');
    final model = LessonFeedbackModel(
      id: 'gen-${stored.length}',
      studentId: studentId,
      targetType: targetType,
      lessonId: lessonId,
      messageId: messageId,
      sentiment: sentiment,
      starRating: starRating,
      comment: comment,
      reportedIncorrect: reportedIncorrect,
    );
    stored.add(model);
    return Result.success(model.id);
  }
}

Widget buildFeedbackTest(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('LessonFeedbackWidget', () {
    testWidgets('renders feedback controls and submits feedback',
        (tester) async {
      final fake = _FakeRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonFeedbackRepositoryProvider.overrideWithValue(fake),
          ],
          child: buildFeedbackTest(
            const LessonFeedbackWidget(
              studentId: 'test-student',
              targetType: 'explanation',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
          tester.element(find.byType(LessonFeedbackWidget)))!;
      expect(find.text(l10n.feedbackSectionTitle), findsOneWidget);
      expect(find.text(l10n.feedbackThumbsUp), findsOneWidget);
      expect(find.text(l10n.feedbackThumbsDown), findsOneWidget);

      await tester.tap(find.text(l10n.feedbackThumbsUp));
      await tester.pumpAndSettle();

      final stars = find.byIcon(Icons.star_outline_rounded);
      expect(stars, findsWidgets);
      await tester.tap(stars.at(3));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.feedbackSubmit));
      await tester.pumpAndSettle();

      expect(fake.stored, hasLength(1));
      expect(fake.stored.first.studentId, 'test-student');
      expect(fake.stored.first.sentimentEnum.name, 'positive');
      expect(fake.stored.first.starRating, 4);
      expect(find.text(l10n.feedbackThanks), findsOneWidget);
    });

    testWidgets('reporting incorrect content sets the flag', (tester) async {
      final fake = _FakeRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonFeedbackRepositoryProvider.overrideWithValue(fake),
          ],
          child: buildFeedbackTest(
            const LessonFeedbackWidget(
              studentId: 'test-student',
              targetType: 'content',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
          tester.element(find.byType(LessonFeedbackWidget)))!;
      await tester.tap(find.text(l10n.feedbackReportIncorrect));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.feedbackSubmit));
      await tester.pumpAndSettle();

      expect(fake.stored, hasLength(1));
      expect(fake.stored.first.reportedIncorrect, isTrue);
      expect(find.text(l10n.feedbackReportedBadge), findsOneWidget);
    });

    testWidgets('optional comment is persisted when provided',
        (tester) async {
      final fake = _FakeRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonFeedbackRepositoryProvider.overrideWithValue(fake),
          ],
          child: buildFeedbackTest(
            const LessonFeedbackWidget(
              studentId: 'test-student',
              targetType: 'lesson',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
          tester.element(find.byType(LessonFeedbackWidget)))!;
      await tester.enterText(
        find.byType(TextField), 'Please slow down next time');
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.feedbackSubmit));
      await tester.pumpAndSettle();

      expect(fake.stored, hasLength(1));
      expect(fake.stored.first.comment, 'Please slow down next time');
    });
  });
}
