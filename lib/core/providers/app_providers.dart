import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../data/database_service.dart';
import '../services/engagement_scheduler.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryStateRepositoryProvider, questionMasteryStateRepositoryProvider, topicDependencyRepositoryProvider, questionEvaluationRepositoryProvider;
import '../services/notification_service.dart';
import '../services/plan_adherence_orchestrator.dart';
import '../services/study_progress_tracker.dart';
import '../services/mastery_graph_service.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorServiceProvider;
import 'package:studyking/core/services/student_id_service.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(
    topicRepository: TopicRepository(),
    questionRepository: QuestionRepository(),
    attemptRepository: AttemptRepository(),
    lessonRepository: LessonRepository(),
    sessionRepository: SessionRepository(),
    subjectRepository: SubjectRepository(),
    conversationRepository: ConversationRepository(),
    tutorSessionRepository: TutorSessionRepository(),
  );
});

SettingsRepository? _settingsRepo;

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return _settingsRepo!;
});

void initSettingsRepository(SettingsRepository repo) {
  _settingsRepo = repo;
}

class SettingsController extends StateNotifier<SettingsBox> {
  final Logger _logger = const Logger('SettingsController');
  final SettingsRepository _repository;
  bool _hasLoadedOnce = false;

  SettingsController(this._repository) : super(SettingsBox()) {
    _loadSettings();
  }

  SettingsBox get currentState => state;

  Future<void> _loadSettings() async {
    if (_hasLoadedOnce) return;
    _hasLoadedOnce = true;
    final result = await _repository.getSettings();
    if (result.isSuccess) {
      state = result.data!;
    } else {
      _logger.w('Error loading settings: ${result.error}');
    }
  }

  Future<void> updateSettings(SettingsUpdate update, {LlmProvider? llmProvider}) async {
    final updateResult = await _repository.updateSettings(update);
    if (updateResult.isFailure) {
      _logger.w('Error updating settings: ${updateResult.error}');
      return;
    }
    if (llmProvider != null) {
      await _repository.saveProvider(llmProvider);
    }
    final settingsResult = await _repository.getSettings();
    if (settingsResult.isSuccess) {
      state = settingsResult.data!;
    } else {
      _logger.w('Error loading settings after update: ${settingsResult.error}');
    }
  }

  Future<void> saveApiKey(String key) async {
    final result = await _repository.saveApiKey(service: 'default', key: key);
    if (result.isFailure) {
      _logger.w('Error saving API key: ${result.error}');
      return;
    }
    await _loadSettings();
  }

  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    final statsResult = await _repository.updateStats(
      sessionCount: sessionCount,
      studyTimeMs: studyTimeMs,
      questions: questions,
    );
    if (statsResult.isFailure) {
      _logger.w('Error updating stats: ${statsResult.error}');
      return;
    }
    final settingsResult = await _repository.getSettings();
    if (settingsResult.isSuccess) {
      state = settingsResult.data!;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsBox>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final fontSizeProvider = StateProvider<double>((ref) => 16.0);

final apiKeyProvider = StateProvider<String>((ref) => '');

final apiBaseUrlProvider = StateProvider<String>((ref) => ApiConfig.openRouterBaseUrlString);

final selectedModelProvider = StateProvider<String>((ref) => '');

final llmProviderProvider = StateProvider<LlmProvider>((ref) => LlmProvider.openRouter);

String? _initialLanguageCode;

void setInitialLanguageCode(String code) {
  _initialLanguageCode = code;
}

final localeProvider = StateProvider<Locale>((ref) {
  try {
    if (_initialLanguageCode != null && _initialLanguageCode!.isNotEmpty) {
      return Locale(_initialLanguageCode!);
    }
    if (Hive.isBoxOpen('profile')) {
      final box = Hive.box('profile');
      final lang = box.get('language', defaultValue: '') as String;
      if (lang.isNotEmpty) {
        return Locale(lang);
      }
    }
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
  } catch (e) {
    const Logger('localeProvider').w('Failed to get device locale', e);
  }
  return const Locale('en');
});

final planOrchestratorProvider = Provider<PlanAdherenceOrchestrator>((ref) {
  return PlanAdherenceOrchestrator();
});

final engagementTrackerProvider = Provider<StudyProgressTracker>((ref) {
  final l10n = ref.watch(l10nProvider);
  final defaultL10n = lookupAppLocalizations(const Locale('en'));
  final tracker = StudyProgressTracker(
    attemptRepo: ref.watch(engagementAttemptRepoProvider),
    masteryService: ref.watch(engagementMasteryServiceProvider),
    sessionRepo: ref.watch(databaseProvider).sessionRepository,
    l10n: l10n ?? defaultL10n,
  );
  if (l10n != null) {
    tracker.updateLocalization(l10n);
  }
  ref.listen(l10nProvider, (_, next) {
    if (next != null) {
      tracker.updateLocalization(next);
    }
  });
  return tracker;
});

final engagementMasteryServiceProvider = Provider<MasteryGraphService>((ref) {
  return MasteryGraphService(
    masteryStateRepo: ref.watch(masteryStateRepositoryProvider),
    questionMasteryRepo: ref.watch(questionMasteryStateRepositoryProvider),
    topicDependencyRepo: ref.watch(topicDependencyRepositoryProvider),
    questionEvaluationRepo: ref.watch(questionEvaluationRepositoryProvider),
  );
});

final engagementAttemptRepoProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

final engagementNudgeRepoProvider = Provider<EngagementNudgeRepository>((ref) {
  return EngagementNudgeRepository();
});

final engagementAdherenceRepoProvider = Provider<PlanAdherenceRepository>((ref) {
  return PlanAdherenceRepository();
});

final engagementPlannerServiceProvider = Provider<PlannerService>((ref) {
  return PlannerService(
    masteryService: ref.watch(engagementMasteryServiceProvider),
  );
});

final engagementSchedulerProvider = Provider<EngagementScheduler>((ref) {
  final l10n = ref.watch(l10nProvider);
  final defaultL10n = lookupAppLocalizations(const Locale('en'));
  final studentId = StudentIdService().getStudentId();
  final scheduler = EngagementScheduler(
    tracker: ref.watch(engagementTrackerProvider),
    masteryService: ref.watch(engagementMasteryServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
    nudgeRepository: ref.watch(engagementNudgeRepoProvider),
    adherenceRepository: ref.watch(engagementAdherenceRepoProvider),
    planOrchestrator: ref.watch(planOrchestratorProvider),
    sessionRepository: ref.watch(databaseProvider).sessionRepository,
    plannerService: ref.watch(engagementPlannerServiceProvider),
    mentorService: ref.watch(mentorServiceProvider(studentId)),
    l10n: l10n ?? defaultL10n,
  );
  if (l10n != null) scheduler.updateLocalization(l10n);
  ref.listen(l10nProvider, (_, next) {
    if (next != null) scheduler.updateLocalization(next);
  });
  ref.onDispose(() {
    scheduler.dispose();
  });
  return scheduler;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final l10nProvider = StateProvider<AppLocalizations?>((ref) => null);


