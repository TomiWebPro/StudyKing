import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_stats_tab.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions;
  final bool shouldThrow;

  _FakeSessionRepository(this._sessions, {this.shouldThrow = false});

  @override
  Future<Result<List<Session>>> getAll() async {
    if (shouldThrow) throw Exception('test error');
    return Result.success(_sessions);
  }
}

class _FakeTopicRepository extends TopicRepository {
  final List<Topic> _topics;

  _FakeTopicRepository([this._topics = const []]);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async =>
      Result.success(_topics.where((t) => t.subjectId == subjectId).toList());
}

class _FakeMasteryStateRepository extends MasteryStateRepository {
  final List<MasteryState> _states;

  _FakeMasteryStateRepository([this._states = const []]);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async =>
      Result.success(_states.where((s) => s.studentId == studentId).toList());
}

class _FakeStudentIdService extends StudentIdService {
  @override
  Future<void> init() async {}

  @override
  Result<String> getStudentId() => Result.success('test-student-id');
}

SubjectStatsTab _createTab(
  String subjectId,
  SessionRepository repo, {
  List<Topic> topics = const [],
  List<MasteryState> masteryStates = const [],
}) {
  return SubjectStatsTab(
    subjectId: subjectId,
    sessionRepository: repo,
    topicRepository: _FakeTopicRepository(topics),
    masteryStateRepository: _FakeMasteryStateRepository(masteryStates),
    studentIdService: _FakeStudentIdService(),
  );
}

Session _session({
  required String id,
  required String subjectId,
  int questionsAnswered = 10,
  int correctAnswers = 8,
  int timeSpentMs = 3600000,
}) {
  return Session(
    id: id,
    studentId: 'student-1',
    subjectId: subjectId,
    type: SessionType.practice,
    startTime: DateTime(2024, 6, 15, 10, 30),
    questionsAnswered: questionsAnswered,
    correctAnswers: correctAnswers,
    actualDurationMs: timeSpentMs,
    completed: true,
    createdAt: DateTime(2024, 6, 15, 10, 30),
  );
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Topic _topic(String id, String subjectId) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: 'Topic $id',
    description: 'description',
    syllabusText: 'syllabus',
  );
}

MasteryState _masteryState({
  required String studentId,
  required String topicId,
  MasteryLevel masteryLevel = MasteryLevel.novice,
}) {
  final now = DateTime(2024, 6, 15);
  return MasteryState(
    studentId: studentId,
    topicId: topicId,
    lastAttempt: now,
    lastUpdated: now,
    masteryLevel: masteryLevel,
  );
}

