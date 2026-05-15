import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

class PendingActionRepository extends Repository<PendingActionModel> {
  Future<void> init() async {
    await openBox(HiveBoxNames.pendingActions);
  }

  Future<void> create(PendingActionModel action) async {
    await super.save(action.id, action);
  }

  Future<List<PendingActionModel>> getPending(String studentId) async {
    final byStudent = filterBy((a) => a.studentId, studentId);
    return byStudent.where((a) => a.status == 'pending').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markCompleted(String id) async {
    final action = box.get(id);
    if (action != null) {
      await super.save(id, action.copyWith(status: 'completed'));
    }
  }

  Future<void> markRejected(String id) async {
    final action = box.get(id);
    if (action != null) {
      await super.save(id, action.copyWith(status: 'rejected'));
    }
  }

  Future<void> clearAll(String studentId) async {
    final actions = filterBy((a) => a.studentId, studentId);
    for (final action in actions) {
      await super.delete(action.id);
    }
  }

  Future<bool> hasPending(String studentId) async {
    final byStudent = filterBy((a) => a.studentId, studentId);
    return byStudent.any((a) => a.status == 'pending');
  }
}
