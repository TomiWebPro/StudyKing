import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'widgets/study_plan_tab.dart';
import 'widgets/calendar_view_widget.dart';
import 'widgets/roadmaps_tab.dart';
import '../../../l10n/generated/app_localizations.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  final String? fixedStudentId;

  const PlannerScreen({super.key, this.fixedStudentId});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  static final Logger _logger = const Logger('PlannerScreen');
  late TabController _tabController;
  List<Subject> _allSubjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(plannerProvider.notifier).loadInitialData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(plannerProvider.notifier).loadAdditionalData();
    });
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final repo = SubjectRepository();
      await repo.init();
      final result = await repo.getAll();
      if (mounted) {
        setState(() => _allSubjects = result.data ?? []);
      }
    } catch (e) {
      _logger.w('Failed to load subjects', e);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCreateRoadmapDialog({RoadmapModel? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final goalController = TextEditingController(text: existing?.goal ?? '');
    final daysController = TextEditingController(
      text: existing != null && existing.targetCompletionDate != null
          ? '${existing.targetCompletionDate!.difference(existing.createdAt).inDays}'
          : '30',
    );
    var selectedSubjectId = existing?.subjectId ?? '';
    var daysError = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          semanticLabel: existing != null ? l10n.edit : l10n.createRoadmap,
          title: Text(existing != null ? l10n.edit : l10n.createRoadmap),
          content: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: goalController,
                  decoration: InputDecoration(
                    labelText: l10n.roadmapGoal,
                    hintText: l10n.roadmapGoalHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.days,
                    border: const OutlineInputBorder(),
                    errorText: daysError.isNotEmpty ? daysError : null,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId.isNotEmpty ? selectedSubjectId : null,
                  decoration: InputDecoration(
                    labelText: l10n.subjectOptional,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: Text(l10n.subjectOptional),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.none),
                    ),
                    ..._allSubjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (v) {
                    setDialogState(() {
                      selectedSubjectId = v ?? '';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final goal = goalController.text.trim();
                if (goal.isEmpty) return;
                final daysStr = daysController.text.trim();
                final days = int.tryParse(daysStr);
                if (daysStr.isNotEmpty && days == null) {
                  setDialogState(() {
                    daysError = l10n.enterValidNumber;
                  });
                  return;
                }
                Navigator.pop(ctx, {
                  'goal': goal,
                  'days': daysStr.isNotEmpty ? daysStr : '30',
                  'subjectId': selectedSubjectId,
                });
              },
              child: Text(existing != null ? l10n.save : l10n.generateRoadmap),
            ),
          ],
        ),
      ),
    );

    goalController.dispose();
    daysController.dispose();

    if (result == null || result['goal']!.isEmpty) return;

    final goal = result['goal']!;
    final days = int.tryParse(result['days'] ?? '') ?? 30;
    final subjectId = result['subjectId']?.isNotEmpty == true ? result['subjectId'] : null;

    if (!mounted) return;
    final notifier = ref.read(plannerProvider.notifier);
    if (existing != null) {
      await notifier.updateRoadmap(
        roadmapId: existing.id,
        goal: goal,
        days: days,
        l10n: AppLocalizations.of(context)!,
        subjectId: subjectId,
      );
    } else {
      await notifier.createRoadmap(
        goal: goal,
        days: days,
        l10n: AppLocalizations.of(context)!,
        subjectId: subjectId,
      );
    }
  }

  Future<void> _confirmDeleteRoadmap(RoadmapModel roadmap, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.roadmapDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppTheme.destructiveButtonStyle(context),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(plannerProvider.notifier).deleteRoadmap(roadmap.id, l10n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);

    ref.listen<PlannerState>(plannerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(next.error!.contains('{') || next.error!.contains('Exception')
              ? l.somethingWentWrong
              : next.error!)),
        );
        ref.read(plannerProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(plannerProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studyPlanner),
        actions: [
          if (state.plan != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.moreOptions,
              onSelected: (value) async {
                switch (value) {
                  case 'redistribute':
                    final missedMinutes = state.plan!.targetMinutesPerDay.toInt();
                    await ref.read(plannerProvider.notifier).redistributeWorkload(missedMinutes, l10n);
                    break;
                  case 'extend':
                    _showCatchUpForMenu(l10n, state);
                    break;
                  case 'regenerate':
                    await ref.read(plannerProvider.notifier).regenerateFromAdherence(l10n);
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'extend',
                  child: ListTile(
                    leading: const Icon(Icons.date_range, size: 20),
                    title: Text(l10n.catchUp),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'redistribute',
                  child: ListTile(
                    leading: const Icon(Icons.replay, size: 20),
                    title: Text(l10n.redistribute),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'regenerate',
                  child: ListTile(
                    leading: const Icon(Icons.refresh, size: 20),
                    title: Text(l10n.regeneratePlan),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Semantics(label: l10n.studyPlanner, child: Tab(text: l10n.studyPlanner)),
            Semantics(label: l10n.calendar, child: Tab(text: l10n.calendar)),
            Semantics(label: l10n.roadmaps, child: Tab(text: l10n.roadmaps)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StudyPlanTab(fixedStudentId: widget.fixedStudentId),
          state.plan != null
              ? CalendarViewWidget(
                  plan: state.plan!,
                  roadmaps: state.roadmaps,
                  onDayTap: (topicId, topicTitle, subjectId) {
                    if (topicId.isEmpty) return;
                    Navigator.pushNamed(
                      context,
                      AppRoutes.tutor,
                      arguments: TutorArgs(
                        topicId: topicId,
                        topicTitle: topicTitle,
                        subjectId: subjectId,
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month,
                          size: ResponsiveUtils.emptyStateIconSize(context),
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(l10n.noStudyPlanYet, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _tabController.animateTo(0),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l10n.createStudyPlan),
                      ),
                    ],
                  ),
                ),
          RoadmapsTab(
            onCreateRoadmap: _showCreateRoadmapDialog,
            onEdit: (roadmap) => _showCreateRoadmapDialog(existing: roadmap),
            onDelete: (roadmap) => _confirmDeleteRoadmap(roadmap, l10n),
          ),
        ],
      ),
    );
  }

  void _showCatchUpForMenu(AppLocalizations l10n, PlannerState state) {
    final notifier = ref.read(plannerProvider.notifier);
    final daysAway = 3;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.catchUpTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.catchUpDescription(daysAway),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.catchUpWithStrategy('redistribute:all', daysAway, l10n);
                },
                icon: const Icon(Icons.replay),
                label: Text(l10n.catchUpRedistribute),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.catchUpWithStrategy('extend', daysAway, l10n);
                },
                icon: const Icon(Icons.date_range),
                label: Text(l10n.catchUpExtend(daysAway)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.catchUpWithStrategy('regenerate', daysAway, l10n);
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.regeneratePlan),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
