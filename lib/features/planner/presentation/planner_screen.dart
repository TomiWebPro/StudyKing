import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/responsive.dart';
import '../providers/planner_providers.dart';
import '../widgets/plan_summary_card.dart';
import '../widgets/daily_plan_card.dart';
import '../widgets/roadmap_card.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  final String? fixedStudentId;

  const PlannerScreen({super.key, this.fixedStudentId});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(plannerProvider.notifier).loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _openTutorMode(String topicId, String topicTitle, String subjectId) {
    if (topicId.isEmpty) return;
    if (!mounted) return;
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

  Future<void> _generatePlan() async {
    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty ||
        daysValue == null ||
        hoursValue == null ||
        daysValue <= 0 ||
        hoursValue <= 0) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFieldsCorrectly)),
      );
      return;
    }

    await ref.read(plannerProvider.notifier).generatePlan(
          course: course,
          daysValue: daysValue,
          hoursValue: hoursValue,
        );
  }

  Future<void> _showCreateRoadmapDialog() async {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      goalController.dispose();
      daysController.dispose();
    });

    if (result == null || result['goal']!.isEmpty) return;

    final goal = result['goal']!;
    final days = int.tryParse(result['days'] ?? '') ?? 30;

    if (!mounted) return;
    await ref.read(plannerProvider.notifier).createRoadmap(
          goal: goal,
          days: days,
          l10n: AppLocalizations.of(context)!,
        );
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
            Tab(text: l10n.studyPlanner),
            Tab(text: l10n.roadmaps),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyPlanTab(l10n, state),
          _buildRoadmapsTab(l10n, state),
        ],
      ),
    );
  }

  Widget _buildStudyPlanTab(AppLocalizations l10n, PlannerState state) {
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
                label: state.isGenerating ? l10n.generating : l10n.generatePlan,
                child: ElevatedButton.icon(
                  onPressed: state.isGenerating ? null : _generatePlan,
                  icon: state.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calendar_today),
                  label: Text(state.isGenerating
                      ? l10n.generating
                      : l10n.generatePlan),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (state.error != null && _tabController.index == 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(state.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            if (state.plan != null) ...[
              PlanSummaryCard(summary: state.plan!.summary),
              const SizedBox(height: 16),
              _buildDailyPlans(state, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPlans(PlannerState state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.yourStudySchedule,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...state.plan!.dailyPlans.map(
          (day) => DailyPlanCard(
            day: day,
            onStartTutoring: _openTutorMode,
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapsTab(AppLocalizations l10n, PlannerState state) {
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
                  onPressed: _showCreateRoadmapDialog,
                  icon: const Icon(Icons.add_road),
                  label: Text(l10n.createRoadmap),
                ),
              ),
            ),
          ),
          if (state.isLoadingRoadmaps)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.roadmaps.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map,
                        size: 64,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.roadmaps.length,
                itemBuilder: (context, index) {
                  return RoadmapCard(roadmap: state.roadmaps[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
