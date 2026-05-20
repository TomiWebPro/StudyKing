import 'package:flutter/material.dart';
import 'package:studyking/core/utils/answer_comparator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/data/models/session_model.dart';
import '../../../core/data/models/subject_model.dart';
import '../../../core/services/student_id_service.dart';
import '../../../features/subjects/data/repositories/subject_repository.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../data/models/personal_learning_plan_model.dart';
import '../data/models/roadmap_model.dart';
import '../providers/planner_providers.dart';
import '../../../core/services/plan_adherence_orchestrator.dart';
import 'widgets/plan_summary_card.dart';
import 'widgets/daily_plan_card.dart';
import 'widgets/roadmap_card.dart';
import 'widgets/pending_action_card.dart';
import 'widgets/lesson_booking_sheet.dart';
import 'widgets/progress_overlay_widget.dart';
import 'widgets/calendar_view_widget.dart';
import 'widgets/syllabus_progress_card.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  final String? fixedStudentId;

  const PlannerScreen({super.key, this.fixedStudentId});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _SyllabusEntry {
  String? selectedSubjectId;
  String? selectedSubjectTitle;
  final TextEditingController subjectController;
  final TextEditingController daysController;
  final TextEditingController hoursController;

  _SyllabusEntry()
      : subjectController = TextEditingController(),
        daysController = TextEditingController(),
        hoursController = TextEditingController();

  void dispose() {
    subjectController.dispose();
    daysController.dispose();
    hoursController.dispose();
  }
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  static final Logger _logger = const Logger('PlannerScreen');
  late TabController _tabController;

  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final List<_SyllabusEntry> _syllabusEntries = [];
  bool _useMultiSyllabus = false;
  List<Subject> _allSubjects = [];
  String? _subjectsError;
  double _paceHours = 1.0;

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
        setState(() {
          _allSubjects = result.data ?? [];
          _subjectsError = null;
        });
      }
    } catch (e) {
      _logger.w('Failed to load subjects', e);
      if (mounted) setState(() => _subjectsError = AppLocalizations.of(context)!.somethingWentWrong);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    for (final entry in _syllabusEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _openTutorMode(String topicId, String topicTitle, String subjectId,
      {int durationMinutes = 45, String? scheduledSessionId}) {
    if (topicId.isEmpty) return;
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        durationMinutes: durationMinutes,
        scheduledSessionId: scheduledSessionId,
      ),
    );
  }

  Future<void> _openLessonBooking(
      String topicId, String topicTitle, String subjectId) async {
    if (!mounted) return;
    final l10nCtx = AppLocalizations.of(context)!;
    final plannerService = ref.read(plannerServiceProvider);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LessonBookingSheet(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        plannerService: plannerService,
        onSchedule: (scheduledTime, durationMinutes) async {
          await ref.read(plannerProvider.notifier).scheduleLesson(
                topicId: topicId,
                topicTitle: topicTitle,
                subjectId: subjectId,
                scheduledTime: scheduledTime,
                l10n: l10nCtx,
                durationMinutes: durationMinutes,
              );
        },
      ),
    );
  }

  Future<void> _generatePlan() async {
    final l10nGen = AppLocalizations.of(context)!;

    if (_useMultiSyllabus) {
      final validEntries = _syllabusEntries.where((e) =>
          e.selectedSubjectId != null &&
          e.selectedSubjectId!.isNotEmpty &&
          int.tryParse(e.daysController.text) != null &&
          int.tryParse(e.hoursController.text) != null &&
          int.parse(e.daysController.text) > 0 &&
          int.parse(e.hoursController.text) > 0).toList();

      if (validEntries.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10nGen.fillAllFieldsCorrectly)),
        );
        return;
      }

      for (final entry in validEntries) {
        final topicRepo = TopicRepository();
        await topicRepo.init();
        final topicsResult = await topicRepo.getBySubject(entry.selectedSubjectId!);
        final topics = topicsResult.data ?? [];
          if (topics.isEmpty) {
            final subjectName = entry.selectedSubjectTitle ?? entry.selectedSubjectId!;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10nGen.subjectNoTopics(subjectName))),
              );
            }
            return;
          }
      }

      final syllabusGoals = validEntries.map((e) => SyllabusGoal(
        subjectId: e.selectedSubjectId!,
        subjectTitle: e.selectedSubjectTitle ?? e.subjectController.text.trim(),
        targetDays: int.parse(e.daysController.text),
        targetHoursPerDay: int.parse(e.hoursController.text),
      )).toList();

      final overallDays = syllabusGoals.fold<int>(0, (sum, g) => sum + g.targetDays) ~/ syllabusGoals.length;
      final overallHours = syllabusGoals.fold<int>(0, (sum, g) => sum + g.targetHoursPerDay);

      await ref.read(plannerProvider.notifier).generatePlanFromSyllabus(
        syllabusGoals: syllabusGoals,
        daysValue: overallDays.clamp(1, 365),
        hoursValue: overallHours.clamp(1, 24),
        l10n: l10nGen,
      );
      return;
    }

    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty ||
        daysValue == null ||
        hoursValue == null ||
        daysValue <= 0 ||
        hoursValue <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nGen.fillAllFieldsCorrectly)),
      );
      return;
    }

    if (_allSubjects.isNotEmpty) {
      final matchingSubject = _allSubjects.where(
        (s) => AnswerComparator.areEquivalent(s.name, course),
      ).firstOrNull;
      if (matchingSubject == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nGen.errorWithMessage(l10nGen.courseNotFound(course))),
          ),
        );
        return;
      }
      final topicRepo = TopicRepository();
      await topicRepo.init();
      final topicsResult = await topicRepo.getBySubject(matchingSubject.id);
      final hasTopics = (topicsResult.data ?? []).isNotEmpty;
      if (!hasTopics) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nGen.errorWithMessage(
              l10nGen.subjectNoTopics(course),
            )),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: l10nGen.addTopic,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.subjectDetail,
                  arguments: matchingSubject,
                );
              },
            ),
          ),
        );
        return;
      }
    }

    await ref.read(plannerProvider.notifier).generatePlan(
          course: course,
          daysValue: daysValue,
          hoursValue: hoursValue,
          l10n: l10nGen,
        );
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
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(next.error!)),
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
          _buildStudyPlanTab(l10n, state),
          _buildCalendarTab(l10n, state),
          _buildRoadmapsTab(l10n, state),
        ],
      ),
    );
  }

  Widget _buildStudyPlanTab(AppLocalizations l10n, PlannerState state) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.screenPadding(context),
      physics: const AlwaysScrollableScrollPhysics(),
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.pendingActions.isNotEmpty) ...[
              _buildPendingActionsSection(l10n, state),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.adherenceDeviation != null &&
                state.adherenceDeviation!.requiresRegeneration) ...[
              _buildAdherenceBanner(l10n, state),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.plan != null) ...[
              _buildProgressOverlay(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.scheduledLessons.isNotEmpty) ...[
              _buildScheduledLessonsSection(l10n, state),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.missedLessons.isNotEmpty) ...[
              _buildMissedLessonsSection(l10n, state),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (_subjectsError != null && _tabController.index == 0)
              Container(
                width: double.infinity,
                padding: ResponsiveUtils.cardPadding(context),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_subjectsError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.createStudyPlan,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                TextButton.icon(
                  icon: Icon(_useMultiSyllabus ? Icons.subject : Icons.menu_book),
                  label: Text(_useMultiSyllabus ? l10n.courseSubject : l10n.subjects),
                  onPressed: () => setState(() => _useMultiSyllabus = !_useMultiSyllabus),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            if (_useMultiSyllabus)
              _buildMultiSyllabusInput(l10n)
            else ...[
              TextField(
                controller: _courseController,
                decoration: InputDecoration(
                  labelText: l10n.courseSubject,
                  hintText: l10n.courseHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_allSubjects.isNotEmpty)
                Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4, top: 4),
                  child: Text(
                    l10n.planSubjectHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = ResponsiveUtils.breakpointOf(context).isMobile;
                  if (narrow) {
                    return Column(
                      children: [
                        TextField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                        TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.hoursPerDay,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.horizontalSpacing(context)),
                      Expanded(
                        child: TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.hoursPerDay,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            Semantics(
              button: true,
              label: state.isGenerating ? l10n.generating : l10n.generatePlan,
              child: ElevatedButton.icon(
                onPressed: state.isGenerating ? null : _generatePlan,
                icon: state.isGenerating
                    ? ResponsiveUtils.loaderInTouchTarget(size: 20)
                    : const Icon(Icons.calendar_today),
                label: Text(state.isGenerating
                    ? l10n.generating
                    : l10n.generatePlan),
              ),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            if (state.error != null && _tabController.index == 0)
              Container(
                padding: ResponsiveUtils.cardPadding(context),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(state.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
              if (state.plan != null) ...[
              if (state.plan!.syllabusGoals.isNotEmpty)
                _buildSubjectProgressTabs(l10n, state)
              else ...[
                PlanSummaryCard(summary: state.plan!.summary),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              ],
              _buildPaceAdjustment(l10n, state),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              _buildDailyPlans(state, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaceAdjustment(AppLocalizations l10n, PlannerState state) {
    if (state.plan == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.rocket_launch, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.noStudyPlanYet,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
        ),
      );
    }
    final currentHours = state.plan!.targetMinutesPerDay / 60;
    _paceHours = currentHours;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.planAdjusted,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l10n.hoursPerDay),
                const Spacer(),
                Text(
                  '${formatDecimal(_paceHours, l10n.localeName, minFractionDigits: 1)} ${l10n.hoursPerDay}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _paceHours,
              min: 0.5,
              max: 8.0,
              divisions: 15,
              label: '${formatDecimal(_paceHours, l10n.localeName, minFractionDigits: 1)} ${l10n.hoursPerDay}',
              onChanged: (value) {
                setState(() => _paceHours = value);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final newTargetMinutes = (_paceHours * 60).round();
                  ref.read(plannerProvider.notifier).adjustPace(
                    newTargetMinutes.toDouble(),
                    l10n,
                  );
                },
                icon: const Icon(Icons.check, size: 18),
                label: Text(l10n.planAdjusted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSyllabusInput(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._syllabusEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: e.selectedSubjectId,
                          decoration: InputDecoration(
                            labelText: '${l10n.courseSubject} ${index + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          hint: Text(l10n.courseHint),
                          isExpanded: true,
                          items: [
                            ..._allSubjects.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (v) {
                            setState(() {
                              e.selectedSubjectId = v;
                              e.selectedSubjectTitle = _allSubjects
                                  .where((s) => s.id == v)
                                  .firstOrNull
                                  ?.name;
                              e.subjectController.text = e.selectedSubjectTitle ?? '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                        tooltip: l10n.delete,
                        onPressed: _syllabusEntries.length > 1
                            ? () {
                                setState(() {
                                  e.dispose();
                                  _syllabusEntries.removeAt(index);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: e.daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: e.hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.hoursPerDay,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (e.selectedSubjectId != null) ...[
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: _getTopicCount(e.selectedSubjectId!),
                      builder: (ctx, snap) {
                        final count = snap.data ?? 0;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(start: 4),
                          child: Text(
                            l10n.topicCountTemplate(count),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addCourseSubject),
          onPressed: () => setState(() => _syllabusEntries.add(_SyllabusEntry())),
        ),
      ],
    );
  }

  Future<int> _getTopicCount(String subjectId) async {
    try {
      final topicRepo = TopicRepository();
      await topicRepo.init();
      final result = await topicRepo.getBySubject(subjectId);
      return result.data?.length ?? 0;
    } catch (e) {
      _logger.w('Failed to get topic count: $e');
      return 0;
    }
  }

  Widget _buildSubjectProgressTabs(AppLocalizations l10n, PlannerState state) {
    final goals = state.plan!.syllabusGoals;
    final studentId = widget.fixedStudentId ?? ref.read(studentIdServiceProvider).getStudentId();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.subjectProgress,
            style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        ...goals.map((goal) {
          final subjectPlans = state.plan!.subjectPlans;
          final plansForSubject = subjectPlans[goal.subjectId] ?? [];
          final uniqueTopicCount = plansForSubject
              .expand((plan) => plan.priorityTopics)
              .map((t) => t.topicId)
              .toSet()
              .length;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(goal.subjectTitle.isNotEmpty
                          ? goal.subjectTitle[0]
                          : 'S'),
                    ),
                    title: Text(goal.subjectTitle.isNotEmpty
                        ? goal.subjectTitle
                        : l10n.unknown),
                    subtitle: Text(
                        '${goal.targetDays} ${l10n.days}, $uniqueTopicCount ${l10n.topics}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.hoursPerDayAbbrev(formatDecimal(goal.targetHoursPerDay.toDouble(), l10n.localeName)),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  SyllabusProgressCard(
                    studentId: studentId,
                    goal: goal,
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        PlanSummaryCard(summary: state.plan!.summary),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
      ],
    );
  }

  Widget _buildPendingActionsSection(
      AppLocalizations l10n, PlannerState state) {
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_active,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.pendingActions,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...state.pendingActions.map((action) => PendingActionCard(
              action: action,
              onAccept: () => ref
                  .read(plannerProvider.notifier)
                  .acceptPendingAction(action.id, l10n),
              onDismiss: () => ref
                  .read(plannerProvider.notifier)
                  .dismissPendingAction(action.id, l10n),
            )),
      ],
    ),
    );
  }

  Widget _buildAdherenceBanner(AppLocalizations l10n, PlannerState state) {
    final deviation = state.adherenceDeviation!;
    final missedMinutes = state.plan?.targetMinutesPerDay.toInt() ?? 60;
    final isAbsence = deviation is AbsenceDeviation;
    return FocusTraversalGroup(
      child: Container(
      padding: ResponsiveUtils.cardPadding(context),
      decoration: BoxDecoration(
        color: deviation.requiresEscalation
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            deviation.requiresEscalation
                ? Icons.warning_amber_rounded
                : Icons.info_outline,
            color: deviation.requiresEscalation
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviation.message,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isAbsence) ...[
                      TextButton.icon(
                        onPressed: () => _showCatchUpSheet(l10n, state),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text(l10n.catchUp),
                      ),
                    ] else ...[
                      TextButton.icon(
                        onPressed: () => ref
                            .read(plannerProvider.notifier)
                            .redistributeWorkload(missedMinutes, l10n),
                        icon: const Icon(Icons.replay, size: 16),
                        label: Text(l10n.redistribute),
                      ),
                      const SizedBox(width: 8),
                      if (deviation.requiresRegeneration)
                        TextButton.icon(
                          onPressed: () => ref
                              .read(plannerProvider.notifier)
                              .regenerateFromAdherence(l10n),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(l10n.regeneratePlan),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _showCatchUpSheet(AppLocalizations l10n, PlannerState state) async {
    final daysAway = state.adherenceDeviation is AbsenceDeviation
        ? (state.adherenceDeviation as AbsenceDeviation).daysSinceLastActivity
        : 3;
    final notifier = ref.read(plannerProvider.notifier);

    if (!mounted) return;
    await showModalBottomSheet(
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

  Widget _buildMissedLessonsSection(
      AppLocalizations l10n, PlannerState state) {
    if (state.missedLessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.allCaughtUp,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber,
                size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(l10n.missedLessonsCount(state.missedLessons.length),
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...state.missedLessons.take(3).map((lesson) {
          final time = DateFormat.Hm(l10n.localeName).format(lesson.startTime);
          final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.cancel_outlined,
                  size: 20, color: Theme.of(context).colorScheme.error),
              title: Text(title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  )),
              subtitle: Text(
                '${l10n.missedLessonLabel}, $time',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }),
        if (state.missedLessons.length > 3)
          TextButton(
            onPressed: () {
              ref.read(plannerProvider.notifier).dismissAllMissed(l10n);
            },
            child: Text(l10n.dismissAllMissed),
          ),
      ],
    ),
    );
  }

  Widget _buildScheduledLessonsSection(
      AppLocalizations l10n, PlannerState state) {
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.scheduledLessons,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
          ...state.scheduledLessons.take(3).map((lesson) {
          final time = DateFormat.Hm(l10n.localeName).format(lesson.startTime);
          final title = lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '';
          final isCompleted = lesson.status == SessionStatus.completed || lesson.completed;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: Icon(
                isCompleted ? Icons.check_circle : Icons.menu_book,
                size: 20,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  )),
              subtitle: Text(
                l10n.lessonTimeStatus(lesson.topicId ?? '', time, isCompleted ? ', ${l10n.completed}' : ''),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted)
                    Semantics(
                      button: true,
                      label: l10n.startTutoring,
                      child: IconButton(
                        icon: Icon(Icons.play_circle_filled, size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        tooltip: l10n.startTutoring,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.tutor,
                          arguments: TutorArgs(
                            topicId: lesson.topicId ?? '',
                            topicTitle: title,
                            subjectId: lesson.subjectId ?? '',
                            durationMinutes: lesson.plannedDurationMinutes ?? 45,
                            scheduledSessionId: lesson.id,
                          ),
                        ),
                      ),
                    ),
                  if (!isCompleted)
                    IconButton(
                      icon: Icon(Icons.refresh, size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      tooltip: l10n.rescheduleLesson,
                      onPressed: () => _openRescheduleLesson(lesson, l10n),
                    ),
                  if (!isCompleted)
                    IconButton(
                      icon: Icon(Icons.cancel_outlined, size: 18,
                          color: Theme.of(context).colorScheme.error),
                      tooltip: l10n.cancel,
                      onPressed: () => _confirmCancelLesson(lesson, l10n),
                    ),
                ],
              ),
            ),
          );
        }),
        if (state.scheduledLessons.length > 3)
          TextButton(
            onPressed: () {
              final first = state.scheduledLessons.first;
              Navigator.pushNamed(context, AppRoutes.lessonList,
                  arguments: LessonListArgs(
                    topicId: first.topicId ?? '',
                    topicTitle: l10n.scheduledLessons,
                    subjectId: first.subjectId,
                  ));
            },
            child: Text(l10n.moreLessonsCount(
                state.scheduledLessons.length - 3)),
          ),
      ],
    ),
    );
  }

  Future<void> _confirmCancelLesson(Session lesson, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancel),
        content: Text(l10n.cancelLessonConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.noThanks),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(plannerProvider.notifier).cancelLesson(lesson.id, l10n);
    }
  }

  Future<void> _openRescheduleLesson(Session lesson, AppLocalizations l10n) async {
    if (!mounted) return;
    final plannerService = ref.read(plannerServiceProvider);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LessonBookingSheet(
        topicId: lesson.topicId ?? '',
        topicTitle: lesson.tutorMetadata?.topicTitle ?? lesson.topicId ?? '',
        subjectId: lesson.subjectId ?? '',
        plannerService: plannerService,
        initialDate: lesson.startTime,
        initialDuration: lesson.plannedDurationMinutes ?? 30,
        onSchedule: (scheduledTime, durationMinutes) async {
          await ref.read(plannerProvider.notifier).rescheduleLesson(
                sessionId: lesson.id,
                newStartTime: scheduledTime,
                durationMinutes: durationMinutes,
                l10n: l10n,
              );
        },
      ),
    );
  }

  Widget _buildDailyPlans(PlannerState state, AppLocalizations l10n) {
    return FocusTraversalGroup(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.yourStudySchedule,
            style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
          ...state.plan!.dailyPlans.map(
          (day) => DailyPlanCard(
            day: day,
            onStartTutoring: (topicId, topicTitle, subjectId) {
              final matchingLessons = state.scheduledLessons.where(
                (s) => s.topicId == topicId && s.status == SessionStatus.planned,
              ).toList();
              final session = matchingLessons.isNotEmpty ? matchingLessons.first : null;
              _openTutorMode(
                topicId, topicTitle, subjectId,
                durationMinutes: session?.plannedDurationMinutes ?? 45,
                scheduledSessionId: session?.id,
              );
            },
            onScheduleLesson: _openLessonBooking,
            onCatchUp: !day.isCompleted && day.date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                ? () => _showCatchUpSheet(l10n, state)
                : null,
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildProgressOverlay() {
    final l10n = AppLocalizations.of(context)!;
    final progressAsync = ref.watch(planProgressProvider);
    return progressAsync.when(
      data: (data) {
        if (data.totalPlanDays == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.noDataUploaded,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          );
        }
        return ProgressOverlayWidget(data: data);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LoadingIndicator(),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$err', style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }

  Widget _buildCalendarTab(AppLocalizations l10n, PlannerState state) {
    if (state.plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month,
                size: ResponsiveUtils.emptyStateIconSize(context),
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(l10n.noStudyPlanYet, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return CalendarViewWidget(
      plan: state.plan!,
      roadmaps: state.roadmaps,
      onDayTap: (topicId, topicTitle, subjectId) {
        _openTutorMode(topicId, topicTitle, subjectId);
      },
    );
  }

  Widget _buildRoadmapsTab(AppLocalizations l10n, PlannerState state) {
    final activeRoadmaps = state.roadmaps.where((r) => r.status == 'active').toList();
    final completedRoadmapsList = state.roadmaps.where((r) => r.status == 'completed').toList();

    return FocusTraversalGroup(
      child: Column(
        children: [
          Padding(
            padding: ResponsiveUtils.screenPadding(context),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateRoadmapDialog,
                icon: const Icon(Icons.add_road),
                label: Text(l10n.createRoadmap),
              ),
            ),
          ),
          if (state.roadmaps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.myRoadmaps,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (state.isLoadingRoadmaps)
            const Expanded(
              child: LoadingIndicator(),
            )
          else if (state.roadmaps.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map,
                        size: ResponsiveUtils.emptyStateIconSize(context),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(l10n.noRoadmapsYet,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(l10n.roadmapGoalHint,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: ResponsiveUtils.screenPadding(context),
                itemCount: (activeRoadmaps.isNotEmpty ? 1 : 0) +
                    (completedRoadmapsList.isNotEmpty ? 1 : 0) +
                    state.roadmaps.length,
                itemBuilder: (context, index) {
                  var offset = 0;
                  if (activeRoadmaps.isNotEmpty) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          '${l10n.activeRoadmaps} (${activeRoadmaps.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    offset = 1;
                  }
                  if (index == activeRoadmaps.length + offset) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        '${l10n.completedRoadmaps} (${completedRoadmapsList.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    );
                  }
                  final roadmapIndex = index - offset;
                  final roadmap = roadmapIndex < activeRoadmaps.length
                      ? activeRoadmaps[roadmapIndex]
                      : completedRoadmapsList[roadmapIndex - activeRoadmaps.length];
                  return RoadmapCard(
                    roadmap: roadmap,
                    onToggleMilestone: (roadmapId, milestoneId, isCompleted) {
                      ref
                          .read(plannerProvider.notifier)
                          .toggleMilestoneCompletion(
                            roadmapId: roadmapId,
                            milestoneId: milestoneId,
                            isCompleted: isCompleted,
                            l10n: l10n,
                          );
                    },
                    onEdit: () => _showCreateRoadmapDialog(existing: roadmap),
                    onDelete: () => _confirmDeleteRoadmap(roadmap, l10n),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
