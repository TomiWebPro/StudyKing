import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider, mentorProgressTrackerProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider, PlannerNotifier;
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/voice_service.dart';
import '../../../helpers/navigator_observer_helper.dart';

class FakeSettingsRepo extends SettingsRepository {
  final Map<String, dynamic> _store = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    if (update.reduceMotion != null) _store['reduceMotion'] = update.reduceMotion;
    if (update.highContrastEnabled != null) _store['highContrastEnabled'] = update.highContrastEnabled;
    if (update.largeTouchTargets != null) _store['largeTouchTargets'] = update.largeTouchTargets;
    return Result.success(null);
  }

  @override
  Future<Result<SettingsBox>> getSettings() async {
    return Result.success(SettingsBox(
      reduceMotion: _store['reduceMotion'] as bool? ?? false,
      highContrastEnabled: _store['highContrastEnabled'] as bool? ?? false,
      largeTouchTargets: _store['largeTouchTargets'] as bool? ?? false,
    ));
  }
}

class FakePlannerService extends PlannerService {
  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async => Result.success(null);
  @override
  Future<Result<List<RoadmapModel>>> loadRoadmaps() async => Result.success([]);
  @override
  Future<Result<List<PendingActionModel>>> loadPendingActions() async => Result.success([]);
  @override
  Future<Result<List<Session>>> getScheduledLessons() async => Result.success([]);
  @override
  Future<Result<bool>> hasSchedulingConflict({required DateTime startTime, required int durationMinutes, String? excludeSessionId}) async => Result.success(false);
  @override
  Future<Result<bool>> scheduleLesson({required String topicId, required String topicTitle, required String subjectId, required DateTime scheduledTime, int durationMinutes = 30}) async => Result.success(true);
  @override
  Future<Result<RoadmapModel?>> createRoadmap({required String goal, required int days, required AppLocalizations l10n, String? subjectId}) async => Result.success(null);
}

class FakeNudgeRepo extends EngagementNudgeRepository {
  @override
  Future<void> init() async {}
  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);
  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async => Result.success([]);
  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class ControllableNudgeRepo extends EngagementNudgeRepository {
  final Completer<void> _initCompleter = Completer<void>();

  void completeInit() => _initCompleter.complete();

  @override
  Future<void> init() => _initCompleter.future;

  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);

  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async => Result.success([]);

  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class FakeSessionRepo extends SessionRepository {
  @override
  Future<Result<List<Session>>> getAll() async => Result.success([]);
  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success([]);
  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(0);
}

class FakeLlmService extends LlmService {
  final bool shouldThrow;
  final Duration? responseDelay;

  FakeLlmService({this.shouldThrow = false, this.responseDelay, bool hasApiKey = true})
      : super(
          config: LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: hasApiKey ? 'test-key' : '',
          ),
        );

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    if (shouldThrow) throw Exception('Simulated LLM error');
    if (responseDelay != null) await Future.delayed(responseDelay!);
    yield 'Mentor response';
  }
}

class FakeAttemptRepo extends AttemptRepository {
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);
}

class FakeTopicRepo extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.success(Topic(
      id: key,
      title: key,
      subjectId: 'subject-1',
      description: '',
      syllabusText: '',
    ));
  }
}

class FakeTopicRepoNoSubject extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.success(Topic(
      id: key,
      title: key,
      subjectId: '',
      description: '',
      syllabusText: '',
    ));
  }
}

class FakeTopicRepoThrowing extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.failure('DB error');
  }
}

class ThrowingNudgeRepo extends EngagementNudgeRepository {
  @override
  Future<void> init() async => throw Exception('Init simulation failure');
  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);
  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async => Result.success([]);
  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class FakeVoiceService extends VoiceService {
  final bool _available;
  final bool _listening;

  FakeVoiceService({bool available = false, bool listening = false})
      : _available = available,
        _listening = listening;

  @override
  bool get isAvailable => _available;
  @override
  bool get isListening => _listening;
}

