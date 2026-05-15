import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

class StudyTimerService {
  final Logger _logger = const Logger('StudyTimerService');
  final SessionRepository _repository;
  Timer? _timer;
  Session? _currentSession;
  int _elapsedMs = 0;
  bool _isPaused = false;
  final List<void Function(Session)> _onSessionComplete = [];
  final List<void Function(int elapsedMs)> _onTick = [];

  StudyTimerService({required SessionRepository repository})
      : _repository = repository;

  SessionRepository get repository => _repository;
  Session? get currentSession => _currentSession;
  int get elapsedMs => _elapsedMs;
  int get elapsedSeconds => _elapsedMs ~/ 1000;
  bool get isPaused => _isPaused;
  bool get hasActiveSession => _currentSession != null;

  void addOnSessionComplete(void Function(Session) callback) {
    _onSessionComplete.add(callback);
  }

  void removeOnSessionComplete(void Function(Session) callback) {
    _onSessionComplete.remove(callback);
  }

  void addOnTick(void Function(int elapsedMs) callback) {
    _onTick.add(callback);
  }

  void removeOnTick(void Function(int elapsedMs) callback) {
    _onTick.remove(callback);
  }

  Future<int> getDailyCapMinutes() async {
    try {
      final box = Hive.box(HiveBoxNames.settings);
      return box.get('dailyCapMinutes', defaultValue: 0);
    } catch (_) {
      return 0;
    }
  }

  Future<bool> isDailyCapReached(int additionalMinutes) async {
    final capMinutes = await getDailyCapMinutes();
    if (capMinutes <= 0) return false;
    final todayStats = await _repository.getTodayStats();
    final todayMinutes = (todayStats['totalMs'] as int? ?? 0) ~/ 60000;
    return (todayMinutes + additionalMinutes) > capMinutes;
  }

  Future<int> getRemainingDailyCapMinutes() async {
    final capMinutes = await getDailyCapMinutes();
    if (capMinutes <= 0) return -1;
    final todayStats = await _repository.getTodayStats();
    final todayMinutes = (todayStats['totalMs'] as int? ?? 0) ~/ 60000;
    return capMinutes - todayMinutes;
  }

  Future<Session> startSession({
    required int plannedDurationMinutes,
    SessionType type = SessionType.focus,
    String? studentId,
    String? subjectId,
    String? topicId,
  }) async {
    if (_currentSession != null) {
      await cancelSession();
    }

    final now = DateTime.now();
    _currentSession = Session(
      id: '${type.name}_${now.millisecondsSinceEpoch}_${plannedDurationMinutes}m',
      studentId: studentId ?? '',
      subjectId: subjectId,
      topicId: topicId,
      type: type,
      startTime: now,
      plannedDurationMinutes: plannedDurationMinutes,
    );

    _elapsedMs = 0;
    _isPaused = false;
    _startTimer();

    await _repository.save(_currentSession!);
    _logger.i('Session started: ${_currentSession!.id} type: ${type.name}');
    return _currentSession!;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _elapsedMs += 1000;
        for (final cb in _onTick) {
          cb(_elapsedMs);
        }

        if (_currentSession!.plannedDurationMinutes != null &&
            _elapsedMs ~/ 1000 >= _currentSession!.plannedDurationMinutes! * 60) {
          completeSession();
        }
      }
    });
  }

  void pauseSession() {
    if (_currentSession == null) return;
    _isPaused = true;
    _logger.i('Session paused');
  }

  void resumeSession() {
    if (_currentSession == null) return;
    _isPaused = false;
    _logger.i('Session resumed');
  }

  Future<Session> completeSession() async {
    if (_currentSession == null) {
      throw StateError('No active session');
    }

    _timer?.cancel();
    final now = DateTime.now();
    _currentSession = _currentSession!.copyWith(
      endTime: now,
      actualDurationMs: _elapsedMs,
      completed: true,
    );

    await _repository.save(_currentSession!);
    final completed = _currentSession!;
    _currentSession = null;
    _elapsedMs = 0;
    _isPaused = false;

    for (final cb in _onSessionComplete) {
      cb(completed);
    }

    _logger.i('Session completed: ${completed.id}');
    return completed;
  }

  Future<Session> cancelSession() async {
    if (_currentSession == null) {
      throw StateError('No active session');
    }

    _timer?.cancel();
    final now = DateTime.now();
    _currentSession = _currentSession!.copyWith(
      endTime: now,
      actualDurationMs: _elapsedMs,
      completed: false,
    );

    await _repository.save(_currentSession!);
    final cancelled = _currentSession!;
    _currentSession = null;
    _elapsedMs = 0;
    _isPaused = false;

    _logger.i('Session cancelled: ${cancelled.id}');
    return cancelled;
  }

  Future<int> getTodayDurationMs() async {
    return _repository.getTodayDurationMs();
  }

  Future<int> getTodaySessionCount() async {
    return _repository.getTodaySessionCount();
  }

  Future<int> getTodayCompletedSessionCount() async {
    return _repository.getTodayCompletedSessionCount();
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    return _repository.getTodayStats();
  }

  Future<List<Session>> getRecentSessions({int limit = 10}) async {
    final all = await _repository.getAll();
    return all.take(limit).toList();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
  }
}
