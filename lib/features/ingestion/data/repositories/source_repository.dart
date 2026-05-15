import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/repository.dart';

class SourceRepository extends Repository<Source> {
  Future<void> init() async {
    await openBox(HiveBoxNames.sources);
  }

  Future<void> create(Source source) async {
    await save(source.id, source);
  }

  Future<List<Source>> getBySubject(String subjectId) async {
    return filterBy((s) => s.subjectId, subjectId);
  }

  Future<List<Source>> getByTopic(String topicId) async {
    return filterBy((s) => s.topicId, topicId);
  }

  Future<List<Source>> getByStudent(String studentId) async {
    return filterBy((s) => s.studentId, studentId);
  }

  Future<List<Source>> getByType(String sourceType) async {
    return box.values.where((s) => s.type.name == sourceType).toList();
  }
}
