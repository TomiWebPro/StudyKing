import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/data/adapters.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/presentation/subject_selection_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSubjectBox {
  final Map<String, Subject> _storage = {};
  Subject? get(String id) => _storage[id];
  Future<void> put(String id, Subject value) async => _storage[id] = value;
}

class _FakeSubjectRepository extends SubjectRepository {
  final _FakeSubjectBox _box;
  _FakeSubjectRepository(this._box);

  @override
  Future<Result<List<Subject>>> getAll() async =>
      Result.success(_box._storage.values.toList());

  @override
  Future<Result<Subject?>> get(String id) async => Result.success(_box.get(id));

  @override
  Future<Result<void>> create(Subject subject) async {
    await _box.put(subject.id, subject);
    return Result.success(null);
  }
}

/// Fake that also captures the screen's `put` call (used to persist the
/// updated subject carrying its seeded topic IDs) into the in-memory box.
class _RecordingSubjectRepository extends _FakeSubjectRepository {
  _RecordingSubjectRepository(super.box);

  @override
  Future<Result<void>> put(String id, Subject value) async {
    await _box.put(id, value);
    return Result.success(null);
  }
}

/// Fake whose `put` write fails the way the real [Repository.put] does:
/// an internal catch turned into [Result.failure], never a thrown
/// exception.
class _PutFailingSubjectRepository extends _RecordingSubjectRepository {
  _PutFailingSubjectRepository(super.box);

  @override
  Future<Result<void>> put(String id, Subject value) async {
    return Result.failure('Hive write failed');
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
  group('SubjectSelectionScreen write results', () {
    late Directory hiveDir;

    setUpAll(() async {
      hiveDir = Directory.systemTemp.createTempSync('subject_selection_write_');
      Hive.init(hiveDir.path);
      registerSubjectsAdapters();
      await TopicRepository().init();
    });

    // No tearDownAll: Hive.close() awaits the box's frame
    // writer, whose stream subscription lives in the test's
    // fake-async zone and cannot be flushed from here. The
    // temp directory is per test-file process and cleaned up
    // by the OS.

    testWidgets('shows error snackbar and aborts when attaching seed topics fails', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _PutFailingSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'IB Chemistry');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      // The seed flow performs many sequential Hive writes. Real
      // I/O futures only complete while the real event loop runs
      // (tester.runAsync), so pump and run the event loop until
      // the failure snackbar appears.
      for (var i = 0; i < 300; i++) {
        if (find.textContaining('Error saving subject:').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 10));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      }

      // The failed put is reported instead of the success dialogs.
      expect(find.textContaining('Error saving subject:'), findsOneWidget);
      expect(find.text('Topics Created'), findsNothing);
      expect(find.text('Subject created successfully'), findsNothing);

      // The subject was created, but the failed put means the
      // seeded topic IDs were never attached to it.
      final subjects = await repo.getAll();
      expect(subjects.data, hasLength(1));
      expect(subjects.data!.first.topicIds, isEmpty);

      // The seed topics were written to the topics box even though
      // the subject update failed — the inconsistency the error
      // snackbar now surfaces instead of masking it as success.
      final createdId = subjects.data!.first.id;
      final seededTopics = Hive.box<Topic>(HiveBoxNames.topics)
          .values
          .where((t) => t.subjectId == createdId)
          .toList();
      expect(seededTopics, isNotEmpty);
    });
  });
}
