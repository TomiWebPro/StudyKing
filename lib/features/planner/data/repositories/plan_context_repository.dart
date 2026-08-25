import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Persists the "active plan id" selection per student so that switching the
/// active study plan context survives app restarts.
class PlanContextRepository {
  static final Logger _logger = const Logger('PlanContextRepository');
  Box? _box;

  Result<Box> _requireBox() {
    final box = _box;
    if (box == null) {
      return Result.failure('PlanContextRepository not initialized');
    }
    return Result.success(box);
  }

  Future<Result<void>> init() async {
    try {
      if (Hive.isBoxOpen(HiveBoxNames.planContext)) {
        _box = Hive.box(HiveBoxNames.planContext);
      } else {
        _box = await Hive.openBox(HiveBoxNames.planContext);
      }
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to initialize plan context repository', e);
      return Result.failure('Failed to initialize plan context repository: $e');
    }
  }

  Future<Result<String?>> getActivePlanId(String studentId) async {
    final boxResult = _requireBox();
    if (boxResult.isFailure) return Result.failure(boxResult.error);
    try {
      final value = boxResult.data!.get(studentId) as String?;
      return Result.success(value);
    } catch (e) {
      _logger.w('Failed to read active plan id', e);
      return Result.failure('Failed to read active plan id: $e');
    }
  }

  Future<Result<void>> setActivePlanId(String studentId, String planId) async {
    final boxResult = _requireBox();
    if (boxResult.isFailure) return Result.failure(boxResult.error);
    try {
      await boxResult.data!.put(studentId, planId);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to set active plan id', e);
      return Result.failure('Failed to set active plan id: $e');
    }
  }

  Future<Result<void>> clearActivePlanId(String studentId) async {
    final boxResult = _requireBox();
    if (boxResult.isFailure) return Result.failure(boxResult.error);
    try {
      await boxResult.data!.delete(studentId);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to clear active plan id', e);
      return Result.failure('Failed to clear active plan id: $e');
    }
  }
}
