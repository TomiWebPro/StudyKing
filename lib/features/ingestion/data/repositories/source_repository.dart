import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class SourceRepository extends Repository<Source> {
  SourceRepository() : super(boxName: HiveBoxNames.sources);

  static final Logger _logger = const Logger('SourceRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.sources);
  }

  Future<void> _ensureReady() async {
    if (!isOpen) await init();
  }

  Future<void> create(Source source) async {
    await _ensureReady();
    await save(source.id, source);
  }

  Future<Result<List<Source>>> getBySubject(String subjectId) async {
    try {
      await _ensureReady();
      return Result.success(filterBy((s) => s.subjectId, subjectId));
    } catch (e) {
      _logger.w('Failed to get sources by subject: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByTopic(String topicId) async {
    try {
      await _ensureReady();
      return Result.success(filterBy((s) => s.topicId, topicId));
    } catch (e) {
      _logger.w('Failed to get sources by topic: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByStudent(String studentId) async {
    try {
      await _ensureReady();
      return Result.success(filterBy((s) => s.studentId, studentId));
    } catch (e) {
      _logger.w('Failed to get sources by student: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByType(String sourceType) async {
    try {
      await _ensureReady();
      return Result.success(box.values.where((s) => s.type.name == sourceType).toList());
    } catch (e) {
      _logger.w('Failed to get sources by type: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByStatus(ProcessingStatus status) async {
    try {
      await _ensureReady();
      return Result.success(box.values.where((s) => s.statusEnum == status).toList());
    } catch (e) {
      _logger.w('Failed to get sources by status: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getPending() async {
    return getByStatus(ProcessingStatus.pending);
  }

  Future<Result<List<Source>>> getFailed() async {
    return getByStatus(ProcessingStatus.failed);
  }

  Future<Result<List<Source>>> getCompleted() async {
    return getByStatus(ProcessingStatus.completed);
  }
}
