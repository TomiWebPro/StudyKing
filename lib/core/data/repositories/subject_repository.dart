import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/subject_model.dart';

class SubjectRepository {
  Box<Subject>? _subjectBox;

  SubjectRepository({Box<Subject>? subjectBox}) : _subjectBox = subjectBox;

  Future<void> init() async {
    _subjectBox = Hive.box<Subject>('subjects');
  }

  Box<Subject> get _box {
    if (_subjectBox == null) {
      throw StateError('SubjectRepository not initialized. Call init() first or inject a Box.');
    }
    return _subjectBox!;
  }

  Future<List<Subject>> getAll() async {
    return _box.values.toList();
  }

  Future<Subject?> get(String id) async {
    return _box.get(id);
  }

  Future<void> save(Subject subject) async {
    await _box.put(subject.id, subject);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<List<Subject>> getWithTopics(List<String> topicIds) async {
    final subjects = await getAll();
    return subjects.where((s) {
      return s.topicIds.any((id) => topicIds.contains(id));
    }).toList();
  }

  Future<void> addTopicToSubject(String subjectId, String topicId) async {
    final subject = await get(subjectId);
    if (subject != null) {
      if (subject.topicIds.contains(topicId)) {
        return;
      }
      final updated = subject.copyWith(
        topicIds: [...subject.topicIds, topicId],
      );
      await save(updated);
    }
  }

  Future<void> removeTopicFromSubject(String subjectId, String topicId) async {
    final subject = await get(subjectId);
    if (subject != null) {
      final updated = subject.copyWith(
        topicIds: subject.topicIds.where((id) => id != topicId).toList(),
      );
      await save(updated);
    }
  }

  Future<Subject?> getByCode(String code) async {
    final subjects = await getAll();
    return subjects.where((s) => s.code == code).firstOrNull;
  }
}
