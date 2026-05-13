import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class StudentIdService {
  static final StudentIdService _instance = StudentIdService._internal();
  factory StudentIdService() => _instance;
  StudentIdService._internal();

  static const _boxName = 'student_id';
  static const _key = 'id';
  Box? _box;
  String? _cachedId;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  String getStudentId() {
    if (_cachedId != null && _cachedId!.isNotEmpty) return _cachedId!;
    if (_box != null) {
      final existing = _box!.get(_key) as String?;
      if (existing != null && existing.isNotEmpty) {
        _cachedId = existing;
        return existing;
      }
    }
    final newId = const Uuid().v4();
    _cachedId = newId;
    _box?.put(_key, newId);
    return newId;
  }

  void setStudentId(String id) {
    _cachedId = id;
    _box?.put(_key, id);
  }
}

final studentIdServiceProvider = Provider<StudentIdService>((ref) {
  return StudentIdService();
});

final studentIdProvider = FutureProvider<String>((ref) async {
  final service = ref.read(studentIdServiceProvider);
  await service.init();
  return service.getStudentId();
});

final studentIdValueProvider = Provider<String>((ref) {
  return ref.watch(studentIdProvider).valueOrNull ?? '';
});
