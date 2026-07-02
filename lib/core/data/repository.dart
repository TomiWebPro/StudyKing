import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../errors/result.dart';
import '../utils/logger.dart';

/// All repositories MUST wrap their public method return types in [Result].
/// See [Result] in `core/errors/result.dart`.
/// This ensures consistent error handling across all feature repositories.
class Repository<T> {
  static final Logger _logger = const Logger('Repository');
  Box<T>? _box;
  String? _boxName;

  Repository({String? boxName}) {
    _boxName = boxName;
  }

  bool get isOpen => _box != null;

  Box<T> _requireBox() {
    if (_box != null) return _box!;
    if (_boxName != null && Hive.isBoxOpen(_boxName!)) {
      _box = Hive.box<T>(_boxName!);
      return _box!;
    }
    if (_boxName != null) {
      throw StateError('Box "$_boxName" is not open. Ensure HiveInitializer.initialize() has been called.');
    }
    throw StateError('Repository not initialized. Call openBox(boxName) or attachBox() first.');
  }

  Future<void> openBox(String boxName) async {
    _boxName = boxName;
    try {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box<T>(boxName);
      } else {
        _box = await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      final existing = Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;
      if (existing != null) {
        await existing.close();
      }
      _box = await Hive.openBox<T>(boxName);
    }
  }

  void attachBox(Box<T> box) {
    _box = box;
  }

  Future<Result<void>> save(String key, T item) async {
    return put(key, item);
  }

  Future<Result<void>> put(String key, T item) async {
    try {
      await _requireBox().put(key, item);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to put: $e', e);
      return Result.failure('Failed to put: $e');
    }
  }

  Future<Result<T?>> get(String key) async {
    try {
      final item = _requireBox().get(key);
      return Result.success(item);
    } catch (e) {
      _logger.w('Failed to get: $e', e);
      return Result.failure('Failed to get: $e');
    }
  }

  Future<Result<List<T>>> getAll() async {
    try {
      final items = _requireBox().values.toList();
      return Result.success(items);
    } catch (e) {
      _logger.w('Failed to get all: $e', e);
      return Result.failure('Failed to get all: $e');
    }
  }

  Future<Result<void>> delete(String key) async {
    try {
      await _requireBox().delete(key);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to delete: $e', e);
      return Result.failure('Failed to delete: $e');
    }
  }

  @protected
  List<T> filterBy<K>(K Function(T) getter, K value) {
    return _requireBox().values.where((item) => getter(item) == value).toList();
  }

  Box<T> get box => _requireBox();
}
