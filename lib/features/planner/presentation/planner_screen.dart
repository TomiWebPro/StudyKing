import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/data/repositories/plan_repository.dart';
import '../../../core/data/repositories/mastery_graph_repository.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../../../core/data/repositories/roadmap_repository.dart';
import '../../../core/data/models/roadmap_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/personal_learning_plan_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/data/models/personal_learning_plan_model.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

class PlannerScreen extends StatefulWidget {
  final PlanRepository? planRepository;
  final MasteryGraphRepository? masteryGraphRepository;
  final TopicRepository? topicRepository;

  const PlannerScreen({
    super.key,
    this.planRepository,
    this.masteryGraphRepository,
    this.topicRepository,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  bool _isGenerating = false;
  PersonalLearningPlan? _plan;
  PersonalLearningPlanService? _planService;
  late PlanRepository _planRepo;
  late MasteryGraphService _masteryService;
  String? _error;

  late RoadmapRepository _roadmapRepo;
  List<RoadmapModel> _roadmaps = [];
  bool _isLoadingRoadmaps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _planRepo = widget.planRepository ?? PlanRepository();
    _masteryService = MasteryGraphService(
      repository: widget.masteryGraphRepository,
    );
    _roadmapRepo = RoadmapRepository();
    _loadExistingPlan();
    _loadRoadmaps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPlan() async {
    final studentId = StudentIdService().getStudentId();
    try {
      await _planRepo.init();
      final existing = await _planRepo.loadPlan(studentId);
      if (existing != null && mounted) {
        setState(() => _plan = existing);
      }
    } catch (_) {}
  }

  Future<void> _loadRoadmaps() async {
    final studentId = StudentIdService().getStudentId();
    setState(() => _isLoadingRoadmaps = true);
    try {
      await _roadmapRepo.init();
      final roadmaps = await _roadmapRepo.getRoadmapsByStudent(studentId);
      if (mounted) {
        setState(() {
          _roadmaps = roadmaps;
          _isLoadingRoadmaps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoadmaps = false);
    }
  }

  Future<void> _generatePlan() async {
    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty || daysValue == null || hoursValue == null ||
        daysValue <= 0 || hoursValue <= 0) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFieldsCorrectly)),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    final studentId = StudentIdService().getStudentId();

    try {
      await _masteryService.init();
      await _planRepo.init();

      _planService = PersonalLearningPlanService(
        masteryService: _masteryService,
        repository: widget.masteryGraphRepository,
        topicRepository: widget.topicRepository,
        planRepository: _planRepo,
        config: PlanGenerationConfig(
          planDurationDays: daysValue,
          targetMinutesPerDay: (hoursValue * 60).toDouble(),
          targetQuestionsPerDay: 15,
        ),
      );

      final result = await _planService!.generatePlan(studentId);

      if (!mounted) return;

      if (result.isSuccess) {
        final plan = result.data!;
        setState(() {
          _plan = plan;
          _isGenerating = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.generatedPlanOverDays(course, daysValue, daysValue * hoursValue))),
        );
      } else {
        setState(() {
          _isGenerating = false;
          _error = result.error ?? AppLocalizations.of(context)!.failedToGeneratePlan;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  Future<void> _createRoadmap() async {
    final l10n = AppLocalizations.of(context)!;
    final goalController = TextEditingController();
    final daysController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createRoadmap),
        content: Column(
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
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'goal': goalController.text.trim(),
              'days': daysController.text.trim(),
            }),
            child: Text(l10n.generateRoadmap),
          ),
        ],
      ),
    );

    goalController.dispose();
    daysController.dispose();

    if (result == null || result['goal']!.isEmpty) return;

    final goal = result['goal']!;
    final days = int.tryParse(result['days'] ?? '') ?? 30;
    final studentId = StudentIdService().getStudentId();

    final now = DateTime.now();
    final targetDate = now.add(Duration(days: days));

    final numMilestones = (days / 7).ceil().clamp(1, 52);
    final milestones = <MilestoneModel>[];
    for (var i = 0; i < numMilestones; i++) {
      final milestoneDeadline = now.add(Duration(
        days: ((i + 1) * days / numMilestones).round(),
      ));
      milestones.add(MilestoneModel(
        id: const Uuid().v4(),
        title: 'Week ${i + 1}',
        description: 'Milestone for week ${i + 1}',
        deadline: milestoneDeadline,
        order: i + 1,
      ));
    }

    final roadmap = RoadmapModel(
      id: const Uuid().v4(),
      studentId: studentId,
      goal: goal,
      createdAt: now,
      targetCompletionDate: targetDate,
      milestones: milestones,
      status: 'active',
    );

