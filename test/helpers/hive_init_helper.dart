import 'dart:io';

import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_initializer.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/planner/data/repositories/advisor_suggestions_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/student_availability_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_context_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';

/// Initializes Hive for integration/widget tests by registering adapters and
/// opening every repository box with its correct (typed) adapter. This mirrors
/// what [HiveInitializer.initialize] does, but opens boxes through the
/// repositories themselves so typed access never hits a dynamic box.
Future<void> initializeHiveForIntegrationTests() async {
  try {
    Hive.init(Directory.systemTemp.createTempSync('studyking_int_').path);
  } catch (_) {
    // Hive may already be initialized by the global test bootstrap.
  }
  HiveInitializer.registerAdapters();

  final repositories = <Object>[
    SubjectRepository(),
    TopicRepository(),
    QuestionRepository(),
    SourceRepository(),
    AttemptRepository(),
    LessonRepository(),
    LessonFeedbackRepository(),
    PlanRepository(),
    SessionRepository(),
    PlanAdherenceRepository(),
    RoadmapRepository(),
    AdvisorSuggestionsRepository(),
    PendingActionRepository(),
    StudentAvailabilityRepository(),
    PlanContextRepository(),
    ConversationRepository(),
    TutorSessionRepository(),
    LessonRecapRepository(),
    QuestionEvaluationRepository(),
    MasteryStateRepository(),
    QuestionMasteryStateRepository(),
    TopicDependencyRepository(),
    EngagementNudgeRepository(),
    BadgeRepository(),
    ConceptMapRepository(),
    FlashcardRepository(),
    StudyGuideRepository(),
  ];

  for (final repo in repositories) {
    try {
      // Each repository exposes an `init()` that opens its typed box.
      // ignore: avoid_dynamic_calls
      await (repo as dynamic).init();
    } catch (_) {
      // Some repositories may not require initialization in a given test;
      // ignore individual failures so the shared box set is still opened.
    }
  }
}
