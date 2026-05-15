import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';

class FocusSessionService {
  final Logger _logger = const Logger('FocusSessionService');
  final FocusSessionRepository _repository;
  Timer? _timer;
  FocusSession? _currentSession;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  final List<void Function(FocusSession)> _onSessionComplete = [];
  final List<void Function(int elapsed)> _onTick = [];

  FocusSessionService({required FocusSessionRepository repository})
      : _repository = repository;

  FocusSessionRepository get repository => _repository;
  FocusSession? get currentSession => _currentSession;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isPaused => _isPaused;
  bool get hasActiveSession => _currentSession != null;

  void addOnSessionComplete(void Function(FocusSession) callback) {
    _onSessionComplete.add(callback);
  }

  void removeOnSessionComplete(void Function(FocusSession) callback) {
    _onSessionComplete.remove(callback);
  }

  void addOnTick(void Function(int elapsed) callback) {
    _onTick.add(callback);
  }

  void removeOnTick(void Function(int elapsed) callback) {
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
    final todaySeconds = await getTodayFocusSeconds();
    final todayMinutes = todaySeconds ~/ 60;
    return (todayMinutes + additionalMinutes) > capMinutes;
  }

  Future<int> getRemainingDailyCapMinutes() async {
    final capMinutes = await getDailyCapMinutes();
    if (capMinutes <= 0) return -1;
    final todaySeconds = await getTodayFocusSeconds();
    return capMinutes - (todaySeconds ~/ 60);
  }

  Future<FocusSession> startSession({
    required int plannedDurationMinutes,
    String? subjectId,
    String? topicId,
  }) async {
    if (_currentSession != null) {
      await cancelSession();
    }

    final now = DateTime.now();
    _currentSession = FocusSession(
      id: 'focus_${now.millisecondsSinceEpoch}_${plannedDurationMinutes}m',
      startTime: now,
      plannedDurationMinutes: plannedDurationMinutes,
      subjectId: subjectId,
      topicId: topicId,
    );

    _elapsedSeconds = 0;
    _isPaused = false;
    _startTimer();

    await _repository.save(_currentSession!);
    _logger.i('Focus session started: ${_currentSession!.id}');
    return _currentSession!;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _elapsedSeconds++;
        for (final cb in _onTick) {
          cb(_elapsedSeconds);
        }

        if (_elapsedSeconds >=
            _currentSession!.plannedDurationMinutes * 60) {
          completeSession();
        }
      }
    });
  }

  void pauseSession() {
    if (_currentSession == null) return;
    _isPaused = true;
    _logger.i('Focus session paused');
  }

  void resumeSession() {
    if (_currentSession == null) return;
    _isPaused = false;
    _logger.i('Focus session resumed');
  }

  Future<FocusSession> completeSession() async {
    if (_currentSession == null) {
      throw StateError('No active session');
    }

    _timer?.cancel();
    final now = DateTime.now();
    _currentSession = _currentSession!.copyWith(
      endTime: now,
      actualDurationSeconds: _elapsedSeconds,
      completed: true,
    );

    await _repository.save(_currentSession!);
    final completed = _currentSession!;
    _currentSession = null;
    _elapsedSeconds = 0;
    _isPaused = false;

    for (final cb in _onSessionComplete) {
      cb(completed);
    }

    _logger.i('Focus session completed: ${completed.id}');
    return completed;
  }

  Future<FocusSession> cancelSession() async {
    if (_currentSession == null) {
      throw StateError('No active session');
    }

    _timer?.cancel();
    final now = DateTime.now();
    _currentSession = _currentSession!.copyWith(
      endTime: now,
      actualDurationSeconds: _elapsedSeconds,
      completed: false,
    );

    await _repository.save(_currentSession!);
    final cancelled = _currentSession!;
    _currentSession = null;
    _elapsedSeconds = 0;
    _isPaused = false;

    _logger.i('Focus session cancelled: ${cancelled.id}');
    return cancelled;
  }

  Future<int> getTodayFocusSeconds() async {
    final sessions = await _repository.getByDate(DateTime.now());
    return sessions.fold<int>(0, (sum, s) => sum + s.actualDurationSeconds);
  }

  Future<int> getTodaySessionCount() async {
    final sessions = await _repository.getByDate(DateTime.now());
    return sessions.length;
  }

  Future<int> getTodayCompletedSessionCount() async {
    final sessions = await _repository.getByDate(DateTime.now());
    return sessions.where((s) => s.completed).length;
  }

  Future<int> getWeeklyFocusSeconds() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final all = await _repository.getAll();
    return all
        .where((s) => s.startTime.isAfter(weekAgo))
        .fold<int>(0, (sum, s) => sum + s.actualDurationSeconds);
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final now = DateTime.now();
    final sessions = await _repository.getByDate(now);
    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.actualDurationSeconds);
    final completed = sessions.where((s) => s.completed).length;
    final plannedMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.plannedDurationMinutes);

    return {
      'totalSeconds': totalSeconds,
      'completedSessions': completed,
      'totalSessions': sessions.length,
      'plannedMinutes': plannedMinutes,
      'hours': (totalSeconds / 3600).toStringAsFixed(1),
    };
  }

  Future<List<FocusSession>> getRecentSessions({int limit = 10}) async {
    final all = await _repository.getAll();
    return all.take(limit).toList();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
  }
}
