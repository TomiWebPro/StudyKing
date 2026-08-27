import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class SubjectRepository extends Repository<Subject> {
  static final Logger _logger = const Logger('SubjectRepository');

  SubjectRepository() : super(boxName: HiveBoxNames.subjects);

  Future<void> init() async {
    await openBox(HiveBoxNames.subjects);
  }

  Future<Result<void>> create(Subject subject) async {
    return super.put(subject.id, subject);
  }

  Future<Result<List<Subject>>> getWithTopics(List<String> topicIds) async {
    try {
      final getAllResult = await getAll();
      final subjects = getAllResult.data ?? [];
      final filtered = subjects.where((s) {
        return s.topicIds.any((id) => topicIds.contains(id));
      }).toList();
      return Result.success(filtered);
    } catch (e, stackTrace) {
      _logger.w('Failed to get subjects with topics', e, stackTrace);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> addTopicToSubject(
      String subjectId, String topicId) async {
    try {
      final getResult = await get(subjectId);
      final subject = getResult.data;
      if (subject != null) {
        if (subject.topicIds.contains(topicId)) {
          return Result.success(null);
        }
        final updated = subject.copyWith(
          topicIds: [...subject.topicIds, topicId],
        );
        return await super.put(subjectId, updated);
      }
      return Result.success(null);
    } catch (e, stackTrace) {
      _logger.w('Failed to add topic to subject', e, stackTrace);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> removeTopicFromSubject(
      String subjectId, String topicId) async {
    try {
      final getResult = await get(subjectId);
      final subject = getResult.data;
      if (subject != null) {
        final updated = subject.copyWith(
          topicIds: subject.topicIds.where((id) => id != topicId).toList(),
        );
        return await super.put(subjectId, updated);
      }
      return Result.success(null);
    } catch (e, stackTrace) {
      _logger.w('Failed to remove topic from subject', e, stackTrace);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Subject?>> getByCode(String code) async {
    try {
      final getAllResult = await getAll();
      final subjects = getAllResult.data ?? [];
      return Result.success(
          subjects.where((s) => s.code == code).firstOrNull);
    } catch (e, stackTrace) {
      _logger.w('Failed to get subject by code', e, stackTrace);
      return Result.failure(e.toString());
    }
  }
}
