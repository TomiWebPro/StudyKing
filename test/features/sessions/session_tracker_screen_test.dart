import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/features/sessions/presentation/session_tracker_screen.dart';
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
}

Widget _buildTestApp(_FakeStudySessionRepository repository) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SessionTrackerScreen(sessionRepository: repository),
  );
}

void main() {
  group('SessionTrackerScreen', () {
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

    testWidgets('renders empty state after repository load', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Study Session Tracker'), findsOneWidget);
      expect(find.text('No Active Session'), findsOneWidget);
      expect(find.text('Tap start to begin tracking'), findsOneWidget);
      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('loads sessions and shows recent entries', (tester) async {
      final now = DateTime.now();
      final repo = _FakeStudySessionRepository(seed: [
        StudySession(
          id: 'a',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now.subtract(const Duration(hours: 2)),
          timeSpentMs: 1800000,
        ),
        StudySession(
          id: 'b',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now.subtract(const Duration(hours: 1)),
          timeSpentMs: 3600000,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
    });

    testWidgets('renders analytics and actions in default state', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('0s'), findsOneWidget);
      expect(find.text('0 days'), findsOneWidget);
      expect(find.text('Recent Sessions'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
      expect(find.text('Start your first session!'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('start button begins tracking session', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      expect(find.text('Current Session'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'End'), findsOneWidget);
    });

    testWidgets('end button shows session complete dialog', (tester) async {
      final repo = _FakeStudySessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'End'));
      await tester.pumpAndSettle();

      expect(find.text('Session Complete'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Questions Answered'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Correct Answers'), findsOneWidget);
    });
  });
}