    try {
      await _roadmapRepo.init();
      await _roadmapRepo.saveRoadmap(roadmap);
      await _loadRoadmaps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.roadmapGoal)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToGeneratePlan)),
        );
      }
    }
  }

  void _openTutorMode(String topicId, String topicTitle, String subjectId) {
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studyPlanner),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.studyPlanner),
            Tab(text: l10n.roadmaps),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyPlanTab(l10n),
          _buildRoadmapsTab(l10n),
        ],
      ),
    );
  }

  Widget _buildStudyPlanTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.screenPadding(context),
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.createStudyPlan,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: TextField(
                controller: _courseController,
                decoration: InputDecoration(
                  labelText: l10n.courseSubject,
                  hintText: l10n.courseHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = ResponsiveUtils.breakpointOf(context).isMobile;
                if (narrow) {
                  return Column(
                    children: [
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: TextField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3),
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
                }
                return Row(
                  children: [
                    Expanded(
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: TextField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(3),
                        child: TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.hoursPerDay,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            FocusTraversalOrder(
              order: const NumericFocusOrder(4),
              child: Semantics(
                button: true,
                label: _isGenerating ? l10n.generating : l10n.generatePlan,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generatePlan,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calendar_today),
                  label: Text(_isGenerating ? l10n.generating : l10n.generatePlan),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            if (_plan != null) ...[
              _buildPlanSummary(context, l10n),
              const SizedBox(height: 16),
              _buildDailyPlans(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapsTab(AppLocalizations l10n) {
    return FocusTraversalGroup(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createRoadmap,
                  icon: const Icon(Icons.add_road),
                  label: Text(l10n.createRoadmap),
                ),
              ),
            ),
          ),
        if (_isLoadingRoadmaps)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_roadmaps.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _roadmaps.length,
              itemBuilder: (context, index) {
                final roadmap = _roadmaps[index];
                return _buildRoadmapCard(roadmap, l10n);
              },
            ),
          ),
      ],
      ),
    );
  }

  Widget _buildRoadmapCard(RoadmapModel roadmap, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final completedMilestones =
        roadmap.milestones.where((m) => m.isCompleted).length;
    final totalMilestones = roadmap.milestones.length;
    final progress = totalMilestones > 0
        ? completedMilestones / totalMilestones
        : roadmap.completionPercentage / 100.0;
    final statusColor = roadmap.status == 'active'
        ? theme.colorScheme.primary
        : roadmap.status == 'completed'
            ? Colors.green
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roadmap.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    roadmap.goal,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.completionOfValue(progress * 100),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '$completedMilestones/$totalMilestones ${l10n.milestones.toLowerCase()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (roadmap.targetCompletionDate != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.targetCompletion}: ${DateFormat.yMMMd().format(roadmap.targetCompletionDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildMilestoneTimeline(roadmap, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneTimeline(RoadmapModel roadmap, AppLocalizations l10n) {
    if (roadmap.milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.timeline,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final now = DateTime.now();
              final startDate = roadmap.createdAt;
              final endDate = roadmap.targetCompletionDate ??
                  startDate.add(const Duration(days: 30));
              final totalDuration =
                  endDate.difference(startDate).inMilliseconds.toDouble();
              if (totalDuration <= 0) return const SizedBox.shrink();

              return Stack(
                children: [
                  Container(
                    height: 4,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ...roadmap.milestones.map((milestone) {
                    final msDuration =
                        milestone.deadline.difference(startDate).inMilliseconds
                            .toDouble();
                    final left = (msDuration / totalDuration * totalWidth)
                        .clamp(0.0, totalWidth);
                    final isPast = milestone.deadline.isBefore(now);
                    final isCompleted = milestone.isCompleted;
                    final color = isCompleted
                        ? Colors.green
                        : isPast
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary;

                    return Positioned(
                      left: left - 6,
                      top: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'M${milestone.order}',
                            style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: roadmap.milestones.map((ms) {
            final isPast = ms.deadline.isBefore(DateTime.now());
            return Semantics(
              label: l10n.milestoneOfWithDeadline(ms.title,
                  DateFormat.yMMMd().format(ms.deadline)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ms.isCompleted
                      ? Colors.green.withValues(alpha: 0.1)
                      : isPast
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${ms.title}: ${DateFormat.MMMd().format(ms.deadline)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: ms.isCompleted
                        ? Colors.green.shade700
                        : isPast
                            ? Colors.orange.shade700
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlanSummary(BuildContext context, AppLocalizations l10n) {
    final summary = _plan!.summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.planSummary, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildSummaryChip('${summary.totalQuestions}Q', l10n.total),
                _buildSummaryChip('${summary.totalMinutes}min', l10n.totalTime),
                _buildSummaryChip('${summary.newTopics} ${l10n.newTopics}', l10n.topics),
                _buildSummaryChip('${summary.reviewTopics} ${l10n.reviewTopics}', l10n.reviewTopics),
                _buildSummaryChip('${(summary.estimatedCoverage * 100).round()}%', l10n.coverage),
              ],
            ),
            if (summary.focusAreas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.focusLabel(summary.focusAreas.join(", ")), style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDailyPlans(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.yourStudySchedule,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ..._plan!.dailyPlans.map((day) => _buildDayCard(day)),
      ],
    );
  }

  Widget _buildDayCard(DailyPlan day) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.focus ?? l10n.studyDay,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (day.isRestDay)
                  Chip(
                    label: Text(l10n.rest, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (!day.isRestDay)
                  Text(l10n.questionsAndMinutes(day.targetQuestions, day.targetMinutes),
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (!day.isRestDay && day.priorityTopics.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...day.priorityTopics.map((topic) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.school, size: 18, color: Theme.of(context).colorScheme.primary),
                title: Text(topic.topicTitle, style: Theme.of(context).textTheme.bodyMedium),
                subtitle: Text(l10n.topicQuestionsAndMinutes(topic.estimatedQuestions, topic.estimatedMinutes),
                    style: Theme.of(context).textTheme.bodySmall),
                trailing: topic.topicId.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.smart_toy_outlined, size: 20),
                        tooltip: l10n.startTutoring,
                        onPressed: () => _openTutorMode(topic.topicId, topic.topicTitle, ''),
                      )
                    : null,
              )),
            ],
          ],
        ),
      ),
    );
  }
}
