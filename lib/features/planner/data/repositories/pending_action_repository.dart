import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

class PendingActionRepository extends Repository<PendingActionModel> {
  Future<Result<void>> init() async {
    return Result.capture(() async {
      await openBox(HiveBoxNames.pendingActions);
    }, context: 'PendingActionRepository.init');
  }

  Future<Result<void>> create(PendingActionModel action) async {
    return super.save(action.id, action);
  }

  Future<Result<List<PendingActionModel>>> getPending(String studentId) async {
    return Result.capture(() async {
      final byStudent = filterBy((a) => a.studentId, studentId);
      return byStudent.where((a) => a.status == 'pending').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }, context: 'PendingActionRepository.getPending');
  }

  Future<Result<void>> markCompleted(String id) async {
    return Result.capture(() async {
      final action = box.get(id);
      if (action != null) {
        await super.save(id, action.copyWith(status: 'completed'));
      }
    }, context: 'PendingActionRepository.markCompleted');
  }

  Future<Result<void>> markRejected(String id) async {
    return Result.capture(() async {
      final action = box.get(id);
      if (action != null) {
        await super.save(id, action.copyWith(status: 'rejected'));
      }
    }, context: 'PendingActionRepository.markRejected');
  }

  Future<Result<void>> clearAll(String studentId) async {
    return Result.capture(() async {
      final actions = filterBy((a) => a.studentId, studentId);
      for (final action in actions) {
        await super.delete(action.id);
      }
    }, context: 'PendingActionRepository.clearAll');
  }

  Future<Result<bool>> hasPending(String studentId) async {
    return Result.capture(() async {
      final byStudent = filterBy((a) => a.studentId, studentId);
      return byStudent.any((a) => a.status == 'pending');
    }, context: 'PendingActionRepository.hasPending');
  }
}
