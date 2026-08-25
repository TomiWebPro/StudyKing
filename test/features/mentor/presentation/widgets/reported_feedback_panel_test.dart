import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/presentation/widgets/reported_feedback_panel.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeLessonFeedbackRepository extends LessonFeedbackRepository {
  final List<LessonFeedbackModel> _store;

  FakeLessonFeedbackRepository(this._store);

  @override
  bool get isOpen => true;

  @override
  Future<void> openBox(String boxName) async {}

  @override
  Future<Result<List<LessonFeedbackModel>>> getReported() async {
    return Result.success(
        _store.where((f) => f.reportedIncorrect).toList());
  }
}

LessonFeedbackModel makeReported({
  String id = 'r1',
  String targetType = 'explanation',
  String sentiment = 'negative',
  int starRating = 2,
  String? comment,
  String? lessonId,
  String? messageId,
}) {
  return LessonFeedbackModel(
    id: id,
    studentId: 's1',
    targetType: targetType,
    lessonId: lessonId,
    messageId: messageId,
    sentiment: sentiment,
    starRating: starRating,
    comment: comment,
    reportedIncorrect: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows empty state when no reported feedback', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonFeedbackRepositoryProvider
              .overrideWithValue(FakeLessonFeedbackRepository([])),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ReportedFeedbackPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No reported content yet.'), findsOneWidget);
  });

  testWidgets('surfaces reported feedback with target and comment',
      (tester) async {
    final item = makeReported(
      targetType: 'lesson',
      comment: 'The formula was wrong',
      lessonId: 'L-42',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonFeedbackRepositoryProvider
              .overrideWithValue(FakeLessonFeedbackRepository([item])),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ReportedFeedbackPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reported AI content'), findsOneWidget);
    expect(find.text('Lesson'), findsOneWidget);
    expect(find.text('The formula was wrong'), findsOneWidget);
    expect(find.text('Lesson: L-42'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
  });
}
