import 'package:flutter/material.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/presentation/practice_session_screen.dart';

class FakeQuestionRepository extends QuestionRepository {
  final Result<List<Question>> result;

  FakeQuestionRepository(this.result);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async => result;
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<Result<void>> save(Session session) async {
    sessions.add(session);
    return Result.success(null);
  }
}

class FakeSpacedRepetitionRepository extends SpacedRepetitionRepository {
  final updateCalls = <UpdateNextReviewCall>[];

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> updateNextReviewDate(String questionId, double masteryLevel) async {
    updateCalls.add(UpdateNextReviewCall(questionId, masteryLevel));
    return Result.success(null);
  }
}

class UpdateNextReviewCall {
  final String questionId;
  final double masteryLevel;
  UpdateNextReviewCall(this.questionId, this.masteryLevel);
}

class TestNavigatorObserver extends NavigatorObserver {
  int popCount = 0;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

Question question({
  required String id,
  required String text,
  required QuestionType type,
  required String markschemeText,
  String topicId = 'topic-a',
  List<String> options = const [],
}) {
  final now = DateTime.utc(2024, 1, 1);
  return Question(
    id: id,
    text: text,
    type: type,
    subjectId: 'subject-a',
    topicId: topicId,
    markscheme: Markscheme(questionId: id, correctAnswer: markschemeText),
    options: options,
    createdAt: now,
    updatedAt: now,
  );
}

Widget sessionApp({
  required Result<List<Question>> result,
  String? topicId,
  int? questionCount,
  NavigatorObserver? observer,
  SessionRepository? sessionRepo,
  SpacedRepetitionRepository? srRepo,
  bool isSpacedRepetition = false,
}) {
  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(FakeQuestionRepository(result)),
      if (sessionRepo != null)
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
      if (srRepo != null)
        spacedRepetitionRepositoryProvider.overrideWithValue(srRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: observer == null ? const [] : [observer],
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeSessionScreen(
                    args: PracticeSessionArgs(
                      subjectId: 'subject-a',
                      topicId: topicId,
                      questionCount: questionCount,
                      isSpacedRepetition: isSpacedRepetition,
                    ),
                  ),
                ),
              ),
              child: const Text('Open Session'),
            ),
          ),
        ),
      ),
    ),
  );
}
