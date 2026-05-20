import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/data/hive_box_names.dart';

class StudentIdService {
  StudentIdService();

  static const _boxName = HiveBoxNames.studentId;
  static const _idKey = 'id';
  static const _lastActivityKey = 'lastActivityAt';
  Box? _box;
  String? _cachedId;
  int? _capturedDaysSinceLastActivity;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _cachedId = null;
  }

  String getStudentId() {
    if (_cachedId != null && _cachedId!.isNotEmpty) return _cachedId!;
    if (_box != null && _box!.isOpen) {
      final existing = _box!.get(_idKey) as String?;
      if (existing != null && existing.isNotEmpty) {
        _cachedId = existing;
        return existing;
      }
    }
    final newId = const Uuid().v4();
    _cachedId = newId;
    if (_box != null && _box!.isOpen) {
      _box!.put(_idKey, newId);
    }
    return newId;
  }

  void setStudentId(String id) {
    _cachedId = id;
    if (_box != null && _box!.isOpen) {
      _box!.put(_idKey, id);
    }
  }

  DateTime? getLastActivityAt() {
    if (_box != null && _box!.isOpen) {
      final raw = _box!.get(_lastActivityKey);
      if (raw is String) return DateTime.tryParse(raw);
      if (raw is DateTime) return raw;
    }
    return null;
  }

  Future<void> updateLastActivity() async {
    _capturedDaysSinceLastActivity = getDaysSinceLastActivity();
    final now = DateTime.now();
    if (_box != null && _box!.isOpen) {
      await _box!.put(_lastActivityKey, now.toIso8601String());
    }
  }

  int getDaysSinceLastActivity() {
    if (_capturedDaysSinceLastActivity != null) {
      return _capturedDaysSinceLastActivity!;
    }
    final last = getLastActivityAt();
    if (last == null) return -1;
    return DateTime.now().difference(last).inDays;
  }
}


