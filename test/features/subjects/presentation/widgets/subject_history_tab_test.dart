import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_history_tab.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions;
  final bool shouldThrow;

  _FakeSessionRepository(this._sessions, {this.shouldThrow = false});

  @override
  Future<List<Session>> getAll() async {
    if (shouldThrow) throw Exception('test error');
    return _sessions;
  }
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

void main() {
  group('SubjectHistoryTab', () {
    const testSubjectId = 'subject-1';

    testWidgets('shows empty state when no sessions', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Start studying to track your progress'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('shows empty state when repository throws', (tester) async {
      final repo = _FakeSessionRepository([], shouldThrow: true);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('shows session card with session number', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
    });

    testWidgets('shows score percentage on session card', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 8, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('shows correct/total fraction', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 7, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('7/10'), findsOneWidget);
    });

    testWidgets('shows check_circle icon for score >= 80', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 8, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows sticky_note_2 for score between 50 and 79', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 6, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows sticky_note_2 for score below 50', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 3, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('renders multiple sessions with sequential numbering', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
        _session(id: 's2', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('filters sessions by subjectId', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
        _session(id: 's2', subjectId: 'other-subject'),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsNothing);
    });

    testWidgets('calls onSessionTap when tapping a session', (tester) async {
      Session? tappedSession;
      final session = _session(id: 's1', subjectId: testSubjectId);
      final repo = _FakeSessionRepository([session]);

      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (s) => tappedSession = s,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Session 1'));
      await tester.pumpAndSettle();

      expect(tappedSession, isNotNull);
      expect(tappedSession!.id, 's1');
    });

    testWidgets('shows 0% when no questions answered', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 0, questionsAnswered: 0),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('does not show fraction when no questions', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, questionsAnswered: 0),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
    });

    testWidgets('shows date and duration in subtitle', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, timeSpentMs: 3600000),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('6/15/2024'), findsOneWidget);
    });

    testWidgets('shows correct score percentage for high score > 80', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 9, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('90%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows correct score percentage for medium score 50-79', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 6, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('60%'), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
    });

    testWidgets('shows correct score percentage for low score < 50', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 3, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectHistoryTab(
          subjectId: testSubjectId,
          onSessionTap: (_) {},
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('30%'), findsOneWidget);
    });
  });
}
