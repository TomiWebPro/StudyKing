import 'package:flutter/material.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/settings_service.dart';
import 'package:studyking/core/utils/study_utils.dart';
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

  Future<Result<List<String>>> checkWellbeingAndGenerateNudges() async {
    return Result.capture(() => _checkWellbeingInner(), context: 'checkWellbeingAndGenerateNudges');
  }

  Future<List<String>> _checkWellbeingInner() async {
    final messages = <String>[];
    final todayMinutes = await _getTodayStudyMinutes();
    final dailyCap = SettingsService.getDailyCapMinutes();

    if (dailyCap > 0) {
      final todayNudgesResult = await _nudgeRepo.getTodayCount(_studentId);
      final todayNudges = todayNudgesResult.data ?? 0;
      if (todayNudges >= _maxNudgesPerDay) return messages;
    }

    await _checkOverwork(todayMinutes, dailyCap, messages);
    await _checkLateNight(messages);
    await _checkRevisionNeeded(messages);
    await _checkStreak(messages);
    return messages;
  }

  Future<void> _checkOverwork(int todayMinutes, int dailyCap, List<String> messages) async {
    if (dailyCap <= 0 || todayMinutes <= dailyCap) return;
    final msg = lookupAppLocalizations(Locale(_localeName)).nudgeOverworkMinutes(todayMinutes, dailyCap);
    await _nudgeRepo.create(EngagementNudgeModel(
      id: 'overwork_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
      studentId: _studentId,
      nudgeType: NudgeType.overwork.name,
      message: msg,
      severity: NudgeSeverity.medium.name,
    ));
    messages.add(msg);
  }

  Future<void> _checkLateNight(List<String> messages) async {
    final recentResult = await _sessionRepository.getByDate(DateTime.now());
    if (!recentResult.isSuccess) return;
    final lateNight = recentResult.data!.where((s) => s.startTime.hour >= lateNightHour).toList();
    if (lateNight.isEmpty) return;
    final msg = lookupAppLocalizations(Locale(_localeName)).nudgeLateNight(lateNight.length);
    await _nudgeRepo.create(EngagementNudgeModel(
      id: 'wellbeing_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
      studentId: _studentId,
      nudgeType: NudgeType.overwork.name,
      message: msg,
      severity: NudgeSeverity.low.name,
    ));
    messages.add(msg);
  }

  Future<void> _checkRevisionNeeded(List<String> messages) async {
    final weakResult = await _masteryService.getAtRiskQuestions(_studentId);
    if (!weakResult.isSuccess || weakResult.data!.isEmpty) return;
    final atRiskCount = weakResult.data!.length;
    if (atRiskCount < 3) return;
    final msg = lookupAppLocalizations(Locale(_localeName)).nudgeRevisionNeeded(atRiskCount);
    await _nudgeRepo.create(EngagementNudgeModel(
      id: 'revision_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
      studentId: _studentId,
      nudgeType: NudgeType.revision.name,
      message: msg,
      severity: NudgeSeverity.low.name,
    ));
    messages.add(msg);
  }

  Future<void> _checkStreak(List<String> messages) async {
    final consecutiveDays = (await _getConsecutiveStudyDays()).data ?? 0;
    if (consecutiveDays >= 7) {
      messages.add(lookupAppLocalizations(Locale(_localeName)).nudgeStreakDays(consecutiveDays));
      return;
    }
    if (consecutiveDays > 0) return;
    final allResult = await _sessionRepository.getAll();
    if (!allResult.isSuccess) return;
    final lastStudy = allResult.data!.where((s) => s.completed).fold<DateTime?>(
      null, (prev, s) {
        if (prev == null || s.startTime.isAfter(prev)) return s.startTime;
        return prev;
      });
    if (lastStudy == null || DateTime.now().difference(lastStudy).inHours < 48) return;
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
    await _nudgeRepo.create(EngagementNudgeModel(
      id: 'inactive_${DateTime.now().millisecondsSinceEpoch}_$_studentId',
      studentId: _studentId,
      nudgeType: nudgeType,
      message: msg,
      severity: severity,
    ));
    messages.add(msg);
  }



  Future<int> _getTodayStudyMinutes() async {
    final result = await _sessionRepository.getTodayDurationMs();
    return result.isSuccess ? (result.data! ~/ msPerMinute) : 0;
  }

  Future<Result<int>> _getConsecutiveStudyDays() async {
    return _sessionRepository.getConsecutiveStudyDays();
  }
}
