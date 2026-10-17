import 'package:flutter/material.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/settings_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/services/system_monitor_service.dart';
import 'package:studyking/core/utils/date_utils.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/services/learning_method_analytics_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/mentor/services/syllabus_focus_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class MentorContextBuilder {
  static final Logger _logger = const Logger('MentorContextBuilder');

  final StudyProgressTracker _progressTracker;
  final MasteryGraphService _masteryService;
  final PlannerService _plannerService;
  final SessionRepository _sessionRepository;
  final LearningMethodAnalyticsService? _learningAnalyticsService;
  final SourceRepository? _sourceRepository;

  /// Optional question repository used to resolve question IDs to concept
  /// labels (topic/topicId) and to surface already-generated variant counts
  /// in the recent-mistakes context block (Vision Next-Term §3.1
  /// scenario_practice_review_context). Null when unavailable — the per-question
  /// accuracy snapshot still injects question IDs so the prompt is never broken.
  final QuestionRepository? _questionRepository;
  final String _localeName;

  /// Device/system-load awareness (Vision Next-Term §4.3). When present, a
  /// concise device-status line is injected into the mentor context so the LLM
  /// can proactively advise on offline, battery, or CPU state (e.g.
  /// "I see you're offline — I'll switch to local Ollama"). Null on platforms
  /// without sensors (web) or when monitoring is unavailable — never throws.
  final SystemMonitorService? _systemMonitor;

  /// Holds the student's explicitly-set syllabus focus, set mid-conversation
  /// by the [SwitchSyllabusFocusTool]. When present, it overrides the
  /// implicit resolution in [_buildSyllabusContext] (Vision Next-Term §3.1).
  final SyllabusFocusService? _focusService;

  /// The student's configured LLM provider and backup/failover (Vision
  /// Next-Term §3.1 scenario audit: "List context the LLM needed vs what the
  /// system prompt actually injects"). When present, the active provider and
  /// backup status are injected into the mentor context so the LLM can advise
  /// on provider status and failover instead of guessing. Null when no config
  /// is available (tests/fallback) so existing context is untouched.
  final LlmConfiguration? _llmConfig;

  /// Human-readable summary of the student's active syllabi, so the mentor can
  /// understand which syllabus the student is referring to when they chat.
  String get currentSyllabusContext => _currentSyllabusContext;
  String _currentSyllabusContext = '';

  MentorContextBuilder({
    required StudyProgressTracker progressTracker,
    required MasteryGraphService masteryService,
    required PlannerService plannerService,
    required SessionRepository sessionRepository,
    LearningMethodAnalyticsService? learningAnalyticsService,
    SourceRepository? sourceRepository,
    QuestionRepository? questionRepository,
    required String localeName,
    SystemMonitorService? systemMonitor,
    SyllabusFocusService? focusService,
    LlmConfiguration? llmConfig,
  })  : _progressTracker = progressTracker,
        _masteryService = masteryService,
        _plannerService = plannerService,
        _sessionRepository = sessionRepository,
        _learningAnalyticsService = learningAnalyticsService,
        _sourceRepository = sourceRepository,
        _questionRepository = questionRepository,
        _localeName = localeName,
        _focusService = focusService,
        _llmConfig = llmConfig,
        _systemMonitor = systemMonitor;

  /// Upper bound on the number of per-question mistake lines injected into the
  /// mentor context (Vision Next-Term §3.1 scenario_practice_review_context).
  static const int _maxRecentMistakes = 5;

  Future<Result<String>> buildContextPrompt() async {
    try {
      final statsResult = await _progressTracker.getOverallStats(_plannerService.studentId);
    final stats = statsResult.data ?? <String, dynamic>{};
    final weakTopics = (await _loadWeakTopics()).data ?? [];
    final plan = (await _loadPlan()).data;
    final roadmaps = (await _loadRoadmaps()).data ?? [];
    final pendingActions = (await _loadPendingActions()).data ?? [];
    final upcomingLessons = (await loadUpcomingLessons()).data ?? [];
    final missedLessons = (await _loadMissedLessons()).data ?? [];
    final adherenceDeviation = (await _loadAdherence()).data;
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = SettingsService.getDailyCapMinutes();
    final consecutiveDays = (await _getConsecutiveStudyDays()).data ?? 0;
    final daysSinceLastActivity = StudentIdService().getDaysSinceLastActivity();
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final bullet = l10n.mentorBulletPoint;

    final syllabusGoals = (await loadSyllabusGoals()).data ?? [];
    final upcomingLessonsForSyllabus = upcomingLessons;
    buildSyllabusContext(syllabusGoals, upcomingLessonsForSyllabus, l10n);

    final sources = await _getSourceInventory();

    final buffer = StringBuffer();
    buffer.writeln(l10n.mentorContextHeader);
    buffer.writeln('$bullet${l10n.mentorContextTotalAttempts(stats['totalAttempts'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextCorrectAttempts(stats['correctAttempts'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextAccuracy('${stats['accuracy']}')}');
    buffer.writeln('$bullet${l10n.mentorContextTopicsStudied(stats['topicsStudied'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextWeeklyActivity(stats['weeklyActivity'] as int? ?? 0)}');
    buffer.writeln('$bullet${l10n.mentorContextTotalStudyTime('${stats['totalStudyTimeHours']}')}');

    if (sources != null) {
      if (sources.isEmpty) {
        buffer.writeln('$bullet${l10n.mentorContextNoMaterials}');
      } else {
        // Vision §11 / §3.1: surface the student's uploaded materials so the
        // mentor LLM is not blind to content added since the last session.
        // Inventory is grouped per-syllabus (by subjectId) with capped titles
        // plus an overflow count, keeping the prompt bounded while making every
        // source visible to the agent. LLM-facing text -> en-invariant per
        // AGENTS i18n convention (prompts/tutor notes may stay invariant).
        _appendSourceInventory(buffer, sources, syllabusGoals, bullet);
      }
    }

    if (plan != null) {
      buffer.writeln('$bullet${l10n.mentorContextPlanPhase(_getPlanDay(plan), plan.dailyPlans.length)}');
      if (adherenceDeviation != null) {
        buffer.writeln('$bullet${l10n.mentorContextPlanAdherence(formatDecimal(adherenceDeviation.averageAdherence, _localeName, minFractionDigits: 1, maxFractionDigits: 1))}');
        if (adherenceDeviation.consecutiveLowDays > 0) {
          buffer.writeln('$bullet${l10n.mentorContextLowAdherence(adherenceDeviation.consecutiveLowDays)}');
        }
      }
    }

    if (_currentSyllabusContext.isNotEmpty) {
      // Vision §3.1: inject the current/active syllabus context so the LLM
      // can disambiguate which syllabus a student utterance refers to when
      // multiple syllabi are active.
      buffer.writeln('$bullet$_currentSyllabusContext');
      // Vision Next-Term §3.1: surface an explicit focus set mid-conversation
      // so the LLM knows the student deliberately chose this syllabus.
      if (_focusService?.hasFocus == true) {
        final focus = _focusService!;
        final focusLabel = focus.subjectTitle ?? focus.subjectId;
        final daysNote = focus.days != null ? ' for ${focus.days} days' : '';
        buffer.writeln('$bullet Syllabus focus explicitly set to "$focusLabel"$daysNote');
      }
      for (final goal in syllabusGoals) {
        buffer.writeln('  $bullet${l10n.mentorContextActiveSyllabus}: ${goal.subjectTitle}');
      }
    }

    if (daysSinceLastActivity >= 0) {
      buffer.writeln('$bullet${l10n.mentorContextDaysSinceActivity(daysSinceLastActivity)}');
      if (daysSinceLastActivity >= 3) {
        buffer.writeln(l10n.mentorContextWelcomeBack(daysSinceLastActivity));
      }
    }

    if (missedLessons.isNotEmpty) {
      buffer.writeln('$bullet Missed lessons: ${missedLessons.length}');
      for (final lesson in missedLessons.take(3)) {
        final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? l10n.unknown;
        buffer.writeln('  $bullet$title');
      }
    }

    if (plan != null && daysSinceLastActivity >= 3) {
      final metadata = plan.metadata ?? {};
      final lastRedistribution = metadata['lastRedistributionDate'] as String?;
      if (lastRedistribution != null) {
        buffer.writeln('$bullet Redistribution was applied for the absence.');
        final remainingDays = plan.dailyPlans.where((d) =>
          d.date.dateOnly.isAfter(DateTime.now().dateOnly) && !d.isRestDay
        ).length;
        final extraPerDay = (plan.targetMinutesPerDay * 0.5).ceil();
        if (remainingDays > 0) {
          buffer.writeln('$bullet Extra minutes per day: ${extraPerDay.toInt()} min over $remainingDays remaining days');
        }
      }
    }

    if (roadmaps.isNotEmpty) {
      final activeRoadmaps = roadmaps.where((r) => r.status == 'active').toList();
      if (activeRoadmaps.isNotEmpty) {
        buffer.writeln('$bullet${l10n.mentorContextActiveRoadmaps(activeRoadmaps.length)}');
        for (final roadmap in activeRoadmaps.take(2)) {
          final completedMilestones = roadmap.milestones.where((m) => m.isCompleted).length;
          final nearest = roadmap.milestones.where((m) => !m.isCompleted).firstOrNull;
          buffer.writeln('  $bullet${l10n.mentorContextRoadmapProgress(roadmap.goal, completedMilestones, roadmap.milestones.length)}');
          if (nearest != null) {
            buffer.writeln('    ${l10n.mentorContextNextMilestone(nearest.title, localizedDateTime(nearest.deadline, _localeName))}');
          }
        }
      }
    }

    if (pendingActions.isNotEmpty) {
      buffer.writeln('$bullet${l10n.mentorContextPendingActions(pendingActions.length)}');
      for (final action in pendingActions.take(3)) {
        buffer.writeln('  $bullet${l10n.mentorContextPendingActionItem(action.actionType, action.topicTitle)}');
      }
    }

    if (upcomingLessons.isNotEmpty) {
      final shownCount = upcomingLessons.length > 3 ? 3 : upcomingLessons.length;
      buffer.writeln('$bullet${l10n.mentorContextUpcomingLessons(shownCount)}');
      for (final lesson in upcomingLessons.take(3)) {
        final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? l10n.unknown;
        buffer.writeln('  $bullet${l10n.mentorContextLessonItem(title, localizedDateTime(lesson.startTime, _localeName), lesson.plannedDurationMinutes ?? 30)}');
      }
    }

    if (weakTopics.isNotEmpty) {
      buffer.writeln('$bullet${l10n.mentorContextWeakTopics}');
      for (final topic in weakTopics.take(5)) {
        buffer.writeln('  $bullet${l10n.mentorContextWeakTopicItem(topic.topicId, formatPercent(topic.accuracy * 100, _localeName, minFractionDigits: 0))}');
      }
    }

    // Vision Next-Term §3.1 (scenario_practice_review_context): inject a
    // bounded per-question accuracy snapshot of the student's most recent
    // incorrect answers, plus per-question variant availability, so the mentor
    // can cite specific wrong questions and offer variant remediation instead
    // of redirecting to UI navigation. Best-effort: a mastery/repo failure
    // leaves the prompt unchanged.
    final mistakeLines = await _buildMistakeLines(bullet);
    if (mistakeLines.isNotEmpty) {
      buffer.writeln('$bullet Recent mistakes (per-question accuracy):');
      for (final line in mistakeLines) {
        buffer.writeln(line);
      }
    }

    if (todayMinutes > 0) {
      buffer.writeln('$bullet${l10n.mentorContextStudyTimeToday(todayMinutes)}');
      if (dailyCap > 0 && todayMinutes > dailyCap) {
        buffer.writeln('$bullet${l10n.mentorContextCapExceeded(dailyCap, todayMinutes - dailyCap)}');
      } else if (dailyCap > 0) {
        buffer.writeln('$bullet${l10n.mentorContextCapRemaining(dailyCap, dailyCap - todayMinutes)}');
      }
    }

    // Vision Next-Term §4.3 / §3.1: inject a concise device/system-status line so
    // the mentor LLM can proactively advise on offline, battery, or CPU state
    // (e.g. "I see you're offline — I'll switch to local Ollama" /
    // "heavy prep deferred under load"). Omitted when no monitor is available
    // (web / fallback) so existing context is untouched.
    if (_systemMonitor != null) {
      buffer.writeln('$bullet${_buildDeviceStatusLine()}');
    }

    // Vision Next-Term §3.1 (scenario_provider_config): inject the active LLM
    // provider and backup/failover status so the mentor LLM can reason about
    // provider status ("I see you're on OpenRouter — switch to Ollama?") rather
    // than guessing. Omitted when no config is available so existing context is
    // untouched. LLM-facing: invariant English per AGENTS.md i18n convention
    // (prompt context lines, like the device-status line above).
    if (_llmConfig != null) {
      buffer.writeln('$bullet${_buildProviderStatusLine()}');
    }

    if (consecutiveDays >= 1 && todayMinutes == 0) {
      // Streak at risk: student has a streak but hasn't studied today.
      // Inject the at-risk directive so the LLM can proactively nudge
      // (Vision Next-Term §3.1 scenario audit: streak-risk context injection).
      buffer.writeln('$bullet${l10n.mentorContextStreakAtRisk(consecutiveDays)}');
    } else if (consecutiveDays >= 7) {
      buffer.writeln('$bullet${l10n.mentorContextStreak(consecutiveDays)}');
    } else if (consecutiveDays >= 3) {
      buffer.writeln('$bullet${l10n.mentorContextStreakGood(consecutiveDays)}');
    }

    final recentResult = await _sessionRepository.getByDate(DateTime.now());
    if (recentResult.isSuccess) {
      final todaySessions = recentResult.data!;
      if (todaySessions.isNotEmpty) {
        buffer.writeln('$bullet${l10n.mentorContextSessionsToday(todaySessions.length)}');
        final lateNight = todaySessions.where((s) => s.startTime.hour >= lateNightHour).toList();
        if (lateNight.isNotEmpty) {
          buffer.writeln('$bullet${l10n.mentorContextLateNightWarning(lateNight.length)}');
        }
      }
    }

    if (_learningAnalyticsService != null) {
      final insightsResult = await _learningAnalyticsService.getLearningInsights(_plannerService.studentId);
      if (insightsResult.isSuccess && insightsResult.data != null) {
        final insights = insightsResult.data!;
        final hasData = insights['hasData'] as bool? ?? false;
        if (hasData) {
          buffer.writeln('$bullet Learning Method Insights:');
          final preferred = insights['preferredBlockType'] as String? ?? 'exercise';
          buffer.writeln('  $bullet Preferred content type: $preferred');
          final optimalMinutes = insights['optimalSessionMinutes'] as int? ?? 25;
          buffer.writeln('  $bullet Optimal session length: $optimalMinutes minutes');
          final prefersVisual = insights['prefersVisual'] as bool? ?? false;
          buffer.writeln('  $bullet Prefers visual explanations: $prefersVisual');
          final srEffectiveness = insights['srEffectiveness'] as double? ?? 0.0;
          if (srEffectiveness > 0.5) {
            buffer.writeln('  $bullet Spaced repetition is highly effective');
          }
        }
      }
    }

      return Result.success(buffer.toString());
    } catch (e, stack) {
      _logger.w('Failed to build mentor context prompt', e, stack);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> loadUpcomingLessons() async {
    return _plannerService.getScheduledLessons();
  }

  Future<Result<List<MasteryState>>> _loadWeakTopics() async {
    return Result.capture(() async {
      final result = await _masteryService.getWeakTopics(_plannerService.studentId);
      return result.isSuccess ? result.data! : [];
    }, context: '_loadWeakTopics');
  }

  /// Builds a bounded, per-question accuracy snapshot of the student's most
  /// recently-incorrect questions for the mentor context prompt
  /// (Vision Next-Term §3.1 scenario_practice_review_context).
  ///
  /// Each emitted line states the question ID, an optional concept label
  /// (resolved from [_questionRepository] when present), accuracy,
  /// correct/total counts, and how many variants have already been generated
  /// for that question's family. Returns an empty list when at-risk questions
  /// are unavailable so the prompt is left unchanged.
  Future<List<String>> _buildMistakeLines(String bullet) async {
    final result = await _masteryService.getAtRiskQuestions(
      _plannerService.studentId,
    );
    if (result.isFailure || result.data == null) return const <String>[];

    final recent = result.data!
        .where((s) => s.incorrectCount > 0 && s.totalAttempts > 0)
        .toList()
      ..sort((a, b) {
        final da = a.lastIncorrect ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final db = b.lastIncorrect ?? DateTime.fromMicrosecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    final lines = <String>[];
    for (final s in recent.take(_maxRecentMistakes)) {
      String? conceptLabel;
      int variantCount = 0;
      if (_questionRepository != null) {
        final qResult = await _questionRepository.get(s.questionId);
        if (qResult.isSuccess && qResult.data != null) {
          final q = qResult.data!;
          conceptLabel = q.topic?.isNotEmpty == true
              ? q.topic
              : (q.topicId.isNotEmpty ? q.topicId : null);
          variantCount = q.variantIds.length;
        }
      }
      final total = s.correctCount + s.incorrectCount;
      final accPct = formatPercent(
        s.accuracy * 100,
        _localeName,
        minFractionDigits: 0,
      );
      final conceptPart = conceptLabel != null ? ' ($conceptLabel)' : '';
      final variantPart = variantCount > 0
          ? ' — $variantCount variant(s) already generated'
          : '';
      lines.add('  $bullet${s.questionId}$conceptPart: $accPct accuracy, '
          '${s.correctCount}/$total correct, ${s.incorrectCount} wrong$variantPart');
    }
    return lines;
  }

  Future<Result<PersonalLearningPlan?>> _loadPlan() async {
    return _plannerService.loadExistingPlan();
  }

  Future<Result<List<RoadmapModel>>> _loadRoadmaps() async {
    return _plannerService.loadRoadmaps();
  }

  /// Loads the active learning plan's syllabus goals (multi-syllabus support).
  Future<Result<List<SyllabusGoal>>> loadSyllabusGoals() async {
    final plan = (await _loadPlan()).data;
    return Result.success(plan?.syllabusGoals ?? []);
  }

  /// Builds [_currentSyllabusContext] — a structured line that identifies the
  /// syllabus the student is most likely discussing, enabling syllabus-scoped
  /// agent tool calls (Vision §3.1 tool/context audit).
  ///
  /// Resolution order:
  /// 0. If the [SwitchSyllabusFocusTool] has set an explicit focus, that
  ///    goal takes priority over implicit resolution.
  /// 1. If upcoming scheduled lessons map to a syllabus goal, that goal is the
  ///    active syllabus.
  /// 2. If there is exactly one syllabus goal, it is the active syllabus.
  /// 3. If multiple syllabi are active with no upcoming lesson to pin one,
  ///    surface an ambiguity notice so the LLM can ask the student to
  ///    disambiguate.
  void buildSyllabusContext(
    List<SyllabusGoal> goals,
    List<Session> upcomingLessons,
    AppLocalizations l10n,
  ) {
    if (goals.isEmpty) {
      _currentSyllabusContext = '';
      return;
    }

    // Vision Next-Term §3.1: honor an explicit syllabus focus set by the
    // switch_syllabus_focus tool over implicit (upcoming-lesson) resolution.
    if (_focusService?.hasFocus == true) {
      final focusSubjectId = _focusService!.subjectId;
      final focusedGoal = goals.firstWhere(
        (g) => g.subjectId == focusSubjectId,
        orElse: () => goals.first,
      );
      _currentSyllabusContext =
          '${l10n.mentorContextActiveSyllabus}: ${focusedGoal.subjectTitle}';
      return;
    }

    final upcomingSubjectIds = upcomingLessons
        .map((s) => s.subjectId)
        .whereType<String>()
        .toSet();

    SyllabusGoal? activeGoal;
    if (upcomingSubjectIds.isNotEmpty) {
      activeGoal = goals.firstWhere(
        (g) => upcomingSubjectIds.contains(g.subjectId),
        orElse: () => goals.first,
      );
    } else if (goals.length == 1) {
      activeGoal = goals.first;
    }

    if (activeGoal != null) {
      _currentSyllabusContext =
          '${l10n.mentorContextActiveSyllabus}: ${activeGoal.subjectTitle}';
    } else {
      // Multiple syllabi active, no upcoming lesson to pin a current one.
      final titles = goals.map((g) => g.subjectTitle).join(', ');
      _currentSyllabusContext =
          '${l10n.mentorContextSyllabusGoals}: $titles';
    }
  }

  Future<Result<List<PendingActionModel>>> _loadPendingActions() async {
    return _plannerService.loadPendingActions();
  }

  Future<Result<AdherenceDeviation?>> _loadAdherence() async {
    return _plannerService.planOrchestrator.checkAdherence(_plannerService.studentId);
  }

  Future<Result<List<Session>>> _loadMissedLessons() async {
    return _plannerService.getMissedLessons();
  }

  int _getPlanDay(PersonalLearningPlan plan) {
    final now = DateTime.now();
    final today = now.dateOnly;
    for (final day in plan.dailyPlans) {
      final dDay = day.date.dateOnly;
      if (dDay == today) return day.dayNumber;
    }
    return 0;
  }

  Future<int> _getTodayStudyMinutes() async {
    final result = await _sessionRepository.getTodayDurationMs();
    return result.isSuccess ? (result.data! ~/ msPerMinute) : 0;
  }

  /// Builds a single concise, LLM-facing line summarising device/system state
  /// (Vision Next-Term §4.3) so the mentor can reason about offline/battery/CPU
  /// constraints. Only fields with a known value are included; unknown readings
  /// degrade to a healthy signal by design (see [SystemMonitorService]).
  String _buildDeviceStatusLine() {
    final monitor = _systemMonitor!;
    final parts = <String>[];
    if (monitor.isCharging) {
      parts.add('plugged in');
    } else if (monitor.batteryLevel >= 0) {
      parts.add('battery ${monitor.batteryLevel}%');
    } else {
      parts.add('on battery');
    }
    if (monitor.cpuLoad >= 0) {
      parts.add('CPU ${(monitor.cpuLoad * 100).round()}%');
    }
    if (monitor.isBatterySaver) {
      parts.add('battery-saver on');
    }
    if (monitor.networkType != null) {
      parts.add(monitor.networkType!);
    }
    final prepNote = monitor.canRunHeavyPrepNow
        ? 'heavy prep available'
        : 'heavy prep deferred';
    return 'Device status: ${parts.join(', ')} — $prepNote';
  }

  /// Human-readable label for an [LlmProvider] (LLM-facing context line).
  static String _providerLabel(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.openRouter:
        return 'OpenRouter';
      case LlmProvider.ollama:
        return 'Ollama';
      case LlmProvider.openAI:
        return 'OpenAI';
      case LlmProvider.custom:
        return 'Custom';
    }
  }

  /// Builds a concise LLM-provider status line for the mentor context prompt
  /// (Vision Next-Term §3.1 scenario audit). Surfaces the active provider and
  /// whether a backup/failover provider is configured so the LLM can advise on
  /// provider status and failover instead of guessing. LLM-facing: invariant
  /// English per AGENTS.md i18n convention.
  String _buildProviderStatusLine() {
    final config = _llmConfig!;
    final active = _providerLabel(config.provider);
    if (config.hasBackup && config.backupProvider != null) {
      final backup = _providerLabel(config.backupProvider!);
      return 'LLM provider: $active. Backup: $backup configured.';
    }
    return 'LLM provider: $active. Backup: not configured.';
  }

  Future<Result<int>> _getConsecutiveStudyDays() async {
    return _sessionRepository.getConsecutiveStudyDays();
  }

  /// Queries the ingestion state (uploaded sources) for the current student.
  ///
  /// Returns `null` when the source repository is unavailable or a read fails
  /// (so the caller leaves the prompt unchanged, matching the prior behaviour
  /// where an unavailable repo injected nothing). Returns an empty list when
  /// the student has no uploaded materials, and a populated list otherwise —
  /// letting the prompt surface per-syllabus titles instead of just a count.
  Future<List<Source>?> _getSourceInventory() async {
    if (_sourceRepository == null) return null;
    final result = await _sourceRepository.getByStudent(_plannerService.studentId);
    if (result.isFailure) {
      _logger.w('Failed to load sources for mentor context', result.error);
      return null;
    }
    return result.data ?? [];
  }

  /// Appends a bounded, per-syllabus inventory of uploaded sources to the
  /// mentor prompt so the LLM stays aware of content added off-period.
  ///
  /// Sources are grouped by `subjectId` (mapped to the syllabus goal's
  /// `subjectTitle`), with at most [_maxSourceTitlesPerSubject] titles shown
  /// per syllabus plus an overflow count ("+N more"). Sources without a
  /// `subjectId` are reported as an unattributed count.
  static const int _maxSourceTitlesPerSubject = 3;

  void _appendSourceInventory(
    StringBuffer buffer,
    List<Source> sources,
    List<SyllabusGoal> syllabusGoals,
    String bullet,
  ) {
    final subjectTitleById = <String, String>{};
    for (final goal in syllabusGoals) {
      if (goal.subjectId.isNotEmpty) {
        subjectTitleById[goal.subjectId] = goal.subjectTitle;
      }
    }

    // Group sources by subject; keep unattributed sources separate.
    final bySubject = <String, List<Source>>{};
    final unattributed = <Source>[];
    for (final source in sources) {
      if (source.subjectId.isNotEmpty) {
        bySubject.putIfAbsent(source.subjectId, () => []).add(source);
      } else {
        unattributed.add(source);
      }
    }

    buffer.writeln('${bullet}Uploaded study materials (${sources.length}):');
    for (final entry in bySubject.entries) {
      final subjectTitle = subjectTitleById[entry.key] ?? entry.key;
      final list = entry.value;
      buffer.writeln('  $bullet$subjectTitle: ${list.length}');
      for (final source in list.take(_maxSourceTitlesPerSubject)) {
        buffer.writeln('    $bullet${source.title}');
      }
      if (list.length > _maxSourceTitlesPerSubject) {
        buffer.writeln('    $bullet+${list.length - _maxSourceTitlesPerSubject} more');
      }
    }
    if (unattributed.isNotEmpty) {
      buffer.writeln('  ${bullet}Unattributed materials: ${unattributed.length}');
    }
  }
}
