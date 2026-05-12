import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/practice/presentation/practice_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _MockSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(Subject s) => _storage[s.id] = s;
  Iterable<Subject> get values => _storage.values.toList();
  void clear() => _storage.clear();
}

class _FakeSubjectRepository extends SubjectRepository {
  final _MockSubjectBox _box;
  _FakeSubjectRepository(this._box) : super(subjectBox: null);

  @override
  Future<List<Subject>> getAll() async => _box.values.toList();
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;
  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getAll() async {
    return Result.success(_questions);
  }

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(_questions);
  }
}

class _FakeSpacedRepetitionRepository extends SpacedRepetitionRepository {
  final Map<String, int> _dueCounts;

  _FakeSpacedRepetitionRepository([this._dueCounts = const {}]);

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    return Result.success([]);
  }
}

class _FakeSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _FakeSubjectsRepositoryNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
}

Subject _subject({required String id, required String name, String? code}) {
  return Subject(id: id, name: name, code: code);
}

Widget _buildTestApp({
  required SubjectRepository subjectRepo,
  QuestionRepository? questionRepo,
  SpacedRepetitionRepository? srRepo,
}) {
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsRepositoryNotifier(subjectRepo)),
      questionRepositoryProvider.overrideWithValue(questionRepo ?? _FakeQuestionRepository([])),
      spacedRepetitionRepositoryProvider.overrideWithValue(srRepo ?? _FakeSpacedRepetitionRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const PracticeScreen(),
    ),
  );
}

void main() {
  group('PracticeScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no subjects', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('No Practice Sessions Yet'), findsOneWidget);
      expect(find.text('Add subjects and questions to start practicing'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
    });

    testWidgets('shows practice modes grid when subjects exist', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Mathematics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Practice Modes'), findsOneWidget);
      expect(find.text('Quick Practice'), findsOneWidget);
      expect(find.text('Spaced Repetition'), findsOneWidget);
      expect(find.text('Topic Focus'), findsOneWidget);
      expect(find.text('Weak Areas'), findsOneWidget);
    });

    testWidgets('shows subject section with cards', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Mathematics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsAtLeast(1));
    });

    testWidgets('shows practice button in FAB', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('tune icon opens practice mode dialog for multiple subjects', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      box.addSubject(_subject(id: '2', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Practice Mode'), findsAtLeast(1));
    });

    testWidgets('FAB shows no subjects when empty', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('No Subjects'), findsOneWidget);
    });

    testWidgets('shows spaced repetition due count badge', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Chemistry'));
      final repo = _FakeSubjectRepository(box);
      final srRepo = _FakeSpacedRepetitionRepository({'1': 5});

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srRepo: srRepo));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows book icon in empty state', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.book_online_outlined), findsOneWidget);
    });
  });
}
