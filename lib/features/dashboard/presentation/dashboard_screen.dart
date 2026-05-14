import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:studyking/features/dashboard/presentation/widgets/summary_row.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weekly_chart.dart';
import 'package:studyking/features/dashboard/presentation/widgets/plan_adherence_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/mastery_progress_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weak_areas_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/topic_breakdown_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/badges_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/export_section.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String studentId;

  const DashboardScreen({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final MasteryGraphService _masteryService;
  late final StudyProgressTracker _tracker;
  late final InstrumentationService _instrumentation;
  late final TopicRepository _topicRepo;
  late final FocusSessionService _focusService;
  late final PlanAdherenceRepository _adherenceRepo;

  List<MasteryState> _allMastery = [];
  Map<String, dynamic>? _snapshot;
  Map<String, dynamic>? _overallStats;
  List<Map<String, dynamic>> _weeklyTrend = [];
  List<Map<String, dynamic>> _badges = [];
  Map<String, dynamic>? _focusTodayStats;
  double _averageAdherence = 0.0;
  double _weeklyAdherence = 0.0;
  bool _isLoading = true;
  final Map<String, String> _topicNameCache = {};

  @override
  void initState() {
    super.initState();
    _masteryService = ref.read(masteryGraphServiceProvider);
    _tracker = ref.read(dashboardStudyProgressTrackerProvider);
    _instrumentation = ref.read(dashboardInstrumentationServiceProvider);
    _topicRepo = ref.read(dashboardTopicRepositoryProvider);
    _focusService = ref.read(dashboardFocusServiceProvider);
    _adherenceRepo = ref.read(dashboardAdherenceRepositoryProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _instrumentation.init();
    await _topicRepo.init();
    await _adherenceRepo.init();
    try {
      await _focusService.repository.init();
      _focusTodayStats = await _focusService.getTodayStats();
    } catch (_) {}

    final masteryResult = await _masteryService.getAllTopicMastery(widget.studentId);
    if (masteryResult.isSuccess) {
      _allMastery = masteryResult.data!;
    }

    final snapshotResult = await _masteryService.getMasterySnapshot(widget.studentId);
    if (snapshotResult.isSuccess) {
      _snapshot = snapshotResult.data;
    }

    _overallStats = await _tracker.getOverallStats(widget.studentId);
    _weeklyTrend = await _tracker.getWeeklyTrend(8, studentId: widget.studentId);
    _badges = await _tracker.getBadges(widget.studentId);
    _averageAdherence = await _adherenceRepo.getAverageAdherence(widget.studentId);
    final weeklyRecords = await _adherenceRepo.getWeekly(widget.studentId);
    _weeklyAdherence = weeklyRecords.isEmpty
        ? 0.0
        : weeklyRecords
                .fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
            weeklyRecords.length;

    for (final state in _allMastery) {
      if (!_topicNameCache.containsKey(state.topicId)) {
        try {
          final topic = await _topicRepo.get(state.topicId);
          _topicNameCache[state.topicId] = topic?.title ?? state.topicId;
        } catch (_) {
          _topicNameCache[state.topicId] = state.topicId;
        }
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _resolveTopicName(String topicId) {
    return _topicNameCache[topicId] ?? topicId;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: const DashboardHeader(),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: SummaryRow(overallStats: _overallStats),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.focusMode),
                  child: SessionSummaryCard(
                    todayStats: _focusTodayStats,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(4),
                child: WeeklyChart(weeklyTrend: _weeklyTrend),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: PlanAdherenceCard(
                  averageAdherence: _averageAdherence,
                  weeklyAdherence: _weeklyAdherence,
                ),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(6),
                child: MasteryProgressCard(snapshot: _snapshot),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(7),
                child: WeakAreasCard(
                  allMastery: _allMastery,
                  resolveTopicName: _resolveTopicName,
                ),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(8),
                child: TopicBreakdownCard(
                  allMastery: _allMastery,
                  resolveTopicName: _resolveTopicName,
                ),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(9),
                child: BadgesCard(badges: _badges),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(10),
                child: ExportSection(
                  studentId: widget.studentId,
                  tracker: _tracker,
                  instrumentation: _instrumentation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
