import 'package:flutter/material.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider, sourceRepositoryProvider, questionVariantServiceProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/presentation/screens/practice_session_screen.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/service_providers.dart' show studentIdServiceProvider, voiceServiceProvider;
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/core/errors/result.dart' show Result;
import 'package:studyking/features/settings/data/models/settings_box.dart' show SettingsBox;
import 'package:studyking/features/settings/data/models/settings_update.dart';
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

  @override
  Future<Result<Question?>> get(String key) async {
    final list = result.data ?? [];
    try {
      return Result.success(list.firstWhere((q) => q.id == key));
    } catch (_) {
      return Result.success(null);
    }
  }
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];

  @override
  Future<Result<void>> save(String key, Session session) async {
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async => Result.success(sessions.where((s) => s.studentId == studentId).toList());
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

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    return Result.success(const []);
  }

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async => Result.success(0);
}

class FakeSettingsRepository extends SettingsRepository {
  @override
  Future<Result<SettingsBox>> getSettings() async {
    return Result.success(SettingsBox());
  }

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    return Result.success(null);
  }
}

class FakeSettingsController extends SettingsController {
  FakeSettingsController() : super(FakeSettingsRepository());
}

class FakeTopicRepository extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async => Result.success([]);
}

class FakeSourceRepository extends SourceRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Source>>> getAll() async => Result.success([]);

  @override
  Future<Result<List<Source>>> getBySubject(String subjectId) async => Result.success([]);
}

class FakeStudentIdService extends StudentIdService {
  @override
  Result<String> getStudentId() => Result.success('test-student-id');

  @override
  Future<Result<void>> init() async => Result.success(null);
}

class FakeMasteryRecorder extends MasteryRecorder {
  FakeMasteryRecorder()
      : super(
          masteryGraphService: FakeMasteryGraphService(),
          srEngine: SpacedRepetitionEngine(),
          attemptRepo: FakeAttemptRepository(),
          questionMasteryRepo: QuestionMasteryStateRepository(),
          questionRepo: FakeQuestionRepository(Result.success([])),
        );

  @override
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String questionId,
    required String subjectId,
    required String topicId,
    required bool isCorrect,
    required int timeSpentMs,
    required int confidence,
    required String userAnswer,
    DateTime? timestamp,
  }) async {
    return Result.success(null);
  }
}

class FakeAttemptRepository extends AttemptRepository {
  FakeAttemptRepository() : super();
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);
  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(String studentId, String subjectId) async => Result.success([]);
  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);
}

class FakeMasteryGraphService extends MasteryGraphService {
  FakeMasteryGraphService() : super();
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<void>> recordAttempt({required String studentId, required String topicId, required String questionId, required bool isCorrect, required int confidence, required int timeSpentMs, String? subtopicId}) async => Result.success(null);
}

class _DummyLlmService implements LlmService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuestionVariantService extends QuestionVariantService {
  FakeQuestionVariantService()
      : super(
          questionRepo: FakeQuestionRepository(Result.success([])),
          llmService: _DummyLlmService(),
          modelId: 'test',
        );

  @override
  Future<Result<Question>> selectVariantForRetry(Question question, {String? excludeVariantId}) async {
    return Result.success(question);
  }
}

class FakeMistakeReviewService extends MistakeReviewService {
  FakeMistakeReviewService() : super(attemptRepo: FakeAttemptRepository(), questionRepo: FakeQuestionRepository(Result.success([])));
  @override
  Future<Result<List<MistakeEntry>>> getMistakesFromSession({required String studentId, required String subjectId, DateTime? after}) async => Result.success([]);
}

class FakeVoiceService extends VoiceService {
  FakeVoiceService() : super(platform: TargetPlatform.linux);
  @override
  bool get isAvailable => false;
  @override
  bool get isListening => false;
  @override
  Stream<String> get transcribedText => const Stream.empty();
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
      sourceRepositoryProvider.overrideWithValue(FakeSourceRepository()),
      topicRepositoryProvider.overrideWithValue(FakeTopicRepository()),
      studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
      masteryRecorderProvider.overrideWithValue(FakeMasteryRecorder()),
      mistakeReviewServiceProvider.overrideWithValue(FakeMistakeReviewService()),
      questionVariantServiceProvider.overrideWithValue(FakeQuestionVariantService()),
      voiceServiceProvider.overrideWithValue(FakeVoiceService()),
      attemptRepositoryProvider.overrideWithValue(FakeAttemptRepository()),
      sessionRepositoryProvider.overrideWithValue(sessionRepo ?? FakeSessionRepository()),
      if (srService != null)
        spacedRepetitionServiceProvider.overrideWithValue(srService)
      else
        spacedRepetitionServiceProvider.overrideWithValue(FakeSpacedRepetitionService()),
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
