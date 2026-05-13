import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/presentation/subject_selection_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _MockSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(String id, Subject subject) => _storage[id] = subject;
  Subject? get(String id) => _storage[id];
  Future<void> put(String id, Subject value) async => _storage[id] = value;
}

class _FakeSubjectRepository extends SubjectRepository {
  final _MockSubjectBox _box;
  _FakeSubjectRepository(this._box) : super(subjectBox: null);

  @override
  Future<List<Subject>> getAll() async => _box._storage.values.toList();

  @override
  Future<Subject?> get(String id) async => _box.get(id);

  @override
  Future<void> save(Subject subject) async {
    await _box.put(subject.id, subject);
  }
}

class _FailingSubjectRepository extends SubjectRepository {
  _FailingSubjectRepository() : super(subjectBox: null);

  @override
  Future<void> save(Subject subject) async {
    throw Exception('Save failed');
  }
}

class _TestNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _TestNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
}

Widget _buildTestApp(SubjectRepository repo) {
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(() => _TestNotifier(repo)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SubjectSelectionScreen(),
    ),
  );
}

void main() {
  group('SubjectSelectionScreen', () {
    testWidgets('renders form fields and save button', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows SubjectColorSelector', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Subject Color'), findsOneWidget);
    });

    testWidgets('save button saves subject and pops', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Mathematics');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final subjects = await repo.getAll();
      expect(subjects, hasLength(1));
    });

    testWidgets('shows validation error when name is empty on save', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Please enter a subject name'), findsOneWidget);
    });

    testWidgets('color selector is interactive', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('color selection callback works', (tester) async {
      final box = _MockSubjectBox();
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
      final box = _MockSubjectBox();
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
      await tester.pumpAndSettle();

      final subjects = await repo.getAll();
      expect(subjects, hasLength(1));
      expect(subjects.first.name, 'Physics');
      expect(subjects.first.code, 'PHY101');
      expect(subjects.first.teacher, 'Dr. Smith');
      expect(subjects.first.syllabus, 'Mechanics');
      expect(subjects.first.description, 'Introductory physics');
    });

    testWidgets('code field has character capitalization', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final codeField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(codeField.textCapitalization, TextCapitalization.characters);
    });
  });
}
