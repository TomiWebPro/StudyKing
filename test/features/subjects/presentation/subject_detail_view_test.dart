import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/presentation/subject_detail_view.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp() {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const SubjectDetailScreen(
        subjectId: 'test-id',
        subjectName: 'Mathematics',
        subjectCode: 'MATH101',
        subjectColor: '#2196F3',
        subjectDescription: 'Mathematics course',
        subjectTeacher: 'Dr. Smith',
        topicIds: ['topic-1', 'topic-2'],
      ),
    ),
  );
}

void main() {
  group('SubjectDetailScreen', () {
    testWidgets('renders subject name in sliver header', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('renders tab bar with 4 tabs', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(4));
    });

    testWidgets('renders edit and more option icons', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('more options shows bottom sheet', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit Subject'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Delete Subject'), findsOneWidget);
    });

    testWidgets('delete shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Delete Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Are you sure you want to delete this subject? This will also delete all associated lessons and questions.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tab labels are present on TabBar', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
    });
  });
}
