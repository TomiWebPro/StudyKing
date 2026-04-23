import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';

class SubjectRepository {
  Box<Subject>? _subjectBox;

  Box<Subject> get _getSubjectBox {
    if (_subjectBox == null) {
      throw Exception('SubjectRepository not initialized. Call initialize() first.');
    }
    return _subjectBox!;
  }

  Future<void> initialize() async {
    if (!Hive.isBoxOpen('subjects')) {
      await Hive.openBox<Subject>('subjects');
    }
    _subjectBox = Hive.box<Subject>('subjects');
  }

  Future<List<Subject>> getAll() async {
    return _getSubjectBox.values.toList();
  }

  Future<Subject?> get(String id) async {
    return _getSubjectBox.get(id);
  }

  Future<void> save(Subject subject) async {
    await _getSubjectBox.put(subject.id, subject);
  }

  Future<void> delete(String id) async {
    await _getSubjectBox.delete(id);
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

  /// Get subject by code (e.g., 'IB-PHYS')
  Future<Subject?> getByCode(String code) async {
    final subjects = await getAll();
    return subjects.where((s) => s.code == code).firstOrNull;
  }

  /// Get all subjects for a student (could be filtered by student later)
  Future<List<Subject>> getStudentSubjects(String studentId) async {
    // For now, return all subjects
    // This would be more sophisticated with actual student-subject relationships
    return getAll();
  }
}
