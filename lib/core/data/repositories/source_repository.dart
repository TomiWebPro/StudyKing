import 'package:hive_flutter/hive_flutter.dart';
import '../models/source_model.dart';

class SourceRepository {
  late Box<Source> _box;

  Future<void> init() async {
    _box = Hive.box<Source>('sources');
  }

  Future<void> create(Source source) async {
    await _box.put(source.id, source);
  }

  Future<Source?> get(String id) async {
    return _box.get(id);
  }

  Future<List<Source>> getAll() async {
    return _box.values.toList();
  }

  Future<List<Source>> getBySubject(String subjectId) async {
    return _box.values.where((s) => s.subjectId == subjectId).toList();
  }

  Future<List<Source>> getByTopic(String topicId) async {
    return _box.values.where((s) => s.topicId == topicId).toList();
  }

  Future<List<Source>> getByStudent(String studentId) async {
    return _box.values.where((s) => s.studentId == studentId).toList();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<List<Source>> getByType(String sourceType) async {
    return _box.values.where((s) => s.type.name == sourceType).toList();
  }
}
