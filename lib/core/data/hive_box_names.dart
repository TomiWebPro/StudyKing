class HiveBoxNames {
  HiveBoxNames._();

  static const String agentMemory = 'agent_memory';
  static const String answers = 'answers';
  static const String attempts = 'attempts';
  static const String badges = 'badges';
  static const String conversations = 'conversations';
  static const String engagementNudges = 'engagement_nudges';
  static const String focusSessions = 'focus_sessions';
  static const String learningPlans = 'learning_plans';
  static const String lessonBlocks = 'lessonBlocks';
  static const String lessons = 'lessons';
  static const String masteryStates = 'mastery_states';
  static const String masteryImprovementMetrics = 'mastery_improvement_metrics';
  static const String pendingActions = 'pending_actions';
  static const String planAdherence = 'plan_adherence';
  static const String planAdherenceMetrics = 'plan_adherence_metrics';
  static const String progress = 'progress';
  static const String questions = 'questions';
  static const String questionMasteryStates = 'question_mastery_states';
  static const String questionEvaluations = 'question_evaluations';
  static const String roadmaps = 'roadmaps';
  static const String sessions = 'sessions';
  static const String sessionsTyped = 'sessions_typed';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String sources = 'sources';
  static const String subjects = 'subjects';
  static const String tasks = 'tasks';
  static const String topicDependencies = 'topic_dependencies';
  static const String topics = 'topics';
  static const String tutorSessions = 'tutor_sessions';
  static const String studentAvailability = 'student_availability';
  static const String llmTasks = 'llm_tasks';
  static const String llmUsageRecords = 'llm_usage_records';
  static const String examResults = 'exam_results';
  static const String studentId = 'student_id';
  static const String dashboardLayoutPrefs = 'dashboard_layout_prefs';
  static const String dbVersion = 'db_version';

  /// All boxes included in a full backup (all boxes except those excluded).
  static List<String> get allBackupBoxes => [
        agentMemory,
        answers,
        attempts,
        badges,
        conversations,
        dashboardLayoutPrefs,
        dbVersion,
        engagementNudges,
        examResults,
        focusSessions,
        learningPlans,
        lessonBlocks,
        lessons,
        masteryStates,
        masteryImprovementMetrics,
        pendingActions,
        planAdherence,
        planAdherenceMetrics,
        progress,
        profile,
        questions,
        questionMasteryStates,
        questionEvaluations,
        roadmaps,
        sessions,
        sessionsTyped,
        settings,
        sources,
        studentAvailability,
        studentId,
        subjects,
        tasks,
        topicDependencies,
        topics,
        tutorSessions,
        llmTasks,
        llmUsageRecords,
      ];

  /// All boxes containing study data (excluding settings, profile, and internal metadata).
  static List<String> get allStudyDataBoxes => [
        agentMemory,
        answers,
        attempts,
        badges,
        conversations,
        engagementNudges,
        examResults,
        focusSessions,
        learningPlans,
        lessonBlocks,
        lessons,
        masteryStates,
        masteryImprovementMetrics,
        pendingActions,
        planAdherence,
        planAdherenceMetrics,
        progress,
        questions,
        questionMasteryStates,
        questionEvaluations,
        roadmaps,
        sessions,
        sessionsTyped,
        sources,
        subjects,
        tasks,
        topicDependencies,
        topics,
        tutorSessions,
        studentAvailability,
        llmTasks,
        llmUsageRecords,
        dashboardLayoutPrefs,
      ];
}
