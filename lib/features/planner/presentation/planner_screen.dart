import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/data/repositories/plan_repository.dart';
import '../../../core/data/repositories/mastery_graph_repository.dart';
import '../../../core/data/repositories/topic_repository.dart';
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

class _PlannerScreenState extends State<PlannerScreen> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  bool _isGenerating = false;
  PersonalLearningPlan? _plan;
  PersonalLearningPlanService? _planService;
  late PlanRepository _planRepo;
  late MasteryGraphService _masteryService;
  String? _error;

  @override
  void initState() {
    super.initState();
    _planRepo = widget.planRepository ?? PlanRepository();
    _masteryService = MasteryGraphService(
      repository: widget.masteryGraphRepository,
    );
    _loadExistingPlan();
  }

  @override
  void dispose() {
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

  Future<void> _generatePlan() async {
    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty || daysValue == null || hoursValue == null || daysValue <= 0 || hoursValue <= 0) {
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
      appBar: AppBar(title: Text(l10n.studyPlanner)),
      body: SingleChildScrollView(
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
                        TextField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                      const SizedBox(width: 16),
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
              const SizedBox(height: 16),
              Semantics(
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
              const SizedBox(height: 16),
              if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
      ),
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
