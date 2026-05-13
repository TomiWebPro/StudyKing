import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/presentation/subject_list_view.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _MockSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(Subject s) => _storage[s.id] = s;
  Subject? get(String id) => _storage[id];
  Iterable<Subject> get values => _storage.values.toList();
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

class _ErrorSubjectRepository extends SubjectRepository {
  _ErrorSubjectRepository() : super(subjectBox: null);

  @override
  Future<List<Subject>> getAll() async {
    throw Exception('Failed to load subjects');
  }
}

class _FailingNotifier extends SubjectsRepositoryNotifier {
  @override
  Future<SubjectRepository> build() async {
    throw Exception('Repository failed to initialize');
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
      home: const SubjectListView(),
    ),
  );
}

Subject _subject({required String id, required String name, String? code, String color = '#2196F3'}) {
  return Subject(id: id, name: name, code: code, color: color);
}

void main() {
  group('SubjectListView', () {
    testWidgets('shows empty state when no subjects', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('My Subjects'), findsOneWidget);
      expect(find.text('No subjects yet'), findsOneWidget);
      expect(find.text('Add your first subject to begin studying'), findsOneWidget);
    });

    testWidgets('add icons appear in appbar and empty state', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsAtLeastNWidgets(2));
    });

    testWidgets('displays list of subjects', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Mathematics', code: 'MATH101'));
      box.addSubject(_subject(id: '2', name: 'Physics', code: 'PHY101'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('MATH101'), findsOneWidget);
      expect(find.text('PHY101'), findsOneWidget);
    });

    testWidgets('displays subject cards with icons', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Biology'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsWidgets);
    });

    testWidgets('books icon visible in empty state', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('add subject button in empty state', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsWidgets);
    });

    testWidgets('shows timer icon in subject cards', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Chemistry'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('shows error state when repository fails', (tester) async {
      final repo = _ErrorSubjectRepository();

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error: Exception: Failed to load subjects'), findsOneWidget);
    });

    testWidgets('shows subject name in card semantics', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Physics'), findsOneWidget);
    });

    testWidgets('shows provider error state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => _FailingNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SubjectListView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error: Exception: Repository failed to initialize'), findsOneWidget);
    });

    testWidgets('app bar add button shows selection screen', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Save'), findsWidgets);
    });

    testWidgets('shows practice sessions label on subject card', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Biology'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Practice sessions'), findsOneWidget);
    });
  });
}
