import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/repository.dart';

class SubjectRepository extends Repository<Subject> {
  Future<void> init() async {
    await openBox(HiveBoxNames.subjects);
  }

  Future<void> create(Subject subject) async {
    await save(subject.id, subject);
  }

  Future<List<Subject>> getWithTopics(List<String> topicIds) async {
    final getAllResult = await getAll();
    final subjects = getAllResult.data ?? [];
    return subjects.where((s) {
      return s.topicIds.any((id) => topicIds.contains(id));
    }).toList();
  }

  Future<void> addTopicToSubject(String subjectId, String topicId) async {
    final getResult = await get(subjectId);
    final subject = getResult.data;
    if (subject != null) {
      if (subject.topicIds.contains(topicId)) {
        return;
      }
      final updated = subject.copyWith(
        topicIds: [...subject.topicIds, topicId],
      );
      await save(subjectId, updated);
    }
  }

  Future<void> removeTopicFromSubject(
      String subjectId, String topicId) async {
    final getResult = await get(subjectId);
    final subject = getResult.data;
    if (subject != null) {
      final updated = subject.copyWith(
        topicIds: subject.topicIds.where((id) => id != topicId).toList(),
      );
      await save(subjectId, updated);
    }
  }

  Future<Subject?> getByCode(String code) async {
    final getAllResult = await getAll();
    final subjects = getAllResult.data ?? [];
    return subjects.where((s) => s.code == code).firstOrNull;
  }
}
