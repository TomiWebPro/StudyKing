import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/utils/answer_comparator.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';
import 'package:studyking/core/widgets/error_retry_widget.dart';
import 'package:studyking/features/planner/presentation/widgets/progress_overlay_widget.dart';
import 'adherence_banner.dart';
import 'daily_plans_section.dart';
import 'missed_lessons_section.dart';
import 'multi_syllabus_input.dart';
import 'pace_adjustment_card.dart';
import 'pending_actions_section.dart';
import 'scheduled_lessons_section.dart';
import 'subject_progress_tabs.dart';
import 'plan_summary_card.dart';
import 'lesson_booking_sheet.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class StudyPlanTab extends ConsumerStatefulWidget {
  final String? fixedStudentId;

  const StudyPlanTab({super.key, this.fixedStudentId});

  @override
  ConsumerState<StudyPlanTab> createState() => _StudyPlanTabState();
}

class _StudyPlanTabState extends ConsumerState<StudyPlanTab> {
  static final Logger _logger = const Logger('StudyPlanTab');
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final List<SyllableEntry> _syllabusEntries = [];
  bool _useMultiSyllabus = false;
  List<Subject> _allSubjects = [];
  String? _subjectsError;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _courseController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    for (final entry in _syllabusEntries) {
      entry.dispose();
    }
    super.dispose();
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
      if (mounted) {
        setState(() => _subjectsError = AppLocalizations.of(context)!.somethingWentWrong);
      }
    }
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
            content: Text(l10nGen.errorWithMessage(l10nGen.subjectNoTopics(course))),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);

    if (state.isGenerating && state.plan == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: ResponsiveUtils.screenPadding(context),
      physics: const AlwaysScrollableScrollPhysics(),
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isGenerating)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            if (state.pendingActions.isNotEmpty) ...[
              const PendingActionsSection(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.adherenceDeviation != null &&
                state.adherenceDeviation!.requiresRegeneration) ...[
              const AdherenceBanner(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.plan != null) ...[
              _PlanProgressSection(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.scheduledLessons.isNotEmpty) ...[
              const ScheduledLessonsSection(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (state.missedLessons.isNotEmpty) ...[
              const MissedLessonsSection(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            ],
            if (_subjectsError != null)
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
              MultiSyllabusInput(
                entries: _syllabusEntries,
                allSubjects: _allSubjects,
                onAddEntry: () => setState(() => _syllabusEntries.add(SyllableEntry())),
                onRemoveEntry: (index) {
                  setState(() {
                    _syllabusEntries[index].dispose();
                    _syllabusEntries.removeAt(index);
                  });
                },
                onSubjectChanged: (index, subjectId) {
                  setState(() {
                    _syllabusEntries[index].selectedSubjectId = subjectId;
                    _syllabusEntries[index].selectedSubjectTitle = _allSubjects
                        .where((s) => s.id == subjectId)
                        .firstOrNull
                        ?.name;
                    _syllabusEntries[index].subjectController.text =
                        _syllabusEntries[index].selectedSubjectTitle ?? '';
                  });
                },
              )
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
            if (state.error != null)
              Container(
                padding: ResponsiveUtils.cardPadding(context),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(state.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            if (state.plan != null) ...[
              if (state.plan!.syllabusGoals.isNotEmpty)
                SubjectProgressTabs(fixedStudentId: widget.fixedStudentId)
              else ...[
                PlanSummaryCard(
                  summary: state.plan!.summary,
                  syllabusGoals: state.plan!.syllabusGoals,
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              ],
              const PaceAdjustmentCard(),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              DailyPlansSection(
                onStartTutoring: _openTutorMode,
                onScheduleLesson: _openLessonBooking,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openTutorMode(String topicId, String topicTitle, String subjectId,
      {int durationMinutes = 45, String? scheduledSessionId}) {
    if (topicId.isEmpty || !mounted) return;
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
}

class _PlanProgressSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    child: Text(l10n.noDataUploaded, style: Theme.of(context).textTheme.bodyMedium),
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
        child: ErrorRetryWidget(
          message: l10n.somethingWentWrong,
          onRetry: () => ref.invalidate(planProgressProvider),
        ),
      ),
    );
  }
}
