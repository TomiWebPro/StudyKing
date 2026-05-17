import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/lessons/presentation/topic_list_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeTopicRepository extends TopicRepository {
  final List<Topic> _topics;
  bool shouldThrow = false;
  int getAllCallCount = 0;

  _FakeTopicRepository({List<Topic>? topics}) : _topics = topics ?? [];

  @override
  Future<Result<List<Topic>>> getAll() async {
    getAllCallCount++;
    if (shouldThrow) throw Exception('Simulated DB error');
    return Result.success(_topics);
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(null);
}

Widget _buildTestApp({
  TopicRepository? topicRepo,
  List<Topic>? topics,
  bool shouldThrow = false,
}) {
  final repo = topicRepo ?? _FakeTopicRepository(topics: topics);
  if (repo is _FakeTopicRepository) {
    repo.shouldThrow = shouldThrow;
  }
  return ProviderScope(
    overrides: [
      topicRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const Scaffold(body: TopicListScreen()),
    ),
  );
}

void main() {
  group('TopicListScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays topics when loaded', (tester) async {
      await tester.pumpWidget(_buildTestApp(topics: [
        Topic(id: 't1', subjectId: 's1', title: 'Algebra', description: 'Algebra basics', syllabusText: ''),
        Topic(id: 't2', subjectId: 's1', title: 'Geometry', description: 'Shapes and angles', syllabusText: ''),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Algebra basics'), findsOneWidget);
      expect(find.text('Shapes and angles'), findsOneWidget);
    });

    testWidgets('shows empty state when no topics', (tester) async {
      await tester.pumpWidget(_buildTestApp(topics: []));
      await tester.pumpAndSettle();

      expect(find.text('No topics yet - add some!'), findsOneWidget);
    });

    testWidgets('displays folder and chevron icons for each topic', (tester) async {
      await tester.pumpWidget(_buildTestApp(topics: [
        Topic(id: 't1', subjectId: 's1', title: 'Algebra', description: '', syllabusText: ''),
      ]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows error snackbar with retry when load fails', (tester) async {
      await tester.pumpWidget(_buildTestApp(shouldThrow: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('navigates to lesson list on topic tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(_FakeTopicRepository(topics: [
              Topic(id: 't1', subjectId: 's1', title: 'Algebra', description: '', syllabusText: ''),
            ])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const Scaffold(body: TopicListScreen()),
            onGenerateRoute: (settings) {
              if (settings.name == '/lesson-list') {
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(body: Text('Lesson List')),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Algebra'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Lesson List'), findsOneWidget);
    });

    testWidgets('uses default database repository when none injected', (tester) async {
      await tester.pumpWidget(_buildTestApp(topics: [
        Topic(id: 't1', subjectId: 's1', title: 'Algebra', description: 'Algebra basics', syllabusText: ''),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
    });
  });
}

