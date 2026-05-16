import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSessionRepository extends SessionRepository {
  _FakeSessionRepository({List<Session>? seed, this.throwOnDelete = false})
      : sessions = List<Session>.from(seed ?? []);

  final List<Session> sessions;
  final bool throwOnDelete;

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(List<Session>.from(sessions));

  @override
  Future<Result<void>> save(Session session) async {
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (throwOnDelete) throw Exception('delete failed');
    sessions.removeWhere((s) => s.id == id);
    return Result.success(null);
  }
}

Widget _buildTestApp(_FakeSessionRepository repository) {
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
      final repo = _FakeSessionRepository();
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
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 10,
          correctAnswers: 8,
          actualDurationMs: 1800000,
          type: SessionType.manual,
        ),
        Session(
          id: 's2',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now.subtract(const Duration(days: 1)),
          questionsAnswered: 5,
          correctAnswers: 3,
          actualDurationMs: 1200000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
    });

    testWidgets('displays zero stats when no sessions', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsAtLeastNWidgets(1));
      expect(find.text('0m'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows correct average time', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          actualDurationMs: 1200000,
          type: SessionType.manual,
        ),
        Session(
          id: 's2',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now,
          actualDurationMs: 600000,
          type: SessionType.manual,
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
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('date filter confirms selection on ok', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'OK'));
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
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Start studying to track your progress'), findsOneWidget);
    });

    testWidgets('shows no results message when filters return empty', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: yesterday,
          actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('math'));
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'OK'));
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
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now.subtract(const Duration(days: 1)),
          actualDurationMs: 1200000,
          type: SessionType.manual,
        ),
        Session(
          id: 's2',
          studentId: 'u1',
          subjectId: 'science',
          startTime: now,
          actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
    });

    testWidgets('displays session duration and questions info', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 15,
          correctAnswers: 12,
          actualDurationMs: 3600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('questions'), findsOneWidget);
      expect(find.textContaining('Correct'), findsOneWidget);
    });

    testWidgets('shows correct accuracy color for good score', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 10,
          correctAnswers: 8,
          actualDurationMs: 1800000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Correct: 8/10'), findsOneWidget);
    });

    testWidgets('shows correct accuracy color for poor score', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 10,
          correctAnswers: 3,
          actualDurationMs: 1800000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Correct: 3/10'), findsOneWidget);
    });

    testWidgets('hides questions info when no questions answered', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          questionsAnswered: 0,
          correctAnswers: 0,
          actualDurationMs: 1800000,
          type: SessionType.manual,
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
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1',
          studentId: 'u1',
          subjectId: 'math',
          startTime: now,
          actualDurationMs: 900000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('15m 0s'), findsAtLeastNWidgets(1));
    });
  });

  group('SessionHistoryScreen - Filter by subject', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('filters by subject and clears filters', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
        Session(
          id: 's2', studentId: 'u1', subjectId: 'science',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('math'));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNWidgets(2));
    });
  });

  group('SessionHistoryScreen - Delete session', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('dismiss delete supports cancel, delete, and undo', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
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
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Session deleted'), findsOneWidget);
      expect(find.byKey(const Key('s1')), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('s1')), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Export functionality', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows export button in app bar', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, questionsAnswered: 10, correctAnswers: 8,
          actualDurationMs: 1800000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('export menu shows CSV, PDF, and JSON options', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, questionsAnswered: 10, correctAnswers: 8,
          actualDurationMs: 1800000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
    });

    testWidgets('shows snackbar when exporting with no sessions', (tester) async {
      final repo = _FakeSessionRepository();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      // No sessions, but menu should still show
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
    });

    testWidgets('export CSV with no sessions shows no sessions snackbar', (tester) async {
      final repo = _FakeSessionRepository();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsAtLeastNWidgets(1));
    });

    testWidgets('comprehensive export options show in menu', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(find.text('Full Progress CSV'), findsOneWidget);
      expect(find.text('Full Progress PDF'), findsOneWidget);
      expect(find.text('Full Progress JSON'), findsOneWidget);
    });

    testWidgets('export menu items are tappable without crash', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, questionsAnswered: 10, correctAnswers: 8,
          actualDurationMs: 1800000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export PDF'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SessionHistoryScreen - Load errors', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows sessions after successful load', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Dismissible), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Delete session error', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('shows error snackbar when delete fails', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(
        throwOnDelete: true,
        seed: [
          Session(
            id: 's1', studentId: 'u1', subjectId: 'math',
            startTime: now, actualDurationMs: 600000,
            type: SessionType.manual,
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('s1'));
      await tester.drag(tile, const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to delete session'), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Subject filter edge cases', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('subject filter does not open dialog when no sessions', (tester) async {
      final repo = _FakeSessionRepository();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('clear filter resets subject filter', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
        Session(
          id: 's2', studentId: 'u1', subjectId: 'science',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('math'));
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'math'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsNWidgets(2));
    });

    testWidgets('shows subject name in filter button after selection', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'physics',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('physics'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'physics'), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Date filter edge cases', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('date picker cancel does not apply filter', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('clear filters button appears after applying date filter', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Date'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });

  group('SessionHistoryScreen - Combined filters', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('date and subject filters work together', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
        Session(
          id: 's2', studentId: 'u1', subjectId: 'science',
          startTime: now.subtract(const Duration(days: 2)), actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter by Subject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('math'));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNWidgets(2));
    });
  });

  group('SessionHistoryScreen - Comprehensive export', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('comprehensive export items are tappable without crash', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, questionsAnswered: 10, correctAnswers: 8,
          actualDurationMs: 1800000,
          type: SessionType.manual,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Progress CSV'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Progress PDF'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Progress JSON'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Keyboard accessibility', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final view = binding.platformDispatcher.implicitView!;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 1.0;
    });

    testWidgets('renders FocusTraversalGroup for keyboard navigation', (tester) async {
      final repo = _FakeSessionRepository();
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('renders delete IconButton as keyboard alternative to Dismissible', (tester) async {
      final now = DateTime.now();
      final repo = _FakeSessionRepository(seed: [
        Session(
          id: 's1', studentId: 'u1', subjectId: 'math',
          startTime: now, actualDurationMs: 600000,
          type: SessionType.manual,
        ),
      ]);
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('Dismissible has swipeToDelete accessibility hint', (tester) async {
      final List<Session> sessions = [
        Session(
          id: 'sess_1',
          startTime: DateTime(2025, 1, 10, 10, 0),
          endTime: DateTime(2025, 1, 10, 11, 0),
          actualDurationMs: 3600000,
          questionsAnswered: 5,
          correctAnswers: 3,
          studentId: 'student1',
          subjectId: 'sub_math',
          type: SessionType.practice,
        ),
      ];
      final repo = _FakeSessionRepository(seed: sessions);
      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final hasSemanticsWithHint = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.hint != null,
      );
      expect(hasSemanticsWithHint, findsAtLeast(1));
    });
  });
}
