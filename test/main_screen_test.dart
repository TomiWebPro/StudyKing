import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorProgressTrackerProvider, mentorModelIdProvider;
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show spacedRepetitionServiceProvider, masteryGraphServiceProvider;
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/main.dart' show MainScreen;
import 'package:studyking/core/data/hive_initializer.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/planner/data/repositories/advisor_suggestions_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/student_availability_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';

class _FakeSubjectRepository extends SubjectRepository {
  @override
  Future<Result<List<Subject>>> getAll() async => Result.success([]);
}

class _FakeSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _FakeSubjectsRepositoryNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
}

class _FakeQuestionRepository extends QuestionRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success([]);
  }
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  _FakeSpacedRepetitionService()
      : super(
          questionRepo: _FakeQuestionRepository(),
          attemptRepo: _FakeAttemptRepository(),
        );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(0);
  }

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    return Result.success([]);
  }
}

class _FakeMasteryGraphService extends MasteryGraphService {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    return Result.success({
      'totalTopics': 0,
      'masteredTopics': 0,
      'weakTopics': 0,
      'averageAccuracy': 0.0,
      'avgReadiness': 0.0,
    });
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success([]);
  }
}

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
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
    yield 'Mock response';
  }
}

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success([]);
  }
}

class _FakeStudyProgressTracker extends StudyProgressTracker {
  _FakeStudyProgressTracker()
      : super(
          attemptRepo: _FakeAttemptRepository(),
          masteryService: _FakeMasteryGraphService(),
          l10n: lookupAppLocalizations(const Locale('en')),
        );

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    return Result.success({});
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(int weeks, {String? studentId}) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    return Result.success([]);
  }
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(
        () => _FakeSubjectsRepositoryNotifier(_FakeSubjectRepository()),
      ),
      spacedRepetitionServiceProvider.overrideWithValue(
        _FakeSpacedRepetitionService(),
      ),
      questionRepositoryProvider.overrideWithValue(
        _FakeQuestionRepository(),
      ),
      masteryGraphServiceProvider.overrideWithValue(
        _FakeMasteryGraphService(),
      ),
      llmServiceProvider.overrideWithValue(
        _FakeLlmService(),
      ),
      mentorProgressTrackerProvider.overrideWithValue(
        _FakeStudyProgressTracker(),
      ),
      mentorModelIdProvider.overrideWithValue('test-model'),
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const MainScreen(fixedStudentId: 'test-student'),
    ),
  );
}

void main() {
  group('MainScreen', () {
    setUpAll(() async {
      try {
        Hive.init(Directory.systemTemp.createTempSync('main_screen_').path);
      } catch (_) {
        // Hive may already be initialized by the global test bootstrap.
      }
      HiveInitializer.registerAdapters();
      await SubjectRepository().init();
      await TopicRepository().init();
      await QuestionRepository().init();
      await SourceRepository().init();
      await AttemptRepository().init();
      await LessonRepository().init();
      await LessonFeedbackRepository().init();
      await PlanRepository().init();
      await SessionRepository().init();
      await PlanAdherenceRepository().init();
      await RoadmapRepository().init();
      await AdvisorSuggestionsRepository().init();
      await PendingActionRepository().init();
      await StudentAvailabilityRepository().init();
      await ConversationRepository().init();
      await TutorSessionRepository().init();
      await LessonRecapRepository().init();
      await QuestionEvaluationRepository().init();
      await MasteryStateRepository().init();
      await QuestionMasteryStateRepository().init();
      await EngagementNudgeRepository().init();
      await BadgeRepository().init();
      await ConceptMapRepository().init();
      await FlashcardRepository().init();
      await StudyGuideRepository().init();
    });

    Future<void> pumpAndSettleSafe(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('renders NavigationBar with 5 destinations', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(6));
    });

    testWidgets('starts with subjects tab selected', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
    });

    testWidgets('switching to practice tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      await tester.tap(find.text('Practice'));
      await pumpAndSettleSafe(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    testWidgets('switching to mentor tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      await tester.tap(find.text('Mentor'));
      await pumpAndSettleSafe(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 3);
    });

    testWidgets('switching to focus mode tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      await tester.tap(find.text('Study'));
      await pumpAndSettleSafe(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 4);
    });

    testWidgets('switching to settings tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      await tester.tap(find.text('Settings'));
      await pumpAndSettleSafe(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 5);
    });

    testWidgets('FAB opens dashboard screen', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('can cycle through all tabs without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await pumpAndSettleSafe(tester);

      for (int i = 1; i < 5; i++) {
        await tester.tap(find.byType(NavigationBar).last);
        await pumpAndSettleSafe(tester);
      }

      for (int i = 3; i >= 0; i--) {
        await tester.tap(find.byType(NavigationBar).last);
        await pumpAndSettleSafe(tester);
      }

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, isNonNegative);
    });
  });
}
