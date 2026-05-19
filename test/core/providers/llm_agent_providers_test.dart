import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/providers/llm_agent_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

MasteryGraphService _buildMasteryGraphService() {
  return MasteryGraphService(
    masteryStateRepo: MasteryStateRepository(),
    questionMasteryRepo: QuestionMasteryStateRepository(),
    topicDependencyRepo: TopicDependencyRepository(),
    questionEvaluationRepo: QuestionEvaluationRepository(),
  );
}

PersonalLearningPlanService _buildPlanService(MasteryGraphService mastery) {
  return PersonalLearningPlanService(
    masteryService: mastery,
    repository: MasteryGraphRepository(),
    topicRepository: TopicRepository(),
    planRepository: PlanRepository(),
    adherenceRepository: PlanAdherenceRepository(),
    roadmapRepository: RoadmapRepository(),
    questionRepository: QuestionRepository(),
  );
}

PlannerService _buildPlannerService(MasteryGraphService mastery) {
  final planService = _buildPlanService(mastery);
  return PlannerService(
    planRepo: PlanRepository(),
    masteryService: mastery,
    topicRepository: TopicRepository(),
    roadmapRepo: RoadmapRepository(),
    planService: planService,
    sessionRepo: SessionRepository(),
    pendingActionRepo: PendingActionRepository(),
    planOrchestrator: PlanAdherenceOrchestrator(
      adherenceRepository: PlanAdherenceRepository(),
      planRepository: PlanRepository(),
      planService: planService,
      masteryService: mastery,
    ),
    syllabusResolver: SyllabusResolver(),
    adherenceRepo: PlanAdherenceRepository(),
  );
}

StudyProgressTracker _buildProgressTracker(MasteryGraphService mastery) {
  return StudyProgressTracker(
    attemptRepo: AttemptRepository(),
    masteryService: mastery,
    sessionRepo: SessionRepository(),
    l10n: lookupAppLocalizations(const Locale('en')),
  );
}

LessonAgentService _buildLessonAgentService() {
  return LessonAgentService(
    llmService: LlmService(
      config: LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'test-key',
      ),
    ),
    modelId: 'test-model',
    lessonRepository: LessonRepository(),
    database: DatabaseService(
      topicRepository: TopicRepository(),
      questionRepository: QuestionRepository(),
      attemptRepository: AttemptRepository(),
      lessonRepository: LessonRepository(),
      sessionRepository: SessionRepository(),
      subjectRepository: SubjectRepository(),
      conversationRepository: ConversationRepository(),
      tutorSessionRepository: TutorSessionRepository(),
    ),
  );
}

ProviderContainer _createContainer({
  String apiKey = '',
}) {
  final mastery = _buildMasteryGraphService();
  return ProviderContainer(
    overrides: [
      plannerServiceProvider.overrideWith((ref) => _buildPlannerService(mastery)),
      questionRepositoryProvider.overrideWith((ref) => QuestionRepository()),
      mentorProgressTrackerProvider.overrideWith(
        (ref) => _buildProgressTracker(mastery),
      ),
      masteryGraphServiceProvider.overrideWith((ref) => mastery),
      lessonAgentServiceProvider.overrideWith((ref) => _buildLessonAgentService()),
      llmServiceProvider.overrideWith(
        (ref) => LlmService(
          config: LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: apiKey,
          ),
        ),
      ),
      mentorModelIdProvider.overrideWith((ref) => 'test-model'),
      llmTaskManagerProvider.overrideWith((ref) => LlmTaskManager()),
    ],
  );
}

void main() {
  group('llmAgentToolsProvider', () {
    test('returns list of AgentTool instances', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      expect(tools, isA<List<AgentTool>>());
      expect(tools.length, greaterThanOrEqualTo(6));
      expect(tools.every((t) => t.name.isNotEmpty), isTrue);
    });

    test('tools have unique names', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      final names = tools.map((t) => t.name).toSet();
      expect(names.length, equals(tools.length));
    });
  });

  group('llmAgentProvider', () {
    test('returns null when apiKey is empty', () {
      final container = _createContainer(apiKey: '');
      addTearDown(() => container.dispose());

      final agent = container.read(llmAgentProvider('student-1'));
      expect(agent, isNull);
    });

    test('returns LlmAgent when apiKey is provided', () {
      final container = _createContainer(apiKey: 'test-key');
      addTearDown(() => container.dispose());

      final agent = container.read(llmAgentProvider('student-1'));
      expect(agent, isA<LlmAgent>());
      expect(agent!.toolRegistry.toolNames.length, greaterThanOrEqualTo(6));
    });

    test('different student IDs produce different agents', () {
      final container = _createContainer(apiKey: 'test-key');
      addTearDown(() => container.dispose());

      final agent1 = container.read(llmAgentProvider('student-1'));
      final agent2 = container.read(llmAgentProvider('student-2'));
      expect(agent1, isA<LlmAgent>());
      expect(agent2, isA<LlmAgent>());
    });
  });
}