void main() {
  group('SubjectStatsTab', () {
    const testSubjectId = 'subject-1';

    testWidgets('shows stat cards with zeros when no sessions', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Practice Progress'), findsOneWidget);
      expect(find.text('Overall Score'), findsOneWidget);
      expect(
        find.text('Keep practicing to improve your score!'),
        findsOneWidget,
      );
    });

    testWidgets('shows error state when repo throws', (tester) async {
      final repo = _FakeSessionRepository([], shouldThrow: true);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('An error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('displays correct session count', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
        _session(id: 's2', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('displays correct accuracy percentage', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 8,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('80.0%'), findsAtLeast(1));
    });

    testWidgets('displays total questions count', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, questionsAnswered: 20),
        _session(id: 's2', subjectId: testSubjectId, questionsAnswered: 15),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('35'), findsOneWidget);
    });

    testWidgets('aggregates stats across multiple sessions', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 8,
          questionsAnswered: 10,
          timeSpentMs: 60000,
        ),
        _session(
          id: 's2',
          subjectId: testSubjectId,
          correctAnswers: 6,
          questionsAnswered: 10,
          timeSpentMs: 120000,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('70.0%'), findsAtLeast(1));
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('filters sessions by subjectId', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, questionsAnswered: 10),
        _session(id: 's2', subjectId: 'other-subject', questionsAnswered: 100),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders MetricCard widgets', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MetricCard), findsNWidgets(4));
    });

    testWidgets('shows LinearProgressIndicator with correct value', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 8,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(0.8, 0.01));
    });

    testWidgets('shows ProgressIndicator header', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice Progress'), findsOneWidget);
    });

    testWidgets('shows 100% accuracy for perfect score', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 10,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100.0%'), findsAtLeast(1));
    });

    testWidgets('shows 0.0% accuracy when no questions answered', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          questionsAnswered: 0,
          correctAnswers: 0,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0.0%'), findsAtLeast(1));
    });

    testWidgets('shows overall score section with percentage', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 8,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overall Score'), findsOneWidget);
      expect(
        find.text('Keep practicing to improve your score!'),
        findsOneWidget,
      );
    });

    testWidgets('shows correct total time formatting', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, timeSpentMs: 3600000),
        _session(id: 's2', subjectId: testSubjectId, timeSpentMs: 1800000),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows section header with Practice Progress', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.text('Practice Progress');
      expect(headerFinder, findsOneWidget);
    });

    testWidgets('shows 50.0% accuracy for medium score', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 5,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50.0%'), findsAtLeast(1));
    });

    testWidgets('shows 25.0% accuracy for low score', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 25,
          questionsAnswered: 100,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('25.0%'), findsAtLeast(1));
    });

    testWidgets('progress indicator shows 50% value for medium score', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 5,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(0.5, 0.01));
    });

    testWidgets('progress indicator shows 25% value for low score', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 25,
          questionsAnswered: 100,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(0.25, 0.01));
    });

    testWidgets('renders MetricCard with how_to_vote icon for sessions', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.how_to_vote), findsOneWidget);
      expect(find.byIcon(Icons.question_answer), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('MetricCard for accuracy displays star icon', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 8,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('section header renders with correct title styling', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      final headerText = tester.widget<Text>(find.text('Practice Progress'));
      expect(headerText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('overall score text shows bold font weight', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 8,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      final overallScoreText = tester.widget<Text>(find.text('80.0%').last);
      expect(overallScoreText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('shows 80.0% accuracy at boundary score (80/100)', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 80,
          questionsAnswered: 100,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('80.0%'), findsAtLeast(1));
    });

    testWidgets('shows 50.0% accuracy at boundary score (50/100)', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 50,
          questionsAnswered: 100,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50.0%'), findsAtLeast(1));
    });

    testWidgets('aggregates stats correctly with varied scores', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 10,
          questionsAnswered: 10,
          timeSpentMs: 1000,
        ),
        _session(
          id: 's2',
          subjectId: testSubjectId,
          correctAnswers: 0,
          questionsAnswered: 10,
          timeSpentMs: 2000,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('shows 0 sessions for sessions from other subjects only', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: 'other-subject'),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(testSubjectId, repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('0.0%'), findsAtLeast(1));
    });

    testWidgets('syllabus progress ignores mastered topics from other subjects', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(
            testSubjectId,
            repo,
            topics: [
              _topic('topic-1', testSubjectId),
              _topic('topic-2', testSubjectId),
            ],
            masteryStates: [
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'other-topic-1',
                masteryLevel: MasteryLevel.proficient,
              ),
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'other-topic-2',
                masteryLevel: MasteryLevel.expert,
              ),
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'topic-1',
                masteryLevel: MasteryLevel.developing,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mastered 0 / 2'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('syllabus progress counts proficient topics within the subject', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(
            testSubjectId,
            repo,
            topics: [
              _topic('topic-1', testSubjectId),
              _topic('topic-2', testSubjectId),
            ],
            masteryStates: [
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'topic-1',
                masteryLevel: MasteryLevel.proficient,
              ),
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'other-topic-1',
                masteryLevel: MasteryLevel.proficient,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mastered 1 / 2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('syllabus progress never exceeds 100% when other subjects have mastered topics', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(
        _buildTestApp(
          _createTab(
            testSubjectId,
            repo,
            topics: [
              _topic('topic-1', testSubjectId),
              _topic('topic-2', testSubjectId),
            ],
            masteryStates: [
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'topic-1',
                masteryLevel: MasteryLevel.proficient,
              ),
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'topic-2',
                masteryLevel: MasteryLevel.expert,
              ),
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'other-topic-1',
                masteryLevel: MasteryLevel.proficient,
              ),
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'other-topic-2',
                masteryLevel: MasteryLevel.proficient,
              ),
              _masteryState(
                studentId: 'test-student-id',
                topicId: 'other-topic-3',
                masteryLevel: MasteryLevel.expert,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mastered 2 / 2'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('250%'), findsNothing);
    });
  });
}
