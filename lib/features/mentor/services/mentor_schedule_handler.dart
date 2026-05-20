import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/conversation_memory.dart';
import 'package:studyking/core/utils/date_utils.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ScheduleProposal {
  final String topicTitle;
  final String? topicId;
  final String? subjectId;
  final DateTime proposedTime;
  final int durationMinutes;

  ScheduleProposal({
    required this.topicTitle,
    this.topicId,
    this.subjectId,
    required this.proposedTime,
    this.durationMinutes = defaultSessionDurationMinutes,
  });
}

class MentorScheduleHandler {
  static final Logger _logger = const Logger('MentorScheduleHandler');

  final DatabaseService _database;
  final PlannerService _plannerService;
  final PendingActionRepository _pendingActionRepo;
  final String _localeName;
  final ConversationMemory _memory;

  MentorScheduleHandler({
    required DatabaseService database,
    required PlannerService plannerService,
    required PendingActionRepository pendingActionRepo,
    required String localeName,
    required ConversationMemory memory,
  })  : _database = database,
        _plannerService = plannerService,
        _pendingActionRepo = pendingActionRepo,
        _localeName = localeName,
        _memory = memory;

  ScheduleProposal extractScheduleProposal(
      String topicTitle, int extractedDurationMinutes) {
    final proposedTime = DateTime.now().add(Timeouts.hour);
    final nextHour = DateTime(
      proposedTime.year,
      proposedTime.month,
      proposedTime.day,
      proposedTime.hour,
      0,
    );

    final durationMinutes = extractedDurationMinutes > 0
        ? extractedDurationMinutes
        : _getDefaultDurationMinutes();

    return ScheduleProposal(
      topicTitle: topicTitle,
      proposedTime: nextHour,
      durationMinutes: durationMinutes,
    );
  }

  int _getDefaultDurationMinutes() {
    try {
      if (!Hive.isBoxOpen(HiveBoxNames.settings)) return defaultSessionDurationMinutes;
      final box = Hive.box(HiveBoxNames.settings);
      final stored = box.get('defaultScheduleDuration', defaultValue: defaultSessionDurationMinutes) as int;
      return stored > 0 && stored <= 480 ? stored : defaultSessionDurationMinutes;
    } catch (e) {
      _logger.w('Failed to read default schedule duration from Hive', e);
      return defaultSessionDurationMinutes;
    }
  }

  Future<String> confirmSchedule(ScheduleProposal proposal) async {
    final result = await Result.capture(() => _confirmScheduleInner(proposal), context: 'confirmSchedule');
    if (result.isSuccess) return result.data!;
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final msg = l10n.mentorScheduleFail;
    _memory.addAssistantMessage(msg);
    return msg;
  }

  Future<String> _confirmScheduleInner(ScheduleProposal proposal) async {
    String? topicId;
    String? subjectId;
    if (proposal.topicTitle.isNotEmpty && proposal.topicTitle != 'general') {
      await _database.topicRepository.init();
      final allTopicsResult = await _database.topicRepository.getAll();
      final allTopics = allTopicsResult.data ?? [];
      final match = allTopics.where(
        (t) => t.title.normalized.contains(proposal.topicTitle.normalized),
      ).firstOrNull;
      topicId = match?.id;
      subjectId = match?.subjectId;
    }

    final hasConflictResult = await _plannerService.hasSchedulingConflict(
      startTime: proposal.proposedTime,
      durationMinutes: proposal.durationMinutes,
    );

    if (hasConflictResult.data ?? false) {
      final existingLessonsResult = await _plannerService.getScheduledLessons();
      final existingLessons = existingLessonsResult.data ?? [];
      final nextFree = _findNextFreeSlot(existingLessons, proposal.durationMinutes);
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final msg = l10n.mentorScheduleConflict(
        localizedDateTime(proposal.proposedTime, _localeName),
        localizedDateTime(nextFree, _localeName),
      );
      _memory.addAssistantMessage(msg);
      return msg;
    }

    final successResult = await _plannerService.scheduleLesson(
      topicId: topicId ?? '',
      topicTitle: proposal.topicTitle,
      subjectId: subjectId ?? '',
      scheduledTime: proposal.proposedTime,
      durationMinutes: proposal.durationMinutes,
    );
    final success = successResult.data ?? false;

    String msg;
    final l10n = lookupAppLocalizations(Locale(_localeName));
    if (success) {
      msg = l10n.mentorScheduleSuccess(
        proposal.topicTitle,
        localizedDateTime(proposal.proposedTime, _localeName),
      );
    } else {
      msg = l10n.mentorScheduleFail;
    }
    _memory.addAssistantMessage(msg);
    return msg;
  }

  DateTime _findNextFreeSlot(List<Session> existingLessons, int durationMinutes) {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    final sorted = List<Session>.from(existingLessons)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final lesson in sorted) {
      if (lesson.completed || lesson.endTime != null) continue;
      final plannedDur = lesson.plannedDurationMinutes ?? durationMinutes;
      final end = lesson.startTime.add(Duration(minutes: plannedDur));
      if (candidate.isBefore(lesson.startTime) &&
          lesson.startTime.difference(candidate).inMinutes >= durationMinutes) {
        return candidate;
      }
      if (candidate.isBefore(end)) {
        candidate = end;
      }
    }
    return candidate;
  }

  Future<String> suggestReschedule(String sessionId) async {
    final sessionResult = await _database.tutorSessionRepository.getSession(sessionId);
    final session = sessionResult.data;
    if (session == null) {
      final msg = lookupAppLocalizations(Locale(_localeName)).mentorRescheduleNotFound;
      _memory.addSystemMessage(msg);
      return msg;
    }

    final existingLessonsResult = await _plannerService.getScheduledLessons();
    final existingLessons = existingLessonsResult.data ?? [];
    final nextFree = _findNextFreeSlot(
      existingLessons.where((l) => l.id != sessionId).toList(),
      session.plannedDurationMinutes,
    );

    final hasConflictResult = await _plannerService.hasSchedulingConflict(
      startTime: nextFree,
      durationMinutes: session.plannedDurationMinutes,
      excludeSessionId: sessionId,
    );

    if (hasConflictResult.data ?? false) {
      final msg = lookupAppLocalizations(Locale(_localeName)).mentorRescheduleNoFreeSlot(
        session.topicTitle,
      );
      _memory.addSystemMessage(msg);
      return msg;
    }

    final studentId = _plannerService.studentId;
    final action = PendingActionModel(
      id: 'resched_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      actionType: PendingActionType.reschedule.name,
      topicTitle: session.topicTitle,
      sessionId: sessionId,
      payload: {
        'topicId': session.topicId,
        'subjectId': session.subjectId,
        'scheduledTime': nextFree.toIso8601String(),
        'durationMinutes': session.plannedDurationMinutes,
        'originalSessionStart': session.startTime.toIso8601String(),
      },
    );
    await _pendingActionRepo.init();
    await _pendingActionRepo.create(action);

    final msg = lookupAppLocalizations(Locale(_localeName)).mentorReschedulePending(
      session.topicTitle,
      localizedDateTime(nextFree, _localeName),
    );
    _memory.addSystemMessage(msg);
    return msg;
  }
}
