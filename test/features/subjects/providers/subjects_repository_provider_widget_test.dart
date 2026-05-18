import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';

class _FakeSubjectRepository extends SubjectRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<Subject?>> get(String key) async => Result.success(null);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success([]);

  @override
  Future<Result<void>> put(String key, Subject item) async =>
      Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class _TestNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository _repo;
  _TestNotifier(this._repo);

  @override
  Future<SubjectRepository> build() async => _repo;
}

class _FailingNotifier extends SubjectsRepositoryNotifier {
  @override
  Future<SubjectRepository> build() async =>
      throw Exception('Widget init failed');
}

class _SlowNotifier extends SubjectsRepositoryNotifier {
  @override
  Future<SubjectRepository> build() async {
    await Future.delayed(const Duration(seconds: 1));
    return _FakeSubjectRepository();
  }
}

class _FirstFailingThenOkNotifier extends SubjectsRepositoryNotifier {
  int callCount = 0;

  @override
  Future<SubjectRepository> build() async {
    callCount++;
    if (callCount == 1) throw Exception('First build fails');
    return _FakeSubjectRepository();
  }
}

class _ProviderReaderWidget extends ConsumerWidget {
  final void Function(SubjectRepository)? onData;

  const _ProviderReaderWidget({this.onData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRepo = ref.watch(subjectsRepositoryProvider);
    return asyncRepo.when(
      data: (repo) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onData?.call(repo));
        return const Text('DataLoaded');
      },
      loading: () => const Text('Loading...'),
      error: (e, _) => Text('Error: ${e.toString()}'),
    );
  }
}

class _InvalidatingWidget extends ConsumerStatefulWidget {
  final Widget child;
  const _InvalidatingWidget({required this.child});

  @override
  ConsumerState<_InvalidatingWidget> createState() => _InvalidatingWidgetState();
}

class _InvalidatingWidgetState extends ConsumerState<_InvalidatingWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => ref.invalidate(subjectsRepositoryProvider),
          child: const Text('Invalidate'),
        ),
        widget.child,
      ],
    );
  }
}

void main() {
  group('subjectsRepositoryProvider widget tests', () {
    testWidgets('displays data when provider resolves', (tester) async {
      final fakeRepo = _FakeSubjectRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(
              () => _TestNotifier(fakeRepo),
            ),
          ],
          child: const MaterialApp(
            home: _ProviderReaderWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('DataLoaded'), findsOneWidget);
    });

    testWidgets('shows loading state while building', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(
              () => _SlowNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: _ProviderReaderWidget(),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('shows error state on build failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(
              () => _FailingNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: _ProviderReaderWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Error: Exception: Widget init failed'),
          findsOneWidget);
    });

    testWidgets('provider returns correct instance', (tester) async {
      final fakeRepo = _FakeSubjectRepository();
      SubjectRepository? receivedRepo;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(
              () => _TestNotifier(fakeRepo),
            ),
          ],
          child: MaterialApp(
            home: _ProviderReaderWidget(
              onData: (repo) => receivedRepo = repo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(receivedRepo, isA<SubjectRepository>());
      expect(receivedRepo, same(fakeRepo));
    });

    testWidgets('transitions from loading to data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(
              () => _SlowNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: _ProviderReaderWidget(),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('DataLoaded'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Loading...'), findsNothing);
      expect(find.text('DataLoaded'), findsOneWidget);
    });

    testWidgets('shows error then recovers after invalidate', (tester) async {
      final notifier = _FirstFailingThenOkNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => notifier),
          ],
          child: const MaterialApp(
            home: _ProviderReaderWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Error: Exception: First build fails'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp(
            home: _InvalidatingWidget(
              child: const _ProviderReaderWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Error: Exception: First build fails'), findsOneWidget);

      await tester.tap(find.text('Invalidate'));
      await tester.pumpAndSettle();

      expect(find.text('DataLoaded'), findsOneWidget);
    });

    testWidgets('two ProviderScopes with different overrides are independent',
        (tester) async {
      final fakeRepo1 = _FakeSubjectRepository();
      final fakeRepo2 = _FakeSubjectRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              SizedBox(
                width: 800,
                child: ProviderScope(
                  overrides: [
                    subjectsRepositoryProvider.overrideWith(
                      () => _TestNotifier(fakeRepo1),
                    ),
                  ],
                  child: const _ProviderReaderWidget(),
                ),
              ),
              SizedBox(
                width: 800,
                child: ProviderScope(
                  overrides: [
                    subjectsRepositoryProvider.overrideWith(
                      () => _TestNotifier(fakeRepo2),
                    ),
                  ],
                  child: const _ProviderReaderWidget(),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('DataLoaded'), findsNWidgets(2));
    });
  });
}
