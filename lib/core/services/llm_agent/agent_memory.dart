import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/utils/logger.dart';

class AgentMemoryStore {
  static final Logger _logger = const Logger('AgentMemoryStore');
  Box? _box;
  bool _migrated = false;

  Future<void> init() async {
    _box = await Hive.openBox(HiveBoxNames.agentMemory);
    await _migrateFromProfileBox();
  }

  Future<void> _migrateFromProfileBox() async {
    if (_migrated) return;
    _migrated = true;
    try {
      if (!Hive.isBoxOpen(HiveBoxNames.profile)) return;
      final profileBox = Hive.box(HiveBoxNames.profile);
      final agentKeys = profileBox.keys.where(
        (k) => k.toString().startsWith('agent_'),
      ).toList();
      if (agentKeys.isEmpty) return;
      for (final key in agentKeys) {
        final value = profileBox.get(key);
        if (value != null) {
          await _box?.put(key, value);
        }
      }
      for (final key in agentKeys) {
        await profileBox.delete(key);
      }
      _logger.d('Migrated ${agentKeys.length} agent memory keys from profile box');
    } catch (e) {
      _logger.w('Failed to migrate agent memory from profile box', e);
    }
  }

  Future<void> rememberFact(String studentId, String key, String value) async {
    final storeKey = 'agent_fact_${studentId}_$key';
    await _box?.put(storeKey, value);
  }

  String? recallFact(String studentId, String key) {
    final storeKey = 'agent_fact_${studentId}_$key';
    return _box?.get(storeKey) as String?;
  }

  Future<void> storeSessionSummary(String studentId, String sessionId, String summary) async {
    final storeKey = 'agent_session_${studentId}_$sessionId';
    await _box?.put(storeKey, summary);

    final listKey = 'agent_sessions_$studentId';
    final existing = _getSessionList(studentId);
    if (!existing.contains(sessionId)) {
      existing.add(sessionId);
      if (existing.length > 100) {
        existing.removeAt(0);
      }
      await _box?.put(listKey, existing.join(','));
    }
  }

  String? getSessionSummary(String studentId, String sessionId) {
    final storeKey = 'agent_session_${studentId}_$sessionId';
    return _box?.get(storeKey) as String?;
  }

  List<String> getSessionIds(String studentId) {
    return _getSessionList(studentId);
  }

  List<String> _getSessionList(String studentId) {
    final listKey = 'agent_sessions_$studentId';
    final raw = _box?.get(listKey) as String?;
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',');
  }

  Future<void> storeStudentProfile(String studentId, Map<String, dynamic> profile) async {
    final storeKey = 'agent_profile_$studentId';
    await _box?.put(storeKey, jsonEncode(profile));
  }

  Map<String, dynamic>? getStudentProfile(String studentId) {
    final storeKey = 'agent_profile_$studentId';
    final raw = _box?.get(storeKey) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      _logger.w('Failed to decode student profile', e);
      return null;
    }
  }

  Future<void> clearStudentMemory(String studentId) async {
    final keys = _box?.keys.where((k) => k.toString().contains(studentId)).toList() ?? [];
    for (final key in keys) {
      await _box?.delete(key);
    }
  }
}
