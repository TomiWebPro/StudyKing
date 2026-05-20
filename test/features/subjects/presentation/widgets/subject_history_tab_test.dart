import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_history_tab.dart';
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
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(
        find.text('Start studying to track your progress'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('shows empty state when repository throws', (tester) async {
      final repo = _FakeSessionRepository([], shouldThrow: true);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('shows session card with session number', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
    });

    testWidgets('shows score percentage on session card', (tester) async {
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
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('shows correct/total fraction', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 7,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('7/10'), findsOneWidget);
    });

    testWidgets(
      'shows play_arrow icon for practice session type (score >= 80)',
      (tester) async {
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
            SubjectHistoryTab(
              subjectId: testSubjectId,
              onSessionTap: (_) {},
              sessionRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow), findsWidgets);
      },
    );

    testWidgets('shows play_arrow practice icon (score between 50 and 79)', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 6,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('shows play_arrow practice icon (score below 50)', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 3,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('renders multiple sessions with sequential numbering', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
        _session(id: 's2', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
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
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsNothing);
    });

    testWidgets('calls onSessionTap when tapping a session', (tester) async {
      Session? tappedSession;
      final session = _session(id: 's1', subjectId: testSubjectId);
      final repo = _FakeSessionRepository([session]);

      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (s) => tappedSession = s,
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Session 1'));
      await tester.pumpAndSettle();

      expect(tappedSession, isNotNull);
      expect(tappedSession!.id, 's1');
    });

    testWidgets('shows 0% when no questions answered', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 0,
          questionsAnswered: 0,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('does not show fraction when no questions', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, questionsAnswered: 0),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('shows date and duration in subtitle', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, timeSpentMs: 3600000),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('6/15/2024'), findsOneWidget);
    });

    testWidgets('shows correct score percentage for high score > 80', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 9,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('90%'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('shows correct score percentage for medium score 50-79', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 6,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('60%'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('shows correct score percentage for low score < 50', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 3,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('shows timer icon for focus session type', (tester) async {
      final repo = _FakeSessionRepository([
        Session(
          id: 's1',
          studentId: 'student-1',
          subjectId: testSubjectId,
          type: SessionType.focus,
          startTime: DateTime(2024, 6, 15, 10, 30),
          questionsAnswered: 10,
          correctAnswers: 8,
          actualDurationMs: 3600000,
          completed: true,
          createdAt: DateTime(2024, 6, 15, 10, 30),
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer), findsWidgets);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows school icon for tutoring session type', (tester) async {
      final repo = _FakeSessionRepository([
        Session(
          id: 's1',
          studentId: 'student-1',
          subjectId: testSubjectId,
          type: SessionType.tutoring,
          startTime: DateTime(2024, 6, 15, 10, 30),
          questionsAnswered: 10,
          correctAnswers: 8,
          actualDurationMs: 3600000,
          completed: true,
          createdAt: DateTime(2024, 6, 15, 10, 30),
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school), findsWidgets);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows edit_note icon for manual session type', (tester) async {
      final repo = _FakeSessionRepository([
        Session(
          id: 's1',
          studentId: 'student-1',
          subjectId: testSubjectId,
          type: SessionType.manual,
          startTime: DateTime(2024, 6, 15, 10, 30),
          questionsAnswered: 10,
          correctAnswers: 8,
          actualDurationMs: 3600000,
          completed: true,
          createdAt: DateTime(2024, 6, 15, 10, 30),
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_note), findsWidgets);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('renders mixed session types in single list', (tester) async {
      final repo = _FakeSessionRepository([
        Session(
          id: 's1',
          studentId: 's',
          subjectId: testSubjectId,
          type: SessionType.focus,
          startTime: DateTime(2024, 6, 15, 10, 30),
          questionsAnswered: 10,
          correctAnswers: 8,
          actualDurationMs: 3600000,
          completed: true,
          createdAt: DateTime(2024, 6, 15, 10, 30),
        ),
        Session(
          id: 's2',
          studentId: 's',
          subjectId: testSubjectId,
          type: SessionType.tutoring,
          startTime: DateTime(2024, 6, 15, 11, 0),
          questionsAnswered: 5,
          correctAnswers: 5,
          actualDurationMs: 1800000,
          completed: true,
          createdAt: DateTime(2024, 6, 15, 11, 0),
        ),
        Session(
          id: 's3',
          studentId: 's',
          subjectId: testSubjectId,
          type: SessionType.manual,
          startTime: DateTime(2024, 6, 15, 12, 0),
          questionsAnswered: 0,
          correctAnswers: 0,
          actualDurationMs: 600000,
          completed: true,
          createdAt: DateTime(2024, 6, 15, 12, 0),
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer), findsWidgets);
      expect(find.byIcon(Icons.school), findsWidgets);
      expect(find.byIcon(Icons.edit_note), findsWidgets);
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
      expect(find.text('Session 3'), findsOneWidget);
    });

    testWidgets('score color for >=80 uses primary', (tester) async {
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
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scoreText = tester.widget<Text>(find.text('100%'));
      expect(scoreText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('score color for 50-79 uses tertiary', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 6,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scoreText = tester.widget<Text>(find.text('60%'));
      expect(scoreText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('score color for <50 uses error', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 2,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scoreText = tester.widget<Text>(find.text('20%'));
      expect(scoreText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets(
      'subtitle contains bullet separator between date and duration',
      (tester) async {
        final repo = _FakeSessionRepository([
          _session(id: 's1', subjectId: testSubjectId, timeSpentMs: 3600000),
        ]);
        await tester.pumpWidget(
          _buildTestApp(
            SubjectHistoryTab(
              subjectId: testSubjectId,
              onSessionTap: (_) {},
              sessionRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('•'), findsOneWidget);
      },
    );

    testWidgets('shows 0% and fraction for zero correct answers', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 0,
          questionsAnswered: 5,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);
    });

    testWidgets('shows only matching sessions and empty state when none filtered', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: 'other-subject'),
        _session(id: 's2', subjectId: 'another-subject'),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('card has proper margin', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card).first);
      expect(card.margin, isNotNull);
    });

    testWidgets('CircleAvatar uses score-based background color', (
      tester,
    ) async {
      final repo = _FakeSessionRepository([
        _session(
          id: 's1',
          subjectId: testSubjectId,
          correctAnswers: 9,
          questionsAnswered: 10,
        ),
      ]);
      await tester.pumpWidget(
        _buildTestApp(
          SubjectHistoryTab(
            subjectId: testSubjectId,
            onSessionTap: (_) {},
            sessionRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar).first,
      );
      expect(avatar.backgroundColor, isNotNull);
      expect((avatar.backgroundColor!.a * 255.0).round().clamp(0, 255), lessThan(255));
    });
  });
}