class NudgeReturningRepo extends EngagementNudgeRepository {
  @override
  Future<void> init() async {}
  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);
  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async {
    return Result.success([
      EngagementNudgeModel(
        id: 'nudge-1',
        studentId: studentId,
        nudgeType: 'reminder',
        message: 'Time to study!',
        sentAt: DateTime.now(),
        severity: 'low',
      ),
    ]);
  }
  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class ThrowingProgressTracker extends FakeProgressTracker {
  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async {
    throw Exception('Simulated recommendations failure');
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  List<MasteryState> _weakTopics = [];
  List<QuestionMasteryState> _atRiskQuestions = [];

  void setWeakTopics(List<MasteryState> topics) => _weakTopics = topics;
  void setAtRiskQuestions(List<QuestionMasteryState> questions) => _atRiskQuestions = questions;

  FakeMasteryGraphService() : super();

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(_weakTopics);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return Result.success(_atRiskQuestions);
  }
}

class FakeProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> _overallStats = const {
    'totalAttempts': 100,
    'correctAttempts': 85,
    'accuracy': 85,
    'topicsStudied': 12,
    'weeklyActivity': 25,
    'totalStudyTimeHours': 45.5,
  };
  List<Map<String, dynamic>> _recommendations = const [];
  List<Map<String, dynamic>> _badges = const [];
  bool _throwOnReport = false;

  void setOverallStats(Map<String, dynamic> stats) => _overallStats = stats;
  void setRecommendations(List<Map<String, dynamic>> recs) => _recommendations = recs;
  void setBadges(List<Map<String, dynamic>> badges) => _badges = badges;
  void setThrowOnReport(bool v) => _throwOnReport = v;

  FakeProgressTracker() : super(attemptRepo: FakeAttemptRepo(), l10n: lookupAppLocalizations(const Locale('en')));

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    if (_throwOnReport) throw Exception('Simulated error');
    return Result.success(Map<String, dynamic>.from(_overallStats));
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async =>
      Result.success(List<Map<String, dynamic>>.from(_recommendations));

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async =>
      Result.success(List<Map<String, dynamic>>.from(_badges));
}

Widget buildMentorTestApp({
  LlmService? llmService,
  FakeMasteryGraphService? masteryGraph,
  FakeProgressTracker? progressTracker,
  EngagementNudgeRepository? nudgeRepo,
  TestNavigatorObserver? navigatorObserver,
  VoiceService? voiceService,
}) {
  return ProviderScope(
    overrides: [
      llmServiceProvider.overrideWithValue(
        llmService ?? FakeLlmService(),
      ),
      settingsProvider.overrideWith(
        (ref) => SettingsController(FakeSettingsRepo()),
      ),
      plannerServiceProvider.overrideWithValue(FakePlannerService()),
      mentorEngagementNudgeRepoProvider.overrideWithValue(
        nudgeRepo ?? FakeNudgeRepo(),
      ),
      mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
      masteryGraphServiceProvider.overrideWithValue(
        masteryGraph ?? FakeMasteryGraphService(),
      ),
      mentorProgressTrackerProvider.overrideWithValue(
        progressTracker ?? FakeProgressTracker(),
      ),
      if (voiceService != null)
        voiceServiceProvider.overrideWithValue(voiceService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: const MentorScreen(),
    ),
  );
}

class FakeTopicRepoNullData extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.success(null);
  }
}

class FakeControllableVoiceService extends VoiceService {
  final bool _available;
  bool _listening = false;
  final _transcriptionStream = StreamController<String>.broadcast();

  FakeControllableVoiceService({bool available = true}) : _available = available;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  Future<void> startListening({String? localeName}) async {
    _listening = true;
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
  }

  @override
  Stream<String> get transcribedText => _transcriptionStream.stream;
}

class NudgeThrowingRepo extends EngagementNudgeRepository {
  @override
  Future<void> init() async {}
  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);
  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async {
    throw Exception('Nudge fetch failure');
  }
  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class FakePlannerNotifier extends PlannerNotifier {
  bool didCreateRoadmap = false;
  String? createdGoal;
  int? createdDays;

  FakePlannerNotifier() : super(FakePlannerService());

  @override
  Future<void> createRoadmap({
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    didCreateRoadmap = true;
    createdGoal = goal;
    createdDays = days;
  }
}
