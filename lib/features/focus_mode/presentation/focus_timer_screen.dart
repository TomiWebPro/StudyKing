import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, planAdapterProvider;
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/services/badge_service.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/services/student_id_service.dart' show studentIdValueProvider;
import 'package:studyking/core/routes/app_router.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  final String? preselectedSubjectId;
  final String? preselectedTopicId;
  final int? defaultDurationMinutes;

  const FocusTimerScreen({
    super.key,
    this.preselectedSubjectId,
    this.preselectedTopicId,
    this.defaultDurationMinutes,
  });

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> with WidgetsBindingObserver {
  late final StudyTimerService _service;

  bool _initialized = false;
  bool _showSetup = true;
  int _selectedMinutes = 25;
  Session? _completedSession;
  bool _inBreak = false;
  int _breakRemaining = 0;
  int _breakDuration = 300;
  Timer? _breakTimer;
  String _selectedSubjectId = '';
  bool _showFirstVisitHelp = false;

  Map<String, dynamic>? _todayStats;
  int _weeklyMs = 0;
  List<Session> _recentSessions = [];
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = ref.read(studyTimerServiceProvider);
    _initService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _service.hasActiveSession) {
      _reconcileBackgroundTime();
    }
  }

  void _reconcileBackgroundTime() {
    if (!_service.hasActiveSession || _lastTickMs <= 0) return;
    final expectedMs = DateTime.now().millisecondsSinceEpoch - _lastTickMs;
    if (expectedMs > 2000) {
      _service.reconcileElapsedMs(expectedMs);
      if (_service.elapsedMs >= (_service.currentSession?.plannedDurationMinutes ?? 25) * 60000) {
        _service.completeSession();
      }
    }
  }

  Future<void> _initService() async {
    try {
      _service.addOnSessionComplete(_onSessionComplete);
      _service.addOnTick(_onTick);
      await _loadStats();

      final settings = ref.read(settingsProvider);
      _breakDuration = settings.breakDurationSeconds;

      if (settings.firstFocusVisit) {
        _showFirstVisitHelp = true;
        try {
          ref.read(settingsProvider.notifier).updateFirstFocusVisit();
        } catch (e) {
          const Logger('FocusTimerScreen').e('Failed to update first focus visit: $e');
        }
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      const Logger('FocusTimerScreen').e('Failed to initialize focus timer', e);
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  void _onSessionComplete(Session session) {
    if (!mounted) return;
    setState(() {
      _completedSession = session;
      _showSetup = false;
      _inBreak = true;
      _breakRemaining = _breakDuration;
      _startBreakTimer();
    });
    _loadStats();
    _recordAdherence(session);
    _checkBadges(session);
  }

  Future<void> _checkBadges(Session session) async {
    try {
      final studentId = ref.read(studentIdValueProvider);
      final badgeService = BadgeService();
      await badgeService.checkAndUnlockBadges(studentId);
    } catch (e) {
      // silent - badge check is non-critical
    }
  }

  Future<void> _recordAdherence(Session session) async {
    try {
      final planAdapter = ref.read(planAdapterProvider);
      final elapsedSeconds = session.actualDurationMs ~/ 1000;
      final actualMinutes = (elapsedSeconds / 60).ceil().clamp(1, 480);
      await planAdapter.recordFromFocusSession(
        studentId: ref.read(studentIdValueProvider),
        actualMinutes: actualMinutes,
      );
    } catch (e) {
      // Logged internally by PlanAdapter, non-critical for UX
    }
  }

  void _onTick(int elapsedMs) {
    if (mounted) {
      _lastTickMs = DateTime.now().millisecondsSinceEpoch;
      setState(() {});
    }
  }

  void _startBreakTimer() {
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(Timeouts.second, (_) {
      if (!mounted) return;
      setState(() {
        _breakRemaining--;
      });
      if (_breakRemaining <= 0) {
        _breakTimer?.cancel();
        _breakTimer = null;
        setState(() {
          _inBreak = false;
          _showSetup = true;
          _completedSession = null;
        });
      }
    });
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _service.getTodayStats();
      final weekly = await _service.getTodayDurationMs();
      final recent = await _service.getRecentSessions();
      if (mounted) {
        setState(() {
          _todayStats = stats;
          _weeklyMs = weekly;
          _recentSessions = recent;
        });
      }
    } catch (e) {
      const Logger('FocusTimerScreen').e('Failed to load focus stats', e);
    }
  }

  Future<void> _startFocus() async {
    try {
      final capMinutes = await _service.getDailyCapMinutes();
      if (capMinutes > 0) {
        final remaining = await _service.getRemainingDailyCapMinutes();
        if (remaining > 0 && _selectedMinutes > remaining) {
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            final continueAnyway = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.dailyCapWarningTitle),
                content: Text(l10n.dailyCapWarningBody(_selectedMinutes, remaining)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.continueAnyway),
                  ),
                ],
              ),
            );
            if (continueAnyway != true) return;
          }
        }
      }

      await _service.startSession(
        plannedDurationMinutes: _selectedMinutes,
        type: SessionType.focus,
        subjectId: _selectedSubjectId.isNotEmpty
            ? _selectedSubjectId
            : widget.preselectedSubjectId,
        topicId: widget.preselectedTopicId,
      );
      if (mounted) {
        setState(() => _showSetup = false);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorStartingSession(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breakTimer?.cancel();
    _service.removeOnSessionComplete(_onSessionComplete);
    _service.removeOnTick(_onTick);
    _service.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_service.hasActiveSession) return true;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmExitFocus),
        content: Text(l10n.confirmExitFocusBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.stay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.endSession),
          ),
        ],
      ),
    );
    if (result == true) {
      await _service.cancelSession();
      setState(() => _showSetup = true);
      _loadStats();
    }
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.focusMode)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_service.hasActiveSession,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.focusMode),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: l10n.refreshStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          children: [
            if (_inBreak && _completedSession != null)
              _buildBreakView(theme, cs, l10n)
            else if (_service.hasActiveSession)
              _buildActiveSessionView(theme, l10n)
            else if (_showSetup)
              _buildSetupView(theme, l10n)
            else
              _buildSetupView(theme, l10n),
            const SizedBox(height: 24),
            SessionSummaryCard(
              todayStats: _todayStats,
              weeklyMs: _weeklyMs,
              recentSessions: _recentSessions,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBreakView(ThemeData theme, ColorScheme cs, AppLocalizations l10n) {
    return Semantics(
      liveRegion: true,
      label: l10n.breakRemainingLabel(formatTimer(Duration(seconds: _breakRemaining), l10n: l10n)),
      child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          children: [
            Icon(Icons.self_improvement, size: ResponsiveUtils.emptyStateIconSize(context), color: cs.tertiary),
            const SizedBox(height: 16),
            Text(
              l10n.breakTime,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.tertiary,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatTimer(Duration(seconds: _breakRemaining), l10n: l10n),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sessionCompleted(_completedSession!.actualDurationMs ~/ 60000),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildActiveSessionView(ThemeData theme, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          children: [
            FocusTimerWidget(
              plannedDurationMinutes: _service.currentSession!.plannedDurationMinutes ?? 25,
              elapsedSeconds: _service.elapsedSeconds,
              isPaused: _service.isPaused,
              isActive: true,
              reduceMotion: ref.watch(settingsProvider).reduceMotion,
              onPause: () => setState(() => _service.pauseSession()),
              onResume: () => setState(() => _service.resumeSession()),
              onComplete: () async {
                await _service.completeSession();
              },
              onCancel: () async {
                await _service.cancelSession();
                setState(() => _showSetup = true);
                _loadStats();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView(ThemeData theme, AppLocalizations l10n) {
    final presets = [10, 15, 25, 30, 45, 60];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.newFocusSession,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_showFirstVisitHelp) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.focusFirstVisitHelp,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildSubjectPicker(),
            const SizedBox(height: 16),
            Text(
              l10n.duration,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FocusTraversalGroup(
              child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((m) {
                final selected = _selectedMinutes == m;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: l10n.minutesSemantics(m),
                  child: ChoiceChip(
                    label: Text(l10n.durationMinutes(m)),
                    selected: selected,
                    onSelected: (v) => setState(() => _selectedMinutes = m),
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                  ),
                );
              }).toList(),
            ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _selectedMinutes.toDouble(),
              min: 1,
              max: 180,
              divisions: 179,
              label: l10n.minutesValue(_selectedMinutes),
              onChanged: (v) => setState(() => _selectedMinutes = v.round()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _startFocus,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  l10n.focusForMinutes(_selectedMinutes),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPicker() {
    final l10n = AppLocalizations.of(context)!;
    final subjectsAsync = ref.watch(subjectsRepositoryProvider);
    return subjectsAsync.when(
      data: (repo) {
        return FutureBuilder<List<Subject>>(
          future: repo.getAll().then((r) => r.data ?? []),
          builder: (context, snapshot) {
            final subjects = snapshot.data ?? [];
            if (subjects.isEmpty) {
              return Semantics(
                label: l10n.addSubjectsForFocusHint,
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.addSubjectsForFocusHint,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
                          child: Text(l10n.settings),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return DropdownButtonFormField<String>(
              initialValue: _selectedSubjectId.isEmpty ? null : _selectedSubjectId,
              decoration: InputDecoration(
                labelText: l10n.selectSubjectLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(l10n.subjectOptional),
                ),
                ...subjects.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                )),
              ],
              onChanged: (v) => setState(() => _selectedSubjectId = v ?? ''),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
