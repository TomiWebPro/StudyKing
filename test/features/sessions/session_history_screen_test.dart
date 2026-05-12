import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeStudySessionRepository extends StudySessionRepository {
  _FakeStudySessionRepository({List<StudySession>? seed})
      : _sessions = List<StudySession>.from(seed ?? []);

  final List<StudySession> _sessions;

  @override
  Future<void> init() async {}

  @override
  Future<List<StudySession>> getAll() async => List<StudySession>.from(_sessions);

  @override
  Future<void> create(StudySession session) async {
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.add(session);
  }

  @override
  Future<void> delete(String id) async {
    _sessions.removeWhere((s) => s.id == id);
  }
}

Widget _buildTestApp(_FakeStudySessionRepository repository) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SessionHistoryScreen(sessionRepository: repository),
  );
}

void main() {
  group('SessionHistoryScreen - Loading and empty states', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Summary stats', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('displays correct summary for multiple sessions', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 10,
          correctAnswers: 8,
          timeSpentMs: 1800000,
        ),
        StudySession(
          id: 's2',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now.subtract(const Duration(days: 1)),
          questionsAnswered: 5,
          correctAnswers: 3,
          timeSpentMs: 1200000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
    });

    testWidgets('displays zero stats when no sessions', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsAtLeastNWidgets(1));
      expect(find.text('0m'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows correct average time', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          timeSpentMs: 1200000,
        ),
        StudySession(
          id: 's2',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now,
          timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('15m 0s'), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Date filter', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows date picker when filter by date is tapped', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('date filter shows correct date format in button', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.textContaining('/'), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Empty state messages', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows no sessions message when empty', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Start studying to track your progress'), findsOneWidget);
    });

    testWidgets('shows no results message when filters return empty', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('math'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('No sessions found for selected filters'), findsOneWidget);
      expect(find.text('Try adjusting your filters'), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - List rendering', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('displays session list with correct order', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now.subtract(const Duration(days: 1)),
          timeSpentMs: 1200000,
        ),
        StudySession(
          id: 's2',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now,
          timeSpentMs: 600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
    });

    testWidgets('displays session duration and questions info', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 15,
          correctAnswers: 12,
          timeSpentMs: 3600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('questions'), findsOneWidget);
      expect(find.textContaining('Correct'), findsOneWidget);
    });

    testWidgets('shows correct accuracy color for good score', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 10,
          correctAnswers: 8,
          timeSpentMs: 1800000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Correct: 8/10'), findsOneWidget);
    });

    testWidgets('shows correct accuracy color for poor score', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 10,
          correctAnswers: 3,
          timeSpentMs: 1800000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Correct: 3/10'), findsOneWidget);
    });

    testWidgets('hides questions info when no questions answered', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 0,
          correctAnswers: 0,
          timeSpentMs: 1800000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('No questions'), findsOneWidget);
      expect(find.textContaining('Correct'), findsNothing);
    });
  });

  group('SessionHistoryScreen - _formatTimeMinutes', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('calculates minutes from milliseconds correctly', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          timeSpentMs: 900000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('15m 0s'), findsAtLeastNWidgets(1));
    });
  });
}