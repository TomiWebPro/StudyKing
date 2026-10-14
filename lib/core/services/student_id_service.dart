import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/clock.dart';

/// Calendar-day difference `a - b` in whole days. Both
/// arguments are local timestamps; the computation is done
/// on UTC-normalized dates so a DST transition (a 23h or
/// 25h calendar day) cannot shift the result the way
/// elapsed-time `difference().inDays` does.
int _calendarDayDiff(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcA.difference(utcB).inDays;
}

class StudentIdService {
  StudentIdService({Clock? clock}) : _clock = clock ?? SystemClock();

  static const _boxName = HiveBoxNames.studentId;
  static const _idKey = 'id';
  static const _lastActivityKey = 'lastActivityAt';
  final Clock _clock;
  Box? _box;
  String? _cachedId;
  int? _capturedDaysSinceLastActivity;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _cachedId = null;
  }

  Result<String> getStudentId() {
    return Result.captureSync(() {
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
    }, context: 'getStudentId');
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
    final now = _clock.now();
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
    // Calendar-day count, not elapsed 24h periods:
    // `difference().inDays` truncates a 23h/25h DST day,
    // so a 3-calendar-day absence spanning a spring-forward
    // computes as 2 days and every absence gate that reads
    // this value (dashboard banner, adherence deviation,
    // plan auto-extension, redistribution window) fires a
    // full day late. UTC normalization makes the day count
    // exact in every timezone.
    final now = _clock.now();
    return _calendarDayDiff(now, last);
  }
}


