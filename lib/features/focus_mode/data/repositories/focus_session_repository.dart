import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/utils/logger.dart';
import '../models/focus_session_model.dart';

class FocusSessionRepository {
  final Logger _logger = const Logger('FocusSessionRepository');

  Box<String> get _box => Hive.box<String>('focus_sessions');

  Future<void> init() async {}

  Future<void> save(FocusSession session) async {
    await _box.put(session.id, jsonEncode(session.toJson()));
  }

  Future<FocusSession?> get(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      return FocusSession.fromJson(jsonDecode(raw));
    } catch (e) {
      _logger.e('Error decoding session $id', e);
      return null;
    }
  }

  Future<List<FocusSession>> getAll() async {
    final sessions = <FocusSession>[];
    for (final raw in _box.values) {
      try {
        sessions.add(FocusSession.fromJson(jsonDecode(raw)));
      } catch (e) {
        _logger.e('Error decoding session', e);
      }
    }
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<List<FocusSession>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final all = await getAll();
    return all.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
  }

  Future<List<FocusSession>> getActive() async {
    final all = await getAll();
    return all.where((s) => s.isActive).toList();
  }

  Future<void> update(String id, FocusSession session) async {
    await save(session);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
