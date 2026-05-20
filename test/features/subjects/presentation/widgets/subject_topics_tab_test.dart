import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_topics_tab.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_edit_dialog.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_dependency_dialog.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show topicDependencyRepositoryProvider;
import '../../../../helpers/navigator_observer_helper.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _storage = {};
  bool throwOnGetBySubject = false;
  bool throwOnCreate = false;
  bool throwOnDelete = false;

  void seed(Topic topic) => _storage[topic.id] = topic;
  bool hasKey(String id) => _storage.containsKey(id);

  void seedAll(List<Topic> topics) {
    for (final t in topics) {
      _storage[t.id] = t;
    }
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(Topic topic) async {
    if (throwOnCreate) throw Exception('Create failed');
    _storage[topic.id] = topic;
    return Result.success(null);
  }

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async {
    if (throwOnGetBySubject) return Result.failure('Get failed');
    return Result.success(
      _storage.values.where((t) => t.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<Result<List<Topic>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<Topic?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (throwOnDelete) throw Exception('Delete failed');
    _storage.remove(id);
    return Result.success(null);
  }
}

class _FakeSubjectRepository extends SubjectRepository {
  final Map<String, Subject> _storage = {};
  bool throwOnAddTopic = false;

  void seed(Subject subject) => _storage[subject.id] = subject;

  @override
  Future<Result<Subject?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<void>> addTopicToSubject(String subjectId, String topicId) async {
    if (throwOnAddTopic) return Result.failure('Add topic failed');
    final subject = _storage[subjectId];
    if (subject != null) {
      _storage[subjectId] = subject.copyWith(
        topicIds: [...subject.topicIds, topicId],
      );
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> removeTopicFromSubject(String subjectId, String topicId) async {
    final subject = _storage[subjectId];
    if (subject != null) {
      _storage[subjectId] = subject.copyWith(
        topicIds: subject.topicIds.where((id) => id != topicId).toList(),
      );
    }
    return Result.success(null);
  }

  @override
  Future<Result<List<Subject>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> create(Subject subject) async {
    _storage[subject.id] = subject;
    return Result.success(null);
  }
}

class _FakeSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;

  _FakeSubjectsRepositoryNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
}

class _FakeTopicDependencyRepository extends TopicDependencyRepository {
  final Map<String, TopicDependency> _storage = {};

  void seed(TopicDependency dep) => _storage[dep.topicId] = dep;

  @override
  Future<void> init() async {}

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    return Result.success(
      _storage[topicId] ?? TopicDependency(topicId: topicId),
    );
  }

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async {
    _storage[dependency.topicId] = dependency;
    return Result.success(null);
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success(_storage.values.toList());
  }
}

Widget _buildTestApp({
  required _FakeTopicRepository topicRepo,
  required _FakeSubjectRepository subjectRepo,
  _FakeTopicDependencyRepository? depRepo,
  NavigatorObserver? observer,
}) {
  return ProviderScope(
    overrides: [
      topicRepositoryProvider.overrideWithValue(topicRepo),
      subjectsRepositoryProvider.overrideWith(() {
        return _FakeSubjectsRepositoryNotifier(subjectRepo);
      }),
      if (depRepo != null)
        topicDependencyRepositoryProvider.overrideWithValue(depRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SubjectTopicsTab(subjectId: 'sub-1'),
      ),
      navigatorObservers: observer != null ? [observer] : [],
    ),
  );
}

void main() {
  late _FakeTopicRepository fakeTopicRepo;
  late _FakeSubjectRepository fakeSubjectRepo;
  late _FakeTopicDependencyRepository fakeDepRepo;
  late Subject testSubject;

  setUp(() {
    fakeTopicRepo = _FakeTopicRepository();
    fakeSubjectRepo = _FakeSubjectRepository();
    fakeDepRepo = _FakeTopicDependencyRepository();

    testSubject = Subject(id: 'sub-1', name: 'Math');
    fakeSubjectRepo.seed(testSubject);
  });

  group('SubjectTopicsTab', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state with no topics message and add button',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('0 topics'), findsOneWidget);
      expect(find.byIcon(Icons.topic), findsOneWidget);
    });

    testWidgets('renders topic list with cards', (tester) async {
      fakeTopicRepo.seedAll([
        Topic(
          id: 't-1',
          subjectId: 'sub-1',
          title: 'Algebra',
          description: 'Algebra basics',
          syllabusText: 'Algebra syllabus',
        ),
        Topic(
          id: 't-2',
          subjectId: 'sub-1',
          title: 'Geometry',
          description: 'Shapes',
          syllabusText: 'Geometry syllabus',
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('shows popup menu with edit, dependencies, and delete options',
        (tester) async {
      fakeTopicRepo.seed(Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Algebra',
        description: 'Algebra basics',
        syllabusText: 'Syllabus',
      ));

      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Edit Topic'), findsOneWidget);
      expect(find.text('Dependencies'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('add topic button navigates to TopicEditDialog', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
        observer: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(TopicEditDialog), findsOneWidget);
    });

    testWidgets('add topic flow creates topic via repo', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'New Topic');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Topic "New Topic"'), findsOneWidget);
    });

    testWidgets('delete topic shows confirmation dialog', (tester) async {
      fakeTopicRepo.seed(Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Algebra',
        description: 'Desc',
        syllabusText: 'Syllabus',
      ));

      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Topic'), findsOneWidget);
      expect(find.textContaining('This will remove'), findsOneWidget);
    });

    testWidgets('delete topic with confirmation removes topic',
        (tester) async {
      fakeTopicRepo.seed(Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Algebra',
        description: 'Desc',
        syllabusText: 'Syllabus',
      ));

      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(fakeTopicRepo.hasKey('t-1'), isFalse);
    });

    testWidgets('delete topic shows error snackbar on repo failure',
        (tester) async {
      fakeTopicRepo.seed(Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Algebra',
        description: 'Desc',
        syllabusText: 'Syllabus',
      ));
      fakeTopicRepo.throwOnDelete = true;

      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to delete'), findsOneWidget);
    });

    testWidgets('edit topic opens TopicEditDialog with pre-filled data',
        (tester) async {
      fakeTopicRepo.seed(Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Algebra',
        description: 'Desc',
        syllabusText: 'Syllabus',
      ));

      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Topic'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Topic'), findsOneWidget);
      expect(find.text('Algebra'), findsWidgets);
    });

    testWidgets('dependencies menu item navigates to TopicDependencyDialog',
        (tester) async {
      fakeTopicRepo.seed(Topic(
        id: 't-1',
        subjectId: 'sub-1',
        title: 'Algebra',
        description: 'Desc',
        syllabusText: 'Syllabus',
      ));

      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
        observer: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dependencies'));
      await tester.pumpAndSettle();

      expect(find.byType(TopicDependencyDialog), findsOneWidget);
    });

    testWidgets('error state shows snackbar on repo create failure',
        (tester) async {
      fakeTopicRepo.throwOnCreate = true;

      await tester.pumpWidget(_buildTestApp(
        topicRepo: fakeTopicRepo,
        subjectRepo: fakeSubjectRepo,
        depRepo: fakeDepRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'New Topic');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to create'), findsOneWidget);
    });
  });
}
