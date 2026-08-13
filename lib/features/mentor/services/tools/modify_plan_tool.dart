import 'package:flutter/material.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ModifyPlanTool extends AgentTool {
  final PlannerService _plannerService;
  final String _localeName;

  ModifyPlanTool({required PlannerService plannerService, required String localeName})
      : _plannerService = plannerService,
        _localeName = localeName;

  @override
  String get name => 'modify_plan';

  @override
  String get description =>
      'Modify an existing study plan: adjust daily pace, extend or shorten duration, redistribute missed workload, or change daily targets.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': ['adjust_pace', 'extend', 'redistribute', 'change_targets'],
        'description': 'What modification to perform',
      },
      'planId': {
        'type': 'string',
        'description': 'Plan ID (omit to use the current active plan)',
      },
      'newTargetMinutesPerDay': {
        'type': 'integer',
        'description': 'For adjust_pace: new daily target in minutes',
      },
      'extendDays': {
        'type': 'integer',
        'description': 'For extend: number of days to add',
      },
      'missedMinutes': {
        'type': 'integer',
        'description': 'For redistribute: total minutes of missed work to redistribute',
      },
      'redistributionStrategy': {
        'type': 'string',
        'enum': ['next_3_days', 'all_remaining'],
        'default': 'next_3_days',
        'description': 'For redistribute: how to spread the missed workload',
      },
      'newDailyQuestions': {
        'type': 'integer',
        'description': 'For change_targets: new daily question target',
      },
      'newDailyMinutes': {
        'type': 'integer',
        'description': 'For change_targets: new daily minute target',
      },
    },
    'required': ['action'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    final l10n = lookupAppLocalizations(Locale(_localeName));

    try {
      switch (action) {
        case 'adjust_pace':
          return await _adjustPace(args, l10n);
        case 'extend':
          return await _extendPlan(args, l10n);
        case 'redistribute':
          return await _redistribute(args, l10n);
        case 'change_targets':
          return await _changeTargets(args, l10n);
        default:
          return {
            'success': false,
            'message': l10n.toolModifyPlanInvalidAction,
          };
      }
    } catch (e) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanError,
      };
    }
  }

  Future<Map<String, dynamic>> _adjustPace(
    Map<String, dynamic> args,
    AppLocalizations l10n,
  ) async {
    final newTargetMinutes = (args['newTargetMinutesPerDay'] as num?)?.toInt();
    if (newTargetMinutes == null || newTargetMinutes <= 0) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanMissingParam('newTargetMinutesPerDay'),
      };
    }

    final result = await _plannerService.adjustPace(newTargetMinutes.toDouble());
    if (!result.isSuccess) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanError,
      };
    }

    final planResult = await _plannerService.loadExistingPlan();
    final plan = planResult.data;

    return {
      'success': true,
      'planId': plan?.studentId ?? '',
      'newTargetMinutesPerDay': newTargetMinutes,
      'totalDays': plan?.dailyPlans.length ?? 0,
      'message': l10n.toolModifyPlanPaceAdjusted(newTargetMinutes),
    };
  }

  Future<Map<String, dynamic>> _extendPlan(
    Map<String, dynamic> args,
    AppLocalizations l10n,
  ) async {
    final extendDays = (args['extendDays'] as num?)?.toInt();
    if (extendDays == null || extendDays <= 0) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanMissingParam('extendDays'),
      };
    }

    final planResult = await _plannerService.loadExistingPlan();
    final plan = planResult.data;
    if (plan == null) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanNoPlan,
      };
    }

    final result = await _plannerService.extendPlan(extendDays);
    if (!result.isSuccess) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanError,
      };
    }

    final newTotalDays = plan.dailyPlans.length + extendDays;

    return {
      'success': true,
      'planId': plan.studentId,
      'previousDays': plan.dailyPlans.length,
      'addedDays': extendDays,
      'newTotalDays': newTotalDays,
      'message': l10n.toolModifyPlanExtended(extendDays, newTotalDays),
    };
  }

  Future<Map<String, dynamic>> _redistribute(
    Map<String, dynamic> args,
    AppLocalizations l10n,
  ) async {
    final missedMinutes = (args['missedMinutes'] as num?)?.toInt();
    if (missedMinutes == null || missedMinutes <= 0) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanMissingParam('missedMinutes'),
      };
    }

    final strategyStr = args['redistributionStrategy'] as String? ?? 'next_3_days';
    final strategy = strategyStr == 'all_remaining' ? 'all' : 'days:3';

    final result = await _plannerService.redistributeMissedWorkload(
      missedMinutes,
      strategy: strategy,
    );
    if (!result.isSuccess) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanError,
      };
    }

    return {
      'success': true,
      'missedMinutes': missedMinutes,
      'strategy': strategyStr,
      'message': l10n.toolModifyPlanRedistributed(missedMinutes, strategyStr),
    };
  }

  Future<Map<String, dynamic>> _changeTargets(
    Map<String, dynamic> args,
    AppLocalizations l10n,
  ) async {
    final newDailyMinutes = (args['newDailyMinutes'] as num?)?.toInt();
    final newDailyQuestions = (args['newDailyQuestions'] as num?)?.toInt();

    if (newDailyMinutes == null && newDailyQuestions == null) {
      return {
        'success': false,
        'message': l10n.toolModifyPlanMissingParam('newDailyMinutes or newDailyQuestions'),
      };
    }

    if (newDailyMinutes != null && newDailyMinutes > 0) {
      final result = await _plannerService.adjustPace(newDailyMinutes.toDouble());
      if (!result.isSuccess) {
        return {
          'success': false,
          'message': l10n.toolModifyPlanError,
        };
      }
    }

    final planResult = await _plannerService.loadExistingPlan();
    final plan = planResult.data;

    return {
      'success': true,
      'planId': plan?.studentId ?? '',
      'newDailyMinutes': newDailyMinutes ?? plan?.targetMinutesPerDay.round(),
      'newDailyQuestions': newDailyQuestions ?? plan?.targetQuestionsPerDay,
      'message': l10n.toolModifyPlanTargetsChanged,
    };
  }
}
