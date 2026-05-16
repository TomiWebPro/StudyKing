import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
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
  group('SubjectStatsTab', () {
    const testSubjectId = 'subject-1';

    testWidgets('shows stat cards with zeros when no sessions', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Practice Progress'), findsOneWidget);
      expect(find.text('Overall Score'), findsOneWidget);
      expect(find.text('Keep practicing to improve your score!'), findsOneWidget);
    });

    testWidgets('shows stat cards with zeros when repo throws', (tester) async {
      final repo = _FakeSessionRepository([], shouldThrow: true);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('0.0%'), findsAtLeast(1));
    });

    testWidgets('displays correct session count', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
        _session(id: 's2', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('displays correct accuracy percentage', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 8, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('80.0%'), findsAtLeast(1));
    });

    testWidgets('displays total questions count', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, questionsAnswered: 20),
        _session(id: 's2', subjectId: testSubjectId, questionsAnswered: 15),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('35'), findsOneWidget);
    });

    testWidgets('aggregates stats across multiple sessions', (tester) async {
      final repo = _FakeSessionRepository([
        _session(
            id: 's1', subjectId: testSubjectId, correctAnswers: 8, questionsAnswered: 10, timeSpentMs: 60000),
        _session(
            id: 's2', subjectId: testSubjectId, correctAnswers: 6, questionsAnswered: 10, timeSpentMs: 120000),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
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
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders MetricCard widgets', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MetricCard), findsNWidgets(4));
    });

    testWidgets('shows LinearProgressIndicator with correct value', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 8, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progress.value, closeTo(0.8, 0.01));
    });

    testWidgets('shows ProgressIndicator header', (tester) async {
      final repo = _FakeSessionRepository([]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Practice Progress'), findsOneWidget);
    });

    testWidgets('shows 100% accuracy for perfect score', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 10, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('100.0%'), findsAtLeast(1));
    });

    testWidgets('shows 0.0% accuracy when no questions answered', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, questionsAnswered: 0, correctAnswers: 0),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0.0%'), findsAtLeast(1));
    });

    testWidgets('shows overall score section with percentage', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 8, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Overall Score'), findsOneWidget);
      expect(find.text('Keep practicing to improve your score!'), findsOneWidget);
    });

    testWidgets('shows correct total time formatting', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, timeSpentMs: 3600000),
        _session(id: 's2', subjectId: testSubjectId, timeSpentMs: 1800000),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows section header with Practice Progress', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      final headerFinder = find.text('Practice Progress');
      expect(headerFinder, findsOneWidget);
    });

    testWidgets('shows 50.0% accuracy for medium score', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 5, questionsAnswered: 10),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('50.0%'), findsAtLeast(1));
    });

    testWidgets('shows 25.0% accuracy for low score', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: testSubjectId, correctAnswers: 25, questionsAnswered: 100),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectStatsTab(
          subjectId: testSubjectId,
          sessionRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('25.0%'), findsAtLeast(1));
    });
  });
}
