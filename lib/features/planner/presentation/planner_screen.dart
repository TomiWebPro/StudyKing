import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/data/repositories/plan_repository.dart';
import '../../../core/services/personal_learning_plan_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/data/models/personal_learning_plan_model.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../../teaching/presentation/tutor_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

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
    _planRepo = PlanRepository();
    _masteryService = MasteryGraphService();
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
          _error = result.error ?? 'Failed to generate plan';
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TutorScreen(
          topicId: topicId,
          topicTitle: topicTitle,
          subjectId: subjectId,
        ),
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
                  final narrow = constraints.maxWidth < 400;
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              if (_plan != null) ...[
                _buildPlanSummary(context),
                const SizedBox(height: 16),
                _buildDailyPlans(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSummary(BuildContext context) {
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
                Text('Plan Summary', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildSummaryChip('${summary.totalQuestions}Q', 'Total'),
                _buildSummaryChip('${summary.totalMinutes}min', 'Total Time'),
                _buildSummaryChip('${summary.newTopics} new', 'Topics'),
                _buildSummaryChip('${summary.reviewTopics} review', 'Review'),
                _buildSummaryChip('${(summary.estimatedCoverage * 100).round()}%', 'Coverage'),
              ],
            ),
            if (summary.focusAreas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Focus: ${summary.focusAreas.join(", ")}', style: Theme.of(context).textTheme.bodySmall),
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
                    day.focus ?? 'Study Day',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (day.isRestDay)
                  Chip(
                    label: const Text('Rest', style: TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (!day.isRestDay)
                  Text('${day.targetQuestions}Q \u00b7 ${day.targetMinutes}min',
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
                subtitle: Text('${topic.estimatedQuestions}Q \u00b7 ${topic.estimatedMinutes}min',
                    style: Theme.of(context).textTheme.bodySmall),
                trailing: topic.topicId.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.smart_toy_outlined, size: 20),
                        tooltip: 'Start tutoring',
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
