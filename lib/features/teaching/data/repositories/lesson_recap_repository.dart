import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';

class LessonRecapRepository extends Repository<LessonRecapModel> {
  LessonRecapRepository() : super(boxName: HiveBoxNames.lessonRecaps);

  Future<void> init() async {
    await openBox(HiveBoxNames.lessonRecaps);
  }

  Future<Result<void>> create(LessonRecapModel recap) async {
    return super.put(recap.id, recap);
  }

  Future<Result<void>> saveRecap(LessonRecapModel recap) async {
    return create(recap);
  }

  Future<Result<LessonRecapModel?>> getRecap(String id) async {
    return super.get(id);
  }

  Future<Result<LessonRecapModel?>> getBySession(String sessionId) async {
    return Result.capture(() async {
      final allResult = await getAll();
      final all = allResult.data ?? [];
      for (final recap in all) {
        if (recap.sessionId == sessionId) return recap;
      }
      return null;
    }, context: 'getBySession');
  }

  Future<Result<LessonRecapModel?>> getByLesson(String lessonId) async {
    return Result.capture(() async {
      final allResult = await getAll();
      final all = allResult.data ?? [];
      for (final recap in all) {
        if (recap.lessonId == lessonId) return recap;
      }
      return null;
    }, context: 'getByLesson');
  }

  Future<Result<List<LessonRecapModel>>> getStudentRecaps(
      String studentId) async {
    return Result.capture(() async {
      final allResult = await getAll();
      final all = allResult.data ?? [];
      final matching = all.where((r) => r.studentId == studentId).toList();
      matching.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return matching;
    }, context: 'getStudentRecaps');
  }

  Future<Result<void>> deleteForSession(String sessionId) async {
    return Result.capture(() async {
      final existing = await getBySession(sessionId);
      if (existing.data != null) {
        await delete(existing.data!.id);
      }
    }, context: 'deleteForSession');
  }

  Future<Result<void>> clearAll() async {
    return Result.capture(() async {
      await box.clear();
    }, context: 'clearAll');
  }
}
