import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class MentorWellbeingService {
  static const int _maxNudgesPerDay = 5;

  final SessionRepository _sessionRepository;
  final EngagementNudgeRepository _nudgeRepo;
  final MasteryGraphService _masteryService;
  final String _localeName;
  final String _studentId;

  MentorWellbeingService({
    required SessionRepository sessionRepository,
    required EngagementNudgeRepository nudgeRepo,
    required MasteryGraphService masteryService,
    required String localeName,
    required String studentId,
  })  : _sessionRepository = sessionRepository,
        _nudgeRepo = nudgeRepo,
        _masteryService = masteryService,
        _localeName = localeName,
        _studentId = studentId;

  Future<List<String>> checkWellbeingAndGenerateNudges() async {
    final result = await Result.capture(() => _checkWellbeingInner(), context: 'checkWellbeingAndGenerateNudges');
    return result.data ?? [];
  }

  Future<List<String>> _checkWellbeingInner() async {
    final messages = <String>[];
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = await _getDailyCapMinutes();
    final recentResult = await _sessionRepository.getByDate(DateTime.now());

    if (dailyCap > 0 && todayMinutes > dailyCap) {
      final msg = lookupAppLocalizations(Locale(_localeName)).nudgeOverworkMinutes(todayMinutes, dailyCap);
      final nudge = EngagementNudgeModel(
        id: 'overwork_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
        studentId: _studentId,
        nudgeType: NudgeType.overwork.name,
        message: msg,
        severity: NudgeSeverity.medium.name,
      );
      await _nudgeRepo.create(nudge);
      messages.add(msg);
    }

    if (recentResult.isSuccess) {
      final lateNight = recentResult.data!.where((s) => s.startTime.hour >= lateNightHour).toList();
      if (lateNight.isNotEmpty) {
        final msg = lookupAppLocalizations(Locale(_localeName)).nudgeLateNight(lateNight.length);
        final nudge = EngagementNudgeModel(
          id: 'wellbeing_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
          studentId: _studentId,
          nudgeType: NudgeType.overwork.name,
          message: msg,
          severity: NudgeSeverity.low.name,
        );
        await _nudgeRepo.create(nudge);
        messages.add(msg);
      }
    }

    final weakResult = await _masteryService.getAtRiskQuestions(_studentId);
    if (weakResult.isSuccess && weakResult.data!.isNotEmpty) {
      final atRiskCount = weakResult.data!.length;
      if (atRiskCount >= 3) {
        final msg = lookupAppLocalizations(Locale(_localeName)).nudgeRevisionNeeded(atRiskCount);
        final nudge = EngagementNudgeModel(
          id: 'revision_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
          studentId: _studentId,
          nudgeType: NudgeType.revision.name,
          message: msg,
          severity: NudgeSeverity.low.name,
        );
        await _nudgeRepo.create(nudge);
        messages.add(msg);
      }
    }

    final consecutiveDays = await _getConsecutiveStudyDays();
    if (consecutiveDays >= 7) {
      final msg = lookupAppLocalizations(Locale(_localeName)).nudgeStreakDays(consecutiveDays);
      messages.add(msg);
    } else if (consecutiveDays == 0) {
      final allResult = await _sessionRepository.getAll();
      if (allResult.isSuccess) {
        final lastStudy = allResult.data!.where((s) => s.completed).fold<DateTime?>(
          null, (prev, s) {
            if (prev == null || s.startTime.isAfter(prev)) return s.startTime;
            return prev;
          });
        if (lastStudy != null && DateTime.now().difference(lastStudy).inHours >= 48) {
          final l10nCtx = lookupAppLocalizations(Locale(_localeName));
          final hoursSince = DateTime.now().difference(lastStudy).inHours;
          final daysSince = hoursSince ~/ 24;
          String msg;
          String nudgeType;
          String severity;
          if (daysSince >= 30) {
            msg = l10nCtx.nudgeInactive30d(daysSince);
            nudgeType = NudgeType.overwork.name;
            severity = NudgeSeverity.high.name;
          } else if (daysSince >= 14) {
            msg = l10nCtx.nudgeInactive14d(daysSince);
            nudgeType = NudgeType.overwork.name;
            severity = NudgeSeverity.high.name;
          } else if (daysSince >= 7) {
            msg = l10nCtx.nudgeInactive7d(daysSince);
            nudgeType = NudgeType.planAdjustment.name;
            severity = NudgeSeverity.medium.name;
          } else {
            msg = l10nCtx.nudgeInactive48h;
            nudgeType = NudgeType.planAdjustment.name;
            severity = NudgeSeverity.medium.name;
          }
          final nudge = EngagementNudgeModel(
            id: 'inactive_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
            studentId: _studentId,
            nudgeType: nudgeType,
            message: msg,
            severity: severity,
          );
          await _nudgeRepo.create(nudge);
          messages.add(msg);
        }
      }
    }

    if (dailyCap > 0) {
      final todayNudgesResult = await _nudgeRepo.getTodayCount(_studentId);
      final todayNudges = todayNudgesResult.data ?? 0;
      if (todayNudges >= _maxNudgesPerDay) return messages;
    }
    return messages;
  }

  Future<int> _getTodayStudyMinutes() async {
    final result = await _sessionRepository.getTodayDurationMs();
    return result.isSuccess ? (result.data! ~/ msPerMinute) : 0;
  }

  Future<int> _getDailyCapMinutes() async {
    final result = Result.captureSync(() {
      if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 0;
      final box = Hive.box(HiveBoxNames.settings);
      return box.get('dailyCapMinutes', defaultValue: 0) as int;
    }, context: '_getDailyCapMinutes');
    return result.data ?? 0;
  }

  Future<int> _getConsecutiveStudyDays() async {
    final result = await Result.capture(() async {
      final allResult = await _sessionRepository.getAll();
      if (allResult.isFailure) return 0;
      final all = allResult.data!;
      if (all.isEmpty) return 0;
      final studyDays = all.where((s) =>
        s.completed || s.actualDurationMs > 0
      ).map((s) =>
        s.startTime.dateOnly
      ).toSet().toList()..sort((a, b) => b.compareTo(a));
      int consecutive = 0;
      final now = DateTime.now();
      final today = now.dateOnly;
      for (var i = 0; i < studyDays.length; i++) {
        final expected = today.subtract(Duration(days: i));
        if (studyDays[i] == expected) {
          consecutive++;
        } else {
          break;
        }
      }
      return consecutive;
    }, context: '_getConsecutiveStudyDays');
    return result.data ?? 0;
  }
}
