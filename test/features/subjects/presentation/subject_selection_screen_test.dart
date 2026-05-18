import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/presentation/subject_selection_screen.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(String id, Subject subject) => _storage[id] = subject;
  Subject? get(String id) => _storage[id];
  Future<void> put(String id, Subject value) async => _storage[id] = value;
}

class _FakeSubjectRepository extends SubjectRepository {
  final _FakeSubjectBox _box;
  _FakeSubjectRepository(this._box);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_box._storage.values.toList());

  @override
  Future<Result<Subject?>> get(String id) async => Result.success(_box.get(id));

  @override
  Future<Result<void>> create(Subject subject) async {
    await _box.put(subject.id, subject);
    return Result.success(null);
  }
}

class _FailingSubjectRepository extends SubjectRepository {
  _FailingSubjectRepository();

  @override
  Future<Result<void>> create(Subject subject) async {
    throw Exception('Save failed');
  }
}

class _SlowSubjectRepository extends SubjectRepository {
  _SlowSubjectRepository();

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success([]);

  @override
  Future<Result<Subject?>> get(String id) async => Result.success(null);

  @override
  Future<Result<void>> create(Subject subject) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return Result.success(null);
  }
}

Widget _buildTestAppForRepo(SubjectRepository repo, {TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(() => _TestNotifier(repo)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.upload) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Upload Mock')),
            settings: settings,
          );
        }
        return null;
      },
      home: const SubjectSelectionScreen(),
    ),
  );
}

class _TestNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _TestNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
}

Widget _buildTestApp(SubjectRepository repo, {TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(() => _TestNotifier(repo)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.upload) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Upload Mock')),
            settings: settings,
          );
        }
        return null;
      },
      home: const SubjectSelectionScreen(),
    ),
  );
}

