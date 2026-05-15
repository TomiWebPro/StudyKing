import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  Future<void> save(String key, T item) async {
    await _box.put(key, item);
  }

  Future<T?> get(String key) async {
    return _box.get(key);
  }

  Future<List<T>> getAll() async {
    return _box.values.toList();
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  @protected
  List<T> filterBy<K>(K Function(T) getter, K value) {
    return _box.values.where((item) => getter(item) == value).toList();
  }

  Box<T> get box => _box;
}
