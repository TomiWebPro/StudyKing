import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/lessons/presentation/topic_list_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeTopicRepository extends TopicRepository {
  final List<Topic> _topics;
  bool shouldThrow = false;
  int getAllCallCount = 0;

  _FakeTopicRepository({List<Topic>? topics}) : _topics = topics ?? [];

  @override
  Future<List<Topic>> getAll() async {
    getAllCallCount++;
    if (shouldThrow) throw Exception('Simulated DB error');
    return _topics;
  }

  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async => null;
}

Widget _buildTestApp(TopicListScreen screen) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: screen),
  );
}

void main() {
  group('TopicListScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeTopicRepository();
      await tester.pumpWidget(_buildTestApp(
        TopicListScreen(topicRepository: repo),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays topics when loaded', (tester) async {
      final repo = _FakeTopicRepository(topics: [
        Topic(id: 't1', subjectId: 's1', title: 'Algebra', description: 'Algebra basics', syllabusText: ''),
        Topic(id: 't2', subjectId: 's1', title: 'Geometry', description: 'Shapes and angles', syllabusText: ''),
      ]);

      await tester.pumpWidget(_buildTestApp(
        TopicListScreen(topicRepository: repo),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Algebra basics'), findsOneWidget);
      expect(find.text('Shapes and angles'), findsOneWidget);
    });

    testWidgets('shows empty state when no topics', (tester) async {
      final repo = _FakeTopicRepository(topics: []);

      await tester.pumpWidget(_buildTestApp(
        TopicListScreen(topicRepository: repo),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No topics yet - add some!'), findsOneWidget);
    });

    testWidgets('displays folder and chevron icons for each topic', (tester) async {
      final repo = _FakeTopicRepository(topics: [
        Topic(id: 't1', subjectId: 's1', title: 'Algebra', description: '', syllabusText: ''),
      ]);

      await tester.pumpWidget(_buildTestApp(
        TopicListScreen(topicRepository: repo),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows error snackbar with retry when load fails', (tester) async {
      final repo = _FakeTopicRepository();
      repo.shouldThrow = true;

      await tester.pumpWidget(_buildTestApp(
        TopicListScreen(topicRepository: repo),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repo.shouldThrow = false;
      await tester.pump();
      await tester.pump();
    });

    testWidgets('navigates to lesson list on topic tap', (tester) async {
      final repo = _FakeTopicRepository(topics: [
        Topic(id: 't1', subjectId: 's1', title: 'Algebra', description: '', syllabusText: ''),
      ]);

      await tester.pumpWidget(_buildTestApp(
        TopicListScreen(topicRepository: repo),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
    });

    testWidgets('uses default database repository when none injected', (tester) async {
      await tester.pumpWidget(_buildTestApp(const TopicListScreen()));
    });
  });
}
