import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../errors/result.dart';

/// All repositories MUST wrap their public method return types in [Result].
/// See [Result] in `core/errors/result.dart`.
/// This ensures consistent error handling across all feature repositories.
class Repository<T> {
  late Box<T> _box;

  Future<void> openBox(String boxName) async {
    _box = await Hive.openBox<T>(boxName);
  }

  void attachBox(Box<T> box) {
    _box = box;
  }

  Future<Result<void>> save(String key, T item) async {
    try {
      await _box.put(key, item);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to save: $e');
    }
  }

  Future<Result<T?>> get(String key) async {
    try {
      final item = _box.get(key);
      return Result.success(item);
    } catch (e) {
      return Result.failure('Failed to get: $e');
    }
  }

  Future<Result<List<T>>> getAll() async {
    try {
      final items = _box.values.toList();
      return Result.success(items);
    } catch (e) {
      return Result.failure('Failed to get all: $e');
    }
  }

  Future<Result<void>> delete(String key) async {
    try {
      await _box.delete(key);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to delete: $e');
    }
  }

  @protected
  List<T> filterBy<K>(K Function(T) getter, K value) {
    return _box.values.where((item) => getter(item) == value).toList();
  }

  Box<T> get box => _box;
}
