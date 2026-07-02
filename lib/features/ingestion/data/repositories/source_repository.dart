import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/repository.dart';

class SourceRepository extends Repository<Source> {
  SourceRepository() : super(boxName: HiveBoxNames.sources);

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

  Future<List<Source>> getBySubject(String subjectId) async {
    await _ensureReady();
    return filterBy((s) => s.subjectId, subjectId);
  }

  Future<List<Source>> getByTopic(String topicId) async {
    await _ensureReady();
    return filterBy((s) => s.topicId, topicId);
  }

  Future<List<Source>> getByStudent(String studentId) async {
    await _ensureReady();
    return filterBy((s) => s.studentId, studentId);
  }

  Future<List<Source>> getByType(String sourceType) async {
    await _ensureReady();
    return box.values.where((s) => s.type.name == sourceType).toList();
  }

  Future<List<Source>> getByStatus(ProcessingStatus status) async {
    await _ensureReady();
    return box.values.where((s) => s.statusEnum == status).toList();
  }

  Future<List<Source>> getPending() async {
    return getByStatus(ProcessingStatus.pending);
  }

  Future<List<Source>> getFailed() async {
    return getByStatus(ProcessingStatus.failed);
  }

  Future<List<Source>> getCompleted() async {
    return getByStatus(ProcessingStatus.completed);
  }
}
