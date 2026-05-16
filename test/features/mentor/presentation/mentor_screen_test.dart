import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/services/plan_adapter.dart' show AdherenceDeviation;
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakePlannerService extends PlannerService {
  @override
  Future<PersonalLearningPlan?> loadExistingPlan() async => null;
  @override
  Future<List<RoadmapModel>> loadRoadmaps() async => [];
  @override
  Future<List<PendingActionModel>> loadPendingActions() async => [];
  @override
  Future<List<TutorSession>> getScheduledLessons() async => [];
  @override
  Future<AdherenceDeviation?> checkAdherence() async => null;
  @override
  Future<bool> hasSchedulingConflict({required DateTime startTime, required int durationMinutes, String? excludeSessionId}) async => false;
  @override
  Future<bool> scheduleLesson({required String topicId, required String topicTitle, required String subjectId, required DateTime scheduledTime, int durationMinutes = 30}) async => true;
}

class _FakeNudgeRepo extends EngagementNudgeRepository {
  @override
  Future<void> init() async {}
  @override
  Future<void> create(EngagementNudgeModel nudge) async {}
  @override
  Future<List<EngagementNudgeModel>> getRecentByStudent(String studentId, {int limit = 10}) async => [];
  @override
  Future<int> getTodayCount(String studentId) async => 0;
}

class _FakeSessionRepo2 extends SessionRepository {
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

  FakeLlmService({this.shouldThrow = false, this.responseDelay})
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
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    if (shouldThrow) throw Exception('Simulated LLM error');
    if (responseDelay != null) await Future.delayed(responseDelay!);
    yield 'Mentor response';
  }
}

Widget _buildTestApp({LlmService? llmService}) {
  return ProviderScope(
    overrides: [
      llmServiceProvider.overrideWithValue(
        llmService ?? FakeLlmService(),
      ),
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
      plannerServiceProvider.overrideWithValue(FakePlannerService()),
      mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
      mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const MentorScreen(),
    ),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('mentor_hive_test_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('student_id')) {
      await Hive.deleteBoxFromDisk('student_id');
    }
  });

  group('MentorScreen', () {
    testWidgets('renders app bar with mentor greeting', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('AI Mentor'), findsWidgets);
    });

    testWidgets('renders chat input and send button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Ask your mentor anything...'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('shows progress report button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Progress Report'), findsOneWidget);
    });

    testWidgets('welcome message is shown after initialization', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('AI Mentor'), findsWidgets);
    });

    testWidgets('sending a message creates user and mentor chat bubbles', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Hello mentor'), findsOneWidget);
      expect(find.text('Mentor response'), findsOneWidget);
    });

    testWidgets('sending a message shows "You" sender label', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('You'), findsWidgets);
    });

    testWidgets('streamed response appears in chat after sending message', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Tell me something');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final mentorBubble = find.text('Mentor response');
      expect(mentorBubble, findsOneWidget);
    });

    testWidgets('sending indicator replaces send button while message is being sent', (tester) async {
      final delayedService = FakeLlmService(responseDelay: const Duration(seconds: 1));

      await tester.pumpWidget(_buildTestApp(llmService: delayedService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('error state renders error message when streaming fails', (tester) async {
      final errorService = FakeLlmService(shouldThrow: true);

      await tester.pumpWidget(_buildTestApp(llmService: errorService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Sorry, I encountered an error. Please try again.'), findsOneWidget);
    });

    testWidgets('message list uses ListView with scroll controller', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Message one');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Message two');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Message one'), findsOneWidget);
      expect(find.text('Message two'), findsOneWidget);
      expect(find.text('Mentor response'), findsNWidgets(2));
    });

    testWidgets('chat input has correct initial state', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('Ask your mentor anything...'), findsOneWidget);
    });
  });
}
