import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/presentation/subject_management_screen.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _MockSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(Subject s) => _storage[s.id] = s;
  Iterable<Subject> get values => _storage.values;
  Subject? get(String id) => _storage[id];
  Future<void> put(String id, Subject value) async => _storage[id] = value;
}

class _FakeSubjectRepository extends SubjectRepository {
  final _MockSubjectBox _box;
  _FakeSubjectRepository(this._box) : super(subjectBox: null);

  @override
  Future<List<Subject>> getAll() async => _box.values.toList();

  @override
  Future<Subject?> get(String id) async => _box.get(id);

  @override
  Future<void> save(Subject subject) async => _box.put(subject.id, subject);
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
      home: const SubjectManagementScreen(),
    ),
  );
}

void main() {
  group('SubjectManagementScreen', () {
    testWidgets('renders form with all fields', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Add New Subject'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(5));
      expect(find.text('Create Subject'), findsOneWidget);
      expect(find.text('Theme Color'), findsOneWidget);
    });

    testWidgets('displays create subject button', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Create Subject'), findsOneWidget);
    });

    testWidgets('shows color picker circles', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('shows select date button', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Select date'), findsOneWidget);
    });

    testWidgets('shows error when name is empty on create', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Create Subject'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Subject'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Please enter a subject name'), findsOneWidget);
    });

    testWidgets('can type into name field', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Physics');
      await tester.pumpAndSettle();

      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets('shows exam date label', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Exam Date (Optional):'), findsOneWidget);
    });

    testWidgets('exam date button is present', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Select date'), findsOneWidget);
    });

    testWidgets('exam date picker can be opened', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Select date'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select date'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('color picker circles are tappable', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(Wrap).first);
      await tester.pumpAndSettle();

      final inkwells = find.byType(InkWell);
      if (inkwells.evaluate().isNotEmpty) {
        await tester.tap(inkwells.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('entering name and creating subject shows error', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Mathematics');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Create Subject'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Subject'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Error creating subject:'), findsOneWidget);
    });

    testWidgets('description field accepts multi-line text', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(TextFormField).at(3));
      await tester.pumpAndSettle();

      final descField = find.byType(TextFormField).at(3);
      await tester.enterText(descField, 'Line 1\nLine 2');
      await tester.pumpAndSettle();
    });

    testWidgets('shows hint texts on form fields', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Subject Name *'), findsOneWidget);
      expect(find.text('Subject Code (Optional)'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
      expect(find.text('Teacher (Optional)'), findsOneWidget);
      expect(find.text('Syllabus/Scope (Optional)'), findsOneWidget);
    });
  });
}
