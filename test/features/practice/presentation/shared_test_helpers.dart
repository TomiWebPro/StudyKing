import 'package:flutter/material.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/presentation/screens/practice_session_screen.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/errors/result.dart' show Result;
import 'package:studyking/features/settings/data/models/settings_box.dart' show SettingsBox;
import 'package:studyking/features/settings/data/repositories/settings_repository.dart' show SettingsRepository;

class FakeQuestionRepository extends QuestionRepository {
  final Result<List<Question>> result;

  FakeQuestionRepository(this.result);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async => result;

  @override
  Future<Result<List<Question>>> getAll() async => result;
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];

  @override
  Future<Result<void>> save(String key, Session session) async {
    sessions.add(session);
    return Result.success(null);
  }
}

class FakeSpacedRepetitionService extends SpacedRepetitionService {
  FakeSpacedRepetitionService()
      : super(
          questionRepo: FakeQuestionRepository(Result.success([])),
          attemptRepo: AttemptRepository(),
        );
  final updateCalls = <UpdateNextReviewCall>[];

  @override
  Future<Result<void>> updateNextReviewDate(String questionId, double masteryLevel) async {
    updateCalls.add(UpdateNextReviewCall(questionId, masteryLevel));
    return Result.success(null);
  }
}

class FakeSettingsRepository extends SettingsRepository {
  @override
  Future<Result<SettingsBox>> getSettings() async {
    return Result.success(SettingsBox());
  }

  @override
  Future<Result<void>> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    dynamic llmProvider,
    dynamic themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
    bool? reduceMotion,
    bool? revisionRemindersEnabled,
    bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled,
    bool? planAdjustmentNotificationsEnabled,
    int? breakDurationSeconds,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? firstFocusVisit,
    bool? dailyReminderEnabled,
  }) async {
    return Result.success(null);
  }
}

class FakeSettingsController extends SettingsController {
  FakeSettingsController() : super(FakeSettingsRepository());
}

class UpdateNextReviewCall {
  final String questionId;
  final double masteryLevel;
  UpdateNextReviewCall(this.questionId, this.masteryLevel);
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
  SpacedRepetitionService? srService,
  bool isSpacedRepetition = false,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => FakeSettingsController()),
      questionRepositoryProvider.overrideWithValue(FakeQuestionRepository(result)),
      if (sessionRepo != null)
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
      if (srService != null)
        spacedRepetitionServiceProvider.overrideWithValue(srService),
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
