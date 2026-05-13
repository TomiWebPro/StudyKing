import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';

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
    home: SessionHistoryScreen(sessionRepository: repository),
  );
}

void main() {
  group('SessionHistoryScreen', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows empty state and filter controls', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Session History'), findsOneWidget);
      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Start studying to track your progress'), findsOneWidget);
      expect(find.text('Filter by Date'), findsOneWidget);
      expect(find.text('Filter by Subject'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0m'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.byIcon(Icons.history), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('renders sessions list and summary values from repository', (tester) async {
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
          questionsAnswered: 0,
          correctAnswers: 0,
          timeSpentMs: 1200000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('50m 0s'), findsOneWidget);
      expect(find.text('25m 0s'), findsOneWidget);
      expect(find.text('Correct: 8/10'), findsOneWidget);
    });

    testWidgets('filters by subject and clears filters', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          timeSpentMs: 600000,
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

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('math'));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNWidgets(2));
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('dismiss delete supports cancel, delete, and undo', (tester) async {
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

      final tile = find.byKey(const Key('s1'));
      await tester.drag(tile, const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete Session'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('s1')), findsOneWidget);

      await tester.drag(find.byKey(const Key('s1')), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Session deleted'), findsOneWidget);
      expect(find.byKey(const Key('s1')), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('s1')), findsOneWidget);
    });

    testWidgets('subject filter clear action keeps sessions unchanged', (tester) async {
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
      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
    });
  });
}
