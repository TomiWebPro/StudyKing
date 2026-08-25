import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/adapters/lesson_recap_adapter.dart';
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';

class FakeLessonRecapRepository extends LessonRecapRepository {
  final Map<String, LessonRecapModel> _store = {};
  bool open = true;

  @override
  bool get isOpen => open;

  @override
  Future<void> openBox(String boxName) async => open = true;

  @override
  Future<Result<void>> saveRecap(LessonRecapModel recap) async {
    _store[recap.id] = recap;
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _store.remove(key);
    return Result.success(null);
  }

  @override
  Future<Result<LessonRecapModel?>> getBySession(String sessionId) async {
    for (final r in _store.values) {
      if (r.sessionId == sessionId) return Result.success(r);
    }
    return Result.success(null);
  }

  @override
  Future<Result<LessonRecapModel?>> getByLesson(String lessonId) async {
    for (final r in _store.values) {
      if (r.lessonId == lessonId) return Result.success(r);
    }
    return Result.success(null);
  }

  @override
  Future<Result<List<LessonRecapModel>>> getStudentRecaps(
      String studentId) async {
    final list = _store.values
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return Result.success(list);
  }
}

LessonRecapModel makeRecap({
  String id = 'r1',
  String sessionId = 's1',
  String? lessonId,
  String studentId = 'student-1',
  double accuracy = 0.5,
  int correctCount = 2,
  int questionCount = 4,
  int participationMessages = 8,
  DateTime? generatedAt,
}) {
  return LessonRecapModel(
    id: id,
    sessionId: sessionId,
    lessonId: lessonId,
    studentId: studentId,
    subjectId: 'subj-1',
    topicId: 'topic-1',
    topicTitle: 'Topic',
    accuracy: accuracy,
    correctCount: correctCount,
    questionCount: questionCount,
    participationMessages: participationMessages,
    generatedAt: generatedAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('LessonRecapRepository (fake)', () {
    late FakeLessonRecapRepository repo;

    setUp(() => repo = FakeLessonRecapRepository());

    test('saveRecap persists and getBySession returns it', () async {
      final recap = makeRecap(id: 'a', sessionId: 'sess-A');
      final save = await repo.saveRecap(recap);
      expect(save.isSuccess, isTrue);

      final bySession = await repo.getBySession('sess-A');
      expect(bySession.data?.id, 'a');
    });

    test('getByLesson filters by lessonId', () async {
      await repo.saveRecap(makeRecap(id: 'a', lessonId: 'L1'));
      await repo.saveRecap(makeRecap(id: 'b', lessonId: 'L2'));
      final result = await repo.getByLesson('L2');
      expect(result.data?.id, 'b');
    });

    test('getStudentRecaps returns newest first', () async {
      await repo.saveRecap(makeRecap(
        id: 'old',
        studentId: 's1',
        generatedAt: DateTime(2026, 1, 1),
      ));
      await repo.saveRecap(makeRecap(
        id: 'new',
        studentId: 's1',
        generatedAt: DateTime(2026, 2, 1),
      ));
      final result = await repo.getStudentRecaps('s1');
      expect(result.data?.first.id, 'new');
      expect(result.data, hasLength(2));
    });

    test('deleteForSession removes the matching recap', () async {
      await repo.saveRecap(makeRecap(id: 'a', sessionId: 'sess-X'));
      final deleted = await repo.deleteForSession('sess-X');
      expect(deleted.isSuccess, isTrue);
      final after = await repo.getBySession('sess-X');
      expect(after.data, isNull);
    });
  });

  group('LessonRecapRepository (real Hive)', () {
    late LessonRecapRepository repo;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(30)) {
        Hive.registerAdapter(LessonRecapAdapter());
      }
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('recap_repo_test_');
      Hive.init(dir.path);
      repo = LessonRecapRepository();
      await repo.init();
    });

    tearDown(() async {
      await repo.box.close();
      await Hive.deleteBoxFromDisk('lesson_recaps');
    });

    test('saveRecap persists and getBySession retrieves it', () async {
      final recap = makeRecap(id: 'h1', sessionId: 'sess-H', lessonId: 'LH');
      final save = await repo.saveRecap(recap);
      expect(save.isSuccess, isTrue);

      final bySession = await repo.getBySession('sess-H');
      expect(bySession.isSuccess, isTrue);
      expect(bySession.data?.id, 'h1');
      expect(bySession.data?.lessonId, 'LH');
    });

    test('getByLesson filters persisted recaps', () async {
      await repo.saveRecap(makeRecap(id: 'h1', lessonId: 'LH1'));
      await repo.saveRecap(makeRecap(id: 'h2', lessonId: 'LH2'));
      final result = await repo.getByLesson('LH1');
      expect(result.data?.id, 'h1');
    });
  });
}
