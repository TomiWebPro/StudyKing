import 'package:hive_flutter/hive_flutter.dart';
import '../models/study_session_model.dart';

class SessionRepository {
  late Box<StudySession> _box;

  Future<void> init() async {
    _box = Hive.box<StudySession>('sessions');
  }

  Future<void> create(StudySession session) async {
    await _box.put(session.id, session);
  }

  Future<StudySession?> get(String id) async {
    return _box.get(id);
  }

  Future<List<StudySession>> getAll() async {
    return _box.values.toList();
  }

  Future<void> endSession(String id) async {
    final session = await get(id);
    if (session != null) {
      final updated = session.copyWith(endTime: DateTime.now());
      await _box.put(id, updated);
    }
  }
}
