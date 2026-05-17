import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/services/notification_service.dart';

class StudyTimerService {
  final Logger _logger = const Logger('StudyTimerService');
  final SessionRepository _repository;
  final NotificationService? _notificationService;
  Timer? _timer;
  Session? _currentSession;
  int _elapsedMs = 0;
  bool _isPaused = false;
  final List<void Function(Session)> _onSessionComplete = [];
  final List<void Function(int elapsedMs)> _onTick = [];
  DateTime? _lastTickTime;

  StudyTimerService({
    required SessionRepository repository,
    NotificationService? notificationService,
  })  : _repository = repository,
        _notificationService = notificationService;

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

  void reconcileElapsedMs(int expectedMs) {
    if (!hasActiveSession || _isPaused) return;
    _elapsedMs += expectedMs;
    final plannedSeconds = (_currentSession!.plannedDurationMinutes ?? 25) * 60;
    if (_elapsedMs ~/ 1000 >= plannedSeconds) {
      _timer?.cancel();
      completeSession();
    }
  }

  Future<int> getDailyCapMinutes() async {
    try {
      final box = Hive.box(HiveBoxNames.settings);
      return box.get('dailyCapMinutes', defaultValue: 0);
    } catch (e) {
      _logger.e('Failed to get daily cap minutes', e);
      return 0;
    }
  }

  Future<bool> isDailyCapReached(int additionalMinutes) async {
    final capMinutes = await getDailyCapMinutes();
    if (capMinutes <= 0) return false;
    final todayStatsResult = await _repository.getTodayStats();
    final todayMinutes = (todayStatsResult.data?['totalMs'] as int? ?? 0) ~/ 60000;
    return (todayMinutes + additionalMinutes) > capMinutes;
  }

  Future<bool> isDailyCapExceededMidSession() async {
    final capMinutes = await getDailyCapMinutes();
    if (capMinutes <= 0) return false;
    final todayStatsResult = await _repository.getTodayStats();
    final totalMs = (todayStatsResult.data?['totalMs'] as int? ?? 0);
    final withoutCurrent = _elapsedMs > 0 ? totalMs - _elapsedMs : totalMs;
    return (withoutCurrent ~/ 60000) >= capMinutes;
  }

  Future<int> getRemainingDailyCapMinutes() async {
    final capMinutes = await getDailyCapMinutes();
    if (capMinutes <= 0) return -1;
    final todayStatsResult = await _repository.getTodayStats();
    final todayMinutes = (todayStatsResult.data?['totalMs'] as int? ?? 0) ~/ 60000;
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

    await _repository.save(_currentSession!.id, _currentSession!);
    _logger.d('Session started: ${_currentSession!.id} type: ${type.name}');
    return _currentSession!;
  }

  void _startTimer() {
    _timer?.cancel();
    _lastTickTime = DateTime.now();
    _timer = Timer.periodic(Timeouts.second, (_) {
      final now = DateTime.now();
      final diff = _lastTickTime != null ? now.difference(_lastTickTime!).inMilliseconds : 1000;
      _lastTickTime = now;

      if (!_isPaused) {
        _elapsedMs += diff.clamp(500, 5000);

        for (final cb in _onTick) {
          cb(_elapsedMs);
        }

        if (_currentSession!.plannedDurationMinutes != null &&
            _elapsedMs ~/ 1000 >= _currentSession!.plannedDurationMinutes! * 60) {
          _timer?.cancel();
          completeSession();
        }
      }
    });
  }

  void pauseSession() {
    if (_currentSession == null) return;
    _isPaused = true;
    _lastTickTime = null;
    _logger.d('Session paused');
  }

  void resumeSession() {
    if (_currentSession == null) return;
    _isPaused = false;
    _lastTickTime = DateTime.now();
    _logger.d('Session resumed');
  }

  Future<Result<Session>> completeSession() async {
    if (_currentSession == null) {
      return Result.failure('No_active_session');
    }

    _timer?.cancel();
    final now = DateTime.now();
    _currentSession = _currentSession!.copyWith(
      endTime: now,
      actualDurationMs: _elapsedMs,
      completed: true,
    );

    if (_elapsedMs > 0) {
      try {
        await _notificationService?.showNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'Focus Session Complete',
          body: 'Great focus! You completed ${_elapsedMs ~/ 60000} minutes.',
        );
      } catch (e) {
        _logger.e('Failed to show session complete notification', e);
      }
    }

    await _repository.save(_currentSession!.id, _currentSession!);
    final completed = _currentSession!;
    _currentSession = null;
    _elapsedMs = 0;
    _isPaused = false;

    for (final cb in _onSessionComplete) {
      cb(completed);
    }

    _logger.d('Session completed: ${completed.id}');
    return Result.success(completed);
  }

  Future<Result<Session>> cancelSession() async {
    if (_currentSession == null) {
      return Result.failure('No_active_session');
    }

    _timer?.cancel();
    final now = DateTime.now();
    _currentSession = _currentSession!.copyWith(
      endTime: now,
      actualDurationMs: _elapsedMs,
      completed: false,
    );

    await _repository.save(_currentSession!.id, _currentSession!);
    final cancelled = _currentSession!;
    _currentSession = null;
    _elapsedMs = 0;
    _isPaused = false;

    _logger.d('Session cancelled: ${cancelled.id}');
    return Result.success(cancelled);
  }

  Future<int> getTodayDurationMs() async {
    final result = await _repository.getTodayDurationMs();
    return result.data ?? 0;
  }

  Future<int> getTodaySessionCount() async {
    final result = await _repository.getTodaySessionCount();
    return result.data ?? 0;
  }

  Future<int> getTodayCompletedSessionCount() async {
    final result = await _repository.getTodayCompletedSessionCount();
    return result.data ?? 0;
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final result = await _repository.getTodayStats();
    return result.data ?? {};
  }

  Future<List<Session>> getRecentSessions({int limit = 10}) async {
    final allResult = await _repository.getAll();
    final all = allResult.data ?? [];
    return all.take(limit).toList();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
  }
}
