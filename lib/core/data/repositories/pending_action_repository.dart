import 'package:hive_flutter/hive_flutter.dart';
import '../models/pending_action_model.dart';

class PendingActionRepository {
  late Box<PendingActionModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<PendingActionModel>('pending_actions');
  }

  Future<void> save(PendingActionModel action) async {
    await _box.put(action.id, action);
  }

  Future<PendingActionModel?> get(String id) async {
    return _box.get(id);
  }

  Future<List<PendingActionModel>> getPending(String studentId) async {
    return _box.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markCompleted(String id) async {
    final action = _box.get(id);
    if (action != null) {
      await _box.put(id, action.copyWith(status: 'completed'));
    }
  }

  Future<void> markRejected(String id) async {
    final action = _box.get(id);
    if (action != null) {
      await _box.put(id, action.copyWith(status: 'rejected'));
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll(String studentId) async {
    final actions = _box.values
        .where((a) => a.studentId == studentId)
        .toList();
    for (final action in actions) {
      await _box.delete(action.id);
    }
  }

  Future<bool> hasPending(String studentId) async {
    return _box.values
        .any((a) => a.studentId == studentId && a.status == 'pending');
  }
}
