import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';

class _FakeTopicRepository extends TopicRepository {
  bool get wasUsedViaWatch => _wasUsedViaWatch;
  bool _wasUsedViaWatch = false;

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> save(String key, Topic item) async =>
      Result.success(null);

  @override
  Future<Result<Topic?>> get(String key) async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async {
    _wasUsedViaWatch = true;
    return Result.success([]);
  }

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  Future<List<Topic>> getBySubject(String subjectId) async => [];

  @override
  Future<List<Topic>> getByParent(String parentId) async => [];

  @override
  Future<List<Topic>> getRootTopics() async => [];
}

class _TopicWatcherWidget extends ConsumerWidget {
  const _TopicWatcherWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(topicRepositoryProvider);
    return Text('RepoReady');
  }
}

class _TopicReaderWidget extends ConsumerStatefulWidget {
  final void Function(TopicRepository repo) onRead;

  const _TopicReaderWidget({required this.onRead});

  @override
  ConsumerState<_TopicReaderWidget> createState() => _TopicReaderWidgetState();
}

class _TopicReaderWidgetState extends ConsumerState<_TopicReaderWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(topicRepositoryProvider);
      widget.onRead(repo);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('topicRepositoryProvider widget tests', () {
    testWidgets('displays repo status via ref.watch', (tester) async {
      final fakeRepo = _FakeTopicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: _TopicWatcherWidget(),
          ),
        ),
      );

      expect(find.text('RepoReady'), findsOneWidget);
    });

    testWidgets('ref.read accesses the same instance as override',
        (tester) async {
      final fakeRepo = _FakeTopicRepository();
      TopicRepository? receivedRepo;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: _TopicReaderWidget(
              onRead: (repo) => receivedRepo = repo,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(receivedRepo, same(fakeRepo));
    });

    testWidgets('repo can be watched in multiple widgets', (tester) async {
      final fakeRepo = _FakeTopicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Column(
              children: [
                _TopicWatcherWidget(),
                _TopicWatcherWidget(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('RepoReady'), findsNWidgets(2));
    });

    testWidgets('override with different repos are independent',
        (tester) async {
      final fakeRepo1 = _FakeTopicRepository();
      final fakeRepo2 = _FakeTopicRepository();
      TopicRepository? repoFromScope1;
      TopicRepository? repoFromScope2;

      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              ProviderScope(
                overrides: [
                  topicRepositoryProvider.overrideWithValue(fakeRepo1),
                ],
                child: _TopicReaderWidget(
                  onRead: (repo) => repoFromScope1 = repo,
                ),
              ),
              ProviderScope(
                overrides: [
                  topicRepositoryProvider.overrideWithValue(fakeRepo2),
                ],
                child: _TopicReaderWidget(
                  onRead: (repo) => repoFromScope2 = repo,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump();
      expect(repoFromScope1, same(fakeRepo1));
      expect(repoFromScope2, same(fakeRepo2));
      expect(identical(repoFromScope1, repoFromScope2), isFalse);
    });

    testWidgets('provider is accessible without override', (tester) async {
      TopicRepository? receivedRepo;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TopicReaderWidget(
              onRead: (repo) => receivedRepo = repo,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(receivedRepo, isA<TopicRepository>());
    });
  });
}
