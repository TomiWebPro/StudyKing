import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/logger.dart';

class UnifiedTimelineEntry {
  final String id;
  final DateTime timestamp;
  final SessionType type;
  final String? subjectId;
  final String? topicId;
  final int durationMs;
  final int? questionsAnswered;
  final int? correctAnswers;
  final String? sourceId;

  UnifiedTimelineEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    this.subjectId,
    this.topicId,
    required this.durationMs,
    this.questionsAnswered,
    this.correctAnswers,
    this.sourceId,
  });
}

class CrossFeatureIntegrator {
  final Logger _logger = const Logger('CrossFeatureIntegrator');
  final SessionRepository _sessionRepo;
  final StudentIdService _studentIdService;
  final Clock _clock;

  CrossFeatureIntegrator({
    required SessionRepository sessionRepo,
    required StudentIdService studentIdService,
    Clock? clock,
  })  : _sessionRepo = sessionRepo,
        _studentIdService = studentIdService,
        _clock = clock ?? SystemClock();

  Future<void> recordTutorSessionAsSession({
    required String tutorSessionId,
    required String subjectId,
    required String topicId,
    required int durationMs,
    String? studentId,
  }) async {
    final sid = studentId ?? _studentIdService.getStudentId();
    final now = _clock.now();
    final session = Session(
      id: 'tutor_${tutorSessionId}_${now.millisecondsSinceEpoch}',
      studentId: sid,
      subjectId: subjectId,
      topicId: topicId,
      type: SessionType.tutoring,
      startTime: now.subtract(Duration(milliseconds: durationMs)),
      endTime: now,
      actualDurationMs: durationMs,
      completed: true,
      sourceId: tutorSessionId,
    );
    await _sessionRepo.save(session);
    _logger.d('Created Session for tutor session $tutorSessionId');
  }

  Future<void> linkPracticeSessionToSource({
    required String practiceSessionId,
    String? tutorSessionId,
    String? sourceId,
  }) async {
    final result = await _sessionRepo.get(practiceSessionId);
    if (result.isFailure || result.data == null) {
      _logger.w('Practice session not found: $practiceSessionId');
      return;
    }
    final session = result.data!;
    final updated = session.copyWith(
      sourceId: tutorSessionId ?? sourceId ?? session.sourceId,
    );
    await _sessionRepo.save(updated);
  }

  Future<List<UnifiedTimelineEntry>> getUnifiedTimeline({
    String? studentId,
    int limit = 50,
    int offset = 0,
  }) async {
    final sid = studentId ?? _studentIdService.getStudentId();
    final result = await _sessionRepo.getByStudent(sid);
    if (result.isFailure || result.data == null) return [];

    final entries = result.data!.map((s) => UnifiedTimelineEntry(
      id: s.id,
      timestamp: s.startTime,
      type: s.type,
      subjectId: s.subjectId,
      topicId: s.topicId,
      durationMs: s.actualDurationMs,
      questionsAnswered: s.questionsAnswered > 0 ? s.questionsAnswered : null,
      correctAnswers: s.correctAnswers > 0 ? s.correctAnswers : null,
      sourceId: s.sourceId,
    )).toList();

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final skip = offset.clamp(0, entries.length);
    final take = limit.clamp(0, entries.length - skip);
    return entries.sublist(skip, skip + take);
  }

  Future<int> getTotalStudyDurationMs({
    String? studentId,
    DateTime? since,
  }) async {
    final sid = studentId ?? _studentIdService.getStudentId();
    final result = await _sessionRepo.getByStudent(sid);
    if (result.isFailure || result.data == null) return 0;

    var sessions = result.data!;
    if (since != null) {
      sessions = sessions.where((s) => s.startTime.isAfter(since)).toList();
    }

    return sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
  }

  Future<int> getCompletedSessionCount({String? studentId}) async {
    final sid = studentId ?? _studentIdService.getStudentId();
    final result = await _sessionRepo.getByStudent(sid);
    if (result.isFailure || result.data == null) return 0;
    return result.data!.where((s) => s.completed).length;
  }

  Future<Map<SessionType, int>> getDurationByType({
    String? studentId,
    DateTime? since,
  }) async {
    final sid = studentId ?? _studentIdService.getStudentId();
    final result = await _sessionRepo.getByStudent(sid);
    if (result.isFailure || result.data == null) return {};

    var sessions = result.data!;
    if (since != null) {
      sessions = sessions.where((s) => s.startTime.isAfter(since)).toList();
    }

    final byType = <SessionType, int>{};
    for (final s in sessions) {
      byType.update(s.type, (v) => v + s.actualDurationMs, ifAbsent: () => s.actualDurationMs);
    }
    return byType;
  }

  Future<void> linkSourceToTopic({
    required String sourceId,
    required String topicId,
    required SourceRepository sourceRepository,
  }) async {
    final source = await sourceRepository.get(sourceId);
    if (source == null) {
      _logger.w('Source not found for linking: $sourceId');
      return;
    }
    final updated = source.copyWith(topicId: topicId);
    await sourceRepository.save(sourceId, updated);
    _logger.d('Linked source $sourceId to topic $topicId');
  }

  Future<void> notifyPlannerOfNewContent({
    required String sourceId,
    required List<String> topicIds,
    required SourceRepository sourceRepository,
  }) async {
    final source = await sourceRepository.get(sourceId);
    if (source == null) {
      _logger.w('Source not found for planner notification: $sourceId');
      return;
    }
    _logger.i(
      'Planner notification: source $sourceId linked to topics $topicIds. '
      'Planner should re-evaluate workload.',
    );
  }
}
