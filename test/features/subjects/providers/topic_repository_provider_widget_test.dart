import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};
  bool shouldThrow = false;

  @override
  Future<Result<void>> put(String key, Topic item) async {
    if (shouldThrow) return Result.failure('storage error');
    _topics[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<Topic?>> get(String key) async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_topics[key]);
  }

  @override
  Future<Result<List<Topic>>> getAll() async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_topics.values.toList());
  }

  @override
  Future<Result<void>> init() async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(null);
  }
}

Topic _createTopic({required String id, required String subjectId}) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: 'Topic $id',
    description: 'Description for $id',
    syllabusText: 'Syllabus for $id',
    childTopicIds: [],
  );
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
  testWidgets('provider is accessible in widget tree', (tester) async {
    final fakeRepo = _FakeTopicRepository();
    await fakeRepo.put('t1', _createTopic(id: 't1', subjectId: 's1'));

    String? topicTitle;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: _TopicReaderWidget(
            onRead: (repo) async {
              final topic = await repo.get('t1');
              topicTitle = topic.data?.title;
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(topicTitle, 'Topic t1');
  });

  testWidgets('handles error state from repo', (tester) async {
    final fakeRepo = _FakeTopicRepository();
    await fakeRepo.put('t1', _createTopic(id: 't1', subjectId: 's1'));
    fakeRepo.shouldThrow = true;

    bool? isFailure;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: _TopicReaderWidget(
            onRead: (repo) async {
              final topic = await repo.get('t1');
              isFailure = topic.isFailure;
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(isFailure, isTrue);
  });

  testWidgets('recovers after error', (tester) async {
    final fakeRepo = _FakeTopicRepository();
    await fakeRepo.put('t1', _createTopic(id: 't1', subjectId: 's1'));

    fakeRepo.shouldThrow = true;
    bool? firstFailure;
    String? recoveredTitle;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: _TopicReaderWidget(
            onRead: (repo) async {
              if (firstFailure == null) {
                final topic = await repo.get('t1');
                firstFailure = topic.isFailure;
              } else {
                final topic = await repo.get('t1');
                recoveredTitle = topic.data?.title;
              }
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(firstFailure, isTrue);

    fakeRepo.shouldThrow = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: _TopicReaderWidget(
            onRead: (repo) async {
              final topic = await repo.get('t1');
              recoveredTitle = topic.data?.title;
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(recoveredTitle, 'Topic t1');
  });
}
