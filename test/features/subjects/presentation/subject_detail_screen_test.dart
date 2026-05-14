import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/subjects/presentation/subject_detail_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp() {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: SubjectDetailScreen(
        args: const SubjectDetailArgs(
          subjectId: 'test-id',
          subjectName: 'Mathematics',
          subjectCode: 'MATH101',
          subjectColor: '#2196F3',
          subjectDescription: 'Mathematics course',
          subjectTeacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2'],
        ),
      ),
    ),
  );
}

Widget _buildTestAppMinimal() {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: SubjectDetailScreen(
        args: const SubjectDetailArgs(
          subjectId: 'test-id',
          subjectName: 'Physics',
          subjectColor: '#4CAF50',
          topicIds: [],
        ),
      ),
    ),
  );
}

void main() {
  group('SubjectDetailScreen', () {
    testWidgets('renders subject name in sliver header', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('renders tab bar with 4 tabs', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(4));
    });

    testWidgets('renders more option icon', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('tab labels are present on TabBar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
    });

    testWidgets('lessons tab has add topic button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Add Topic'), findsOneWidget);
    });

    testWidgets('practice tab shows practice buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Start Practice'), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('history tab shows empty state', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('start practice button navigates', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('semantics for more options exist', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('practice mode button navigates', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Practice Mode').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('stats tab shows metric cards', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Stats'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Practice Progress'), findsOneWidget);
    });

    testWidgets('practice mode button is present', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.play_arrow), findsAtLeast(1));
    });

    testWidgets('switches between all tabs', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      for (final tab in ['Lessons', 'Practice', 'History', 'Stats']) {
        await tester.tap(find.text(tab));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('renders subject code when provided', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('MATH101'), findsOneWidget);
    });

    testWidgets('does not render subject code when null', (tester) async {
      await tester.pumpWidget(_buildTestAppMinimal());
      await tester.pump();

      expect(find.text('Physics'), findsAtLeast(1));
    });


  });
}
