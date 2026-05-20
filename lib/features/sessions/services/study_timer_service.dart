import 'dart:async';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/core/services/settings_service.dart';
import 'package:studyking/core/utils/study_utils.dart';

class StudyTimerService {
  static final Logger _logger = const Logger('StudyTimerService');
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
  int get elapsedSeconds => _elapsedMs ~/ msPerSecond;
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
    if (_elapsedMs ~/ msPerSecond >= plannedSeconds) {
      _timer?.cancel();
      completeSession();
    }
  }

  Future<Result<int>> getDailyCapMinutes() async {
    try {
      return Result.success(SettingsService.getDailyCapMinutes());
    } catch (e) {
      _logger.w('Failed to get daily cap minutes', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> isDailyCapReached(int additionalMinutes) async {
    try {
      final capResult = await getDailyCapMinutes();
      if (capResult.isFailure) return Result.failure(capResult.error);
      final capMinutes = capResult.data!;
      if (capMinutes <= 0) return Result.success(false);
      final todayStatsResult = await _repository.getTodayStats();
      if (todayStatsResult.isFailure) return Result.failure(todayStatsResult.error);
      final todayMinutes = (todayStatsResult.data!['totalMs'] as int? ?? 0) ~/ msPerMinute;
      return Result.success((todayMinutes + additionalMinutes) > capMinutes);
    } catch (e) {
      _logger.w('Failed to check daily cap', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> isDailyCapExceededMidSession() async {
    try {
      final capResult = await getDailyCapMinutes();
      if (capResult.isFailure) return Result.failure(capResult.error);
      final capMinutes = capResult.data!;
      if (capMinutes <= 0) return Result.success(false);
      final todayStatsResult = await _repository.getTodayStats();
      if (todayStatsResult.isFailure) return Result.failure(todayStatsResult.error);
      final totalMs = (todayStatsResult.data!['totalMs'] as int? ?? 0);
      final withoutCurrent = _elapsedMs > 0 ? totalMs - _elapsedMs : totalMs;
      return Result.success((withoutCurrent ~/ msPerMinute) >= capMinutes);
    } catch (e) {
      _logger.w('Failed to check mid-session cap', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getRemainingDailyCapMinutes() async {
    try {
      final capResult = await getDailyCapMinutes();
      if (capResult.isFailure) return Result.failure(capResult.error);
      final capMinutes = capResult.data!;
      if (capMinutes <= 0) return Result.success(-1);
      final todayStatsResult = await _repository.getTodayStats();
      if (todayStatsResult.isFailure) return Result.failure(todayStatsResult.error);
      final todayMinutes = (todayStatsResult.data!['totalMs'] as int? ?? 0) ~/ msPerMinute;
      return Result.success(capMinutes - todayMinutes);
    } catch (e) {
      _logger.w('Failed to get remaining daily cap minutes', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Session>> startSession({
    required int plannedDurationMinutes,
    SessionType type = SessionType.focus,
    String? studentId,
    String? subjectId,
    String? topicId,
  }) async {
    try {
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
      _logger.i('Session started: ${_currentSession!.id} type: ${type.name}');
      return Result.success(_currentSession!);
    } catch (e) {
      _logger.w('Failed to start session: $e');
      return Result.failure('StudyTimerService.startSession: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _lastTickTime = DateTime.now();
    _timer = Timer.periodic(Timeouts.second, (_) {
      final now = DateTime.now();
      final diff = _lastTickTime != null ? now.difference(_lastTickTime!).inMilliseconds : msPerSecond;
      _lastTickTime = now;

      if (!_isPaused) {
        _elapsedMs += diff.clamp(500, 5000);

        for (final cb in _onTick) {
          cb(_elapsedMs);
        }

        if (_currentSession!.plannedDurationMinutes != null &&
            _elapsedMs ~/ msPerSecond >= _currentSession!.plannedDurationMinutes! * 60) {
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
    _logger.i('Session paused');
  }

  void resumeSession() {
    if (_currentSession == null) return;
    _isPaused = false;
    _lastTickTime = DateTime.now();
    _logger.i('Session resumed');
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
          body: 'Great focus! You completed ${_elapsedMs ~/ msPerMinute} minutes.',
        );
        // Note: Notification titles/bodies are intentionally invariant (English)
        // because they are not rendered inside the app UI; they appear in the
        // OS notification shade where locale is controlled by the OS, not the app.
      } catch (e) {
        _logger.w('Failed to show session complete notification', e);
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

    _logger.i('Session completed: ${completed.id}');
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

    _logger.i('Session cancelled: ${cancelled.id}');
    return Result.success(cancelled);
  }

  Future<Result<int>> getTodayDurationMs() async {
    try {
      final result = await _repository.getTodayDurationMs();
      return Result.success(result.data ?? 0);
    } catch (e) {
      _logger.w('getTodayDurationMs failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getTodaySessionCount() async {
    try {
      final result = await _repository.getTodaySessionCount();
      return Result.success(result.data ?? 0);
    } catch (e) {
      _logger.w('getTodaySessionCount failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getTodayCompletedSessionCount() async {
    try {
      final result = await _repository.getTodayCompletedSessionCount();
      return Result.success(result.data ?? 0);
    } catch (e) {
      _logger.w('getTodayCompletedSessionCount failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getTodayStats() async {
    try {
      final result = await _repository.getTodayStats();
      return Result.success(result.data ?? {});
    } catch (e) {
      _logger.w('getTodayStats failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getRecentSessions({int limit = 10}) async {
    try {
      final allResult = await _repository.getAll();
      final all = allResult.data ?? [];
      return Result.success(all.take(limit).toList());
    } catch (e) {
      _logger.w('getRecentSessions failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> dispose() async {
    try {
      _timer?.cancel();
      _timer = null;
      return Result.success(null);
    } catch (e) {
      _logger.w('dispose failed', e);
      return Result.failure(e.toString());
    }
  }
}
