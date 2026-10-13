import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

class PendingActionRepository extends Repository<PendingActionModel> {
  static final Logger _logger = const Logger('PendingActionRepository');
  PendingActionRepository() : super(boxName: HiveBoxNames.pendingActions);

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
    try {
      final action = box.get(id);
      if (action == null) return Result.success(null);
      final result = await super.save(id, action.copyWith(status: 'completed'));
      if (result.isFailure) {
        _logger.w('Failed to complete pending action $id', result.error);
      }
      return result;
    } catch (e) {
      _logger.w('Failed to complete pending action $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> markRejected(String id) async {
    try {
      final action = box.get(id);
      if (action == null) return Result.success(null);
      final result = await super.save(id, action.copyWith(status: 'rejected'));
      if (result.isFailure) {
        _logger.w('Failed to reject pending action $id', result.error);
      }
      return result;
    } catch (e) {
      _logger.w('Failed to reject pending action $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> clearAll(String studentId) async {
    try {
      final actions = filterBy((a) => a.studentId, studentId);
      for (final action in actions) {
        final result = await super.delete(action.id);
        if (result.isFailure) {
          _logger.w(
              'Failed to clear pending action ${action.id}', result.error);
          return result;
        }
      }
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to clear pending actions for $studentId', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> hasPending(String studentId) async {
    return Result.capture(() async {
      final byStudent = filterBy((a) => a.studentId, studentId);
      return byStudent.any((a) => a.status == 'pending');
    }, context: 'PendingActionRepository.hasPending');
  }
}
