import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';

class FakeLessonFeedbackRepository extends LessonFeedbackRepository {
  final List<LessonFeedbackModel> _store = [];
  bool _open = true;

  void setOpen(bool value) => _open = value;

  @override
  bool get isOpen => _open;

  @override
  Future<void> openBox(String boxName) async {
    _open = true;
  }

  @override
  Future<Result<void>> saveFeedback(LessonFeedbackModel feedback) async {
    if (!_open) return Result.failure('Box unavailable');
    _store.add(feedback);
    return Result.success(null);
  }

  @override
  Future<Result<List<LessonFeedbackModel>>> getByStudent(String studentId) async {
    if (!_open) return Result.success([]);
    return Result.success(
        _store.where((f) => f.studentId == studentId).toList());
  }

  @override
  Future<Result<List<LessonFeedbackModel>>> getByLesson(String lessonId) async {
    if (!_open) return Result.success([]);
    return Result.success(
        _store.where((f) => f.lessonId == lessonId).toList());
  }

  @override
  Future<Result<List<LessonFeedbackModel>>> getByMessage(String messageId) async {
    if (!_open) return Result.success([]);
    return Result.success(
        _store.where((f) => f.messageId == messageId).toList());
  }

  @override
  Future<Result<List<LessonFeedbackModel>>> getReported() async {
    if (!_open) return Result.success([]);
    return Result.success(_store.where((f) => f.reportedIncorrect).toList());
  }

  @override
  Future<Result<List<LessonFeedbackModel>>> getReportedByStudent(
      String studentId) async {
    if (!_open) return Result.success([]);
    return Result.success(_store
        .where((f) => f.reportedIncorrect && f.studentId == studentId)
        .toList());
  }
}

LessonFeedbackModel makeFeedback({
  String id = 'f1',
  String studentId = 'student-1',
  String targetType = 'explanation',
  String? lessonId,
  String? messageId,
  String sentiment = 'none',
  int starRating = 0,
  String? comment,
  bool reportedIncorrect = false,
}) {
  return LessonFeedbackModel(
    id: id,
    studentId: studentId,
    targetType: targetType,
    lessonId: lessonId,
    messageId: messageId,
    sentiment: sentiment,
    starRating: starRating,
    comment: comment,
    reportedIncorrect: reportedIncorrect,
  );
}

void main() {
  group('LessonFeedbackRepository (fake)', () {
    late FakeLessonFeedbackRepository repo;

    setUp(() => repo = FakeLessonFeedbackRepository());

    test('submitFeedback returns generated id and persists', () async {
      final result = await repo.submitFeedback(
        studentId: 's1',
        targetType: 'explanation',
        sentiment: 'positive',
        starRating: 4,
        comment: 'Clear explanation',
      );
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotEmpty);
      final stored = await repo.getByStudent('s1');
      expect(stored.data, hasLength(1));
      expect(stored.data!.first.sentiment, 'positive');
      expect(stored.data!.first.starRating, 4);
    });

    test('getByLesson filters by lessonId', () async {
      await repo.saveFeedback(makeFeedback(id: 'a', lessonId: 'L1', studentId: 's1'));
      await repo.saveFeedback(makeFeedback(id: 'b', lessonId: 'L2', studentId: 's1'));
      final result = await repo.getByLesson('L1');
      expect(result.data, hasLength(1));
      expect(result.data!.first.id, 'a');
    });

    test('getByMessage filters by messageId', () async {
      await repo.saveFeedback(makeFeedback(id: 'a', messageId: 'M1', studentId: 's1'));
      await repo.saveFeedback(makeFeedback(id: 'b', messageId: 'M2', studentId: 's1'));
      final result = await repo.getByMessage('M2');
      expect(result.data, hasLength(1));
      expect(result.data!.first.id, 'b');
    });

    test('getReported only returns reported feedback', () async {
      await repo.saveFeedback(makeFeedback(id: 'a', reportedIncorrect: true));
      await repo.saveFeedback(makeFeedback(id: 'b', reportedIncorrect: false));
      final result = await repo.getReported();
      expect(result.data, hasLength(1));
      expect(result.data!.first.id, 'a');
    });

    test('getReportedByStudent filters by student and reported flag', () async {
      await repo.saveFeedback(makeFeedback(id: 'a', studentId: 's1', reportedIncorrect: true));
      await repo.saveFeedback(makeFeedback(id: 'b', studentId: 's2', reportedIncorrect: true));
      final result = await repo.getReportedByStudent('s1');
      expect(result.data, hasLength(1));
      expect(result.data!.first.id, 'a');
    });

    test('gracefully handles closed box: getByStudent returns empty, save fails',
        () async {
      repo.setOpen(false);
      final getResult = await repo.getByStudent('s1');
      expect(getResult.isSuccess, isTrue);
      expect(getResult.data, isEmpty);

      final saveResult = await repo.saveFeedback(makeFeedback());
      expect(saveResult.isFailure, isTrue);
    });
  });

  group('LessonFeedbackRepository (real Hive)', () {
    late LessonFeedbackRepository repo;
    late String path;

    setUpAll(() {
      Hive.registerAdapter(_TestLessonFeedbackAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('feedback_repo_test_');
      path = dir.path;
      Hive.init(path);
      repo = LessonFeedbackRepository();
      await repo.init();
    });

    tearDown(() async {
      await repo.box.close();
      await Hive.deleteBoxFromDisk('lesson_feedback');
    });

    test('init opens box and saveFeedback persists', () async {
      final submit = await repo.submitFeedback(
        studentId: 's1',
        targetType: 'lesson',
        sentiment: 'negative',
        reportedIncorrect: true,
      );
      expect(submit.isSuccess, isTrue);

      final byStudent = await repo.getByStudent('s1');
      expect(byStudent.data, hasLength(1));
      expect(byStudent.data!.first.reportedIncorrect, isTrue);
    });

    test('getReported surfaces reported feedback', () async {
      await repo.saveFeedback(makeFeedback(id: 'r1', reportedIncorrect: true));
      await repo.saveFeedback(makeFeedback(id: 'r2', reportedIncorrect: false));
      final reported = await repo.getReported();
      expect(reported.data, hasLength(1));
      expect(reported.data!.first.id, 'r1');
    });

    test('deleteFeedback removes an entry', () async {
      final submit = await repo.submitFeedback(studentId: 's1', targetType: 'explanation');
      final id = submit.data!;
      await repo.deleteFeedback(id);
      final byStudent = await repo.getByStudent('s1');
      expect(byStudent.data, isEmpty);
    });
  });
}

class _TestLessonFeedbackAdapter extends TypeAdapter<LessonFeedbackModel> {
  @override
  final int typeId = 44;

  @override
  LessonFeedbackModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return LessonFeedbackModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      targetType: fields[2] as String? ?? 'explanation',
      lessonId: fields[3] as String?,
      messageId: fields[4] as String?,
      sentiment: fields[5] as String? ?? 'none',
      starRating: fields[6] as int? ?? 0,
      comment: fields[7] as String?,
      reportedIncorrect: fields[8] as bool? ?? false,
      createdAt: fields[9] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, LessonFeedbackModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.targetType)
      ..writeByte(3)
      ..write(obj.lessonId)
      ..writeByte(4)
      ..write(obj.messageId)
      ..writeByte(5)
      ..write(obj.sentiment)
      ..writeByte(6)
      ..write(obj.starRating)
      ..writeByte(7)
      ..write(obj.comment)
      ..writeByte(8)
      ..write(obj.reportedIncorrect)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