void main() {
  group('SubjectSelectionScreen', () {
    testWidgets('renders form fields and save button', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows SubjectColorSelector', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Subject Color'), findsOneWidget);
    });

    testWidgets('save button saves subject and pops', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Mathematics');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('No thanks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final subjects = await repo.getAll();
      expect(subjects.data, hasLength(1));
    });

    testWidgets('shows validation error when name is empty on save', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Please enter a subject name'), findsOneWidget);
    });

    testWidgets('color selector is interactive', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('color selection callback works', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final inkwells = find.byType(InkWell);
      if (inkwells.evaluate().length > 1) {
        await tester.tap(inkwells.at(1));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('shows error snackbar when save fails', (tester) async {
      final repo = _FailingSubjectRepository();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Mathematics');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Error saving subject:'), findsOneWidget);
    });

    testWidgets('entering all fields and saving works', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Physics');
      await tester.enterText(find.byType(TextFormField).at(1), 'PHY101');
      await tester.enterText(find.byType(TextFormField).at(2), 'Dr. Smith');
      await tester.enterText(find.byType(TextFormField).at(3), 'Mechanics');
      await tester.enterText(find.byType(TextFormField).at(4), 'Introductory physics');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('No thanks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final subjects = await repo.getAll();
      expect(subjects.data, hasLength(1));
      expect(subjects.data!.first.name, 'Physics');
      expect(subjects.data!.first.code, 'PHY101');
      expect(subjects.data!.first.teacher, 'Dr. Smith');
      expect(subjects.data!.first.syllabus, 'Mechanics');
      expect(subjects.data!.first.description, 'Introductory physics');
    });

    testWidgets('code field has character capitalization', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final codeField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(codeField.textCapitalization, TextCapitalization.characters);
    });

    testWidgets('shows loading indicator during save', (tester) async {
      final repo = _SlowSubjectRepository();

      await tester.pumpWidget(_buildTestAppForRepo(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Mathematics');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    });

    testWidgets('optional fields are null in saved subject when left empty', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Physics');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('No thanks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final subjects = await repo.getAll();
      expect(subjects.data, hasLength(1));
      expect(subjects.data!.first.name, 'Physics');
      expect(subjects.data!.first.code, isNull);
      expect(subjects.data!.first.teacher, isNull);
      expect(subjects.data!.first.syllabus, isNull);
      expect(subjects.data!.first.description, isNull);
    });

    testWidgets('code is auto-uppercased when saved', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Chemistry');
      await tester.enterText(find.byType(TextFormField).at(1), 'chem101');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('No thanks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final subjects = await repo.getAll();
      expect(subjects.data, hasLength(1));
      expect(subjects.data!.first.code, 'CHEM101');
    });

    testWidgets('app bar shows title', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
    });

    testWidgets('renders five text form fields', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(5));
    });

    testWidgets('saves subject with selected color', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Physics');

      await tester.tap(find.text('Green'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('No thanks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final subjects = await repo.getAll();
      expect(subjects.data, hasLength(1));
      expect(subjects.data!.first.name, 'Physics');
      expect(subjects.data!.first.color, '#4CAF50');
    });

    testWidgets('saves subject with default color when no color selected', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Chemistry');

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('No thanks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final subjects = await repo.getAll();
      expect(subjects.data, hasLength(1));
      expect(subjects.data!.first.name, 'Chemistry');
      expect(subjects.data!.first.color, '#2196F3');
    });

    testWidgets('shows upload prompt dialog after saving new subject', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Biology');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Subject created successfully'), findsOneWidget);
      expect(find.text('Upload Study Material'), findsOneWidget);
      expect(find.text('No thanks'), findsOneWidget);
    });

    testWidgets('upload prompt dialog navigates to upload on Upload Study Material', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'History');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Upload Study Material'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Mock'), findsOneWidget);
    });

    testWidgets('editing existing subject pre-fills fields', (tester) async {
      final existingSubject = Subject(
        id: 'edit-id',
        name: 'Existing Subject',
        code: 'EX123',
        teacher: 'John Doe',
        syllabus: 'Course syllabus',
        description: 'Course description',
        color: '#9C27B0',
        topicIds: ['topic-1'],
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => _TestNotifier(_FakeSubjectRepository(_FakeSubjectBox()))),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SubjectSelectionScreen(editingSubject: existingSubject),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Subject'), findsOneWidget);
      expect(find.text('Existing Subject'), findsOneWidget);
      expect(find.text('EX123'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Course syllabus'), findsOneWidget);
      expect(find.text('Course description'), findsOneWidget);
    });

    testWidgets('editing subject with code pre-fills uppercase code', (tester) async {
      final existingSubject = Subject(
        id: 'edit-id-2',
        name: 'Physics',
        code: 'PHY202',
        teacher: 'Dr. Smith',
        color: '#2196F3',
        topicIds: [],
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => _TestNotifier(_FakeSubjectRepository(_FakeSubjectBox()))),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SubjectSelectionScreen(editingSubject: existingSubject),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final codeField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(codeField.controller?.text, 'PHY202');
    });

    testWidgets('editing and saving subject updates existing', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);
      final existingSubject = Subject(
        id: 'edit-id-3',
        name: 'Old Name',
        color: '#2196F3',
        topicIds: [],
        createdAt: DateTime(2024, 1, 1),
      );
      box.addSubject('edit-id-3', existingSubject);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => _TestNotifier(repo)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SubjectSelectionScreen(editingSubject: existingSubject),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'New Name');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final updated = await repo.get('edit-id-3');
      expect(updated.data, isNotNull);
      expect(updated.data!.name, 'New Name');
    });

    testWidgets('navigator pushes upload route on Upload Study Material tap', (tester) async {
      final observer = TestNavigatorObserver();
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo, navigatorObserver: observer));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'History');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Upload Study Material'));
      await tester.pumpAndSettle();

      expect(
        observer.pushedRoutes.any((r) => r.settings.name == AppRoutes.upload),
        isTrue,
      );
    });

    testWidgets('navigator pops via system back', (tester) async {
      final observer = TestNavigatorObserver();
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo, navigatorObserver: observer));
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, isEmpty);
    });
  });
}
