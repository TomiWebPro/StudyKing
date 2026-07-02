import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';

class FocusSessionRepository {
  static final Logger _logger = const Logger('FocusSessionRepository');
  Box<String>? _box;

  Future<Result<void>> init() async {
    return Result.capture(() async {
      _box = await Hive.openBox<String>(HiveBoxNames.focusSessions);
    }, context: 'FocusSessionRepository.init');
  }

  Box<String> get _ensureBox {
    if (_box == null) {
      throw StateError('FocusSessionRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  Future<Result<void>> save(FocusSession session) async {
    try {
      final json = jsonEncode(session.toJson());
      await _ensureBox.put(session.id, json);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to save FocusSession: $e');
      return Result.failure('FocusSessionRepository.save: $e');
    }
  }

  Future<Result<FocusSession?>> get(String key) async {
    try {
      final json = _ensureBox.get(key);
      if (json == null) return Result.success(null);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return Result.success(FocusSession.fromJson(decoded));
    } catch (e) {
      _logger.w('Failed to get FocusSession: $e');
      return Result.failure('FocusSessionRepository.get: $e');
    }
  }

  Future<Result<List<FocusSession>>> getAll() async {
    try {
      final sessions = <FocusSession>[];
      for (final entry in _ensureBox.toMap().entries) {
        try {
          final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
          sessions.add(FocusSession.fromJson(decoded));
        } catch (e) {
          _logger.w('Failed to decode focus session ${entry.key}: $e');
        }
      }
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return Result.success(sessions);
    } catch (e) {
      _logger.w('Failed to get all FocusSessions: $e');
      return Result.failure('FocusSessionRepository.getAll: $e');
    }
  }

  Future<Result<FocusSession?>> getLatest() async {
    try {
      final all = await getAll();
      if (all.isFailure) return Result.failure(all.error);
      final sessions = all.data!;
      return Result.success(sessions.isNotEmpty ? sessions.first : null);
    } catch (e) {
      _logger.w('Failed to get latest FocusSession: $e');
      return Result.failure('FocusSessionRepository.getLatest: $e');
    }
  }
}
