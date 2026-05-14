import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';

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

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with TickerProviderStateMixin {
  final FocusSessionService _service = FocusSessionService(
    repository: FocusSessionRepository(),
  );

  FocusSessionRepository get _repo => _service.repository;

  bool _initialized = false;
  bool _showSetup = true;
  int _selectedMinutes = 25;
  FocusSession? _completedSession;
  bool _inBreak = false;
  int _breakRemaining = 0;
  final int _breakDuration = 300;
  late AnimationController _breakController;

  Map<String, dynamic>? _todayStats;
  int _weeklySeconds = 0;
  List<FocusSession> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _breakController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _init();
  }

  Future<void> _init() async {
    try {
      await _repo.init();
      _service.addOnSessionComplete(_onSessionComplete);
      _service.addOnTick(_onTick);
      await _loadStats();
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  void _onSessionComplete(FocusSession session) {
    if (!mounted) return;
    setState(() {
      _completedSession = session;
      _showSetup = false;
      _inBreak = true;
      _breakRemaining = _breakDuration;
      _startBreakTimer();
    });
    _loadStats();
  }

  void _onTick(int elapsed) {
    if (mounted) setState(() {});
  }

  void _startBreakTimer() {
    _breakController.repeat(
      period: const Duration(seconds: 1),
    );
    _breakController.addListener(() {
      if (!mounted) return;
      setState(() {
        _breakRemaining--;
      });
      if (_breakRemaining <= 0) {
        _breakController.stop();
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
      final weekly = await _service.getWeeklyFocusSeconds();
      final recent = await _service.getRecentSessions();
      if (mounted) {
        setState(() {
          _todayStats = stats;
          _weeklySeconds = weekly;
          _recentSessions = recent;
        });
      }
    } catch (_) {}
  }

  Future<void> _startFocus() async {
    try {
      final capReached = await _service.isDailyCapReached(_selectedMinutes);
      if (capReached) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.celebration, size: 48, color: Colors.green),
              title: const Text('Daily Limit Reached'),
              content: const Text(
                'You\'ve reached your daily study limit — well done! '
                'Take a rest and come back tomorrow.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      await _service.startSession(
        plannedDurationMinutes: _selectedMinutes,
        subjectId: widget.preselectedSubjectId,
        topicId: widget.preselectedTopicId,
      );
      if (mounted) {
        setState(() => _showSetup = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting session: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _breakController.dispose();
    _service.removeOnSessionComplete(_onSessionComplete);
    _service.removeOnTick(_onTick);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bp = ResponsiveUtils.breakpointOf(context);

    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Focus Mode')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          children: [
            if (_inBreak && _completedSession != null)
              _buildBreakView(theme)
            else if (_service.hasActiveSession)
              _buildActiveSessionView(theme)
            else if (_showSetup)
              _buildSetupView(theme, bp)
            else
              _buildSetupView(theme, bp),
            const SizedBox(height: 24),
            SessionSummaryCard(
              todayStats: _todayStats,
              weeklySeconds: _weeklySeconds,
              recentSessions: _recentSessions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakView(ThemeData theme) {
    final m = _breakRemaining ~/ 60;
    final s = _breakRemaining % 60;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.self_improvement, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Break Time!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session completed: ${_completedSession!.actualDurationSeconds ~/ 60}m',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionView(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FocusTimerWidget(
              plannedDurationMinutes: _service.currentSession!.plannedDurationMinutes,
              elapsedSeconds: _service.elapsedSeconds,
              isPaused: _service.isPaused,
              isActive: true,
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

  Widget _buildSetupView(ThemeData theme, ScreenBreakpoint bp) {
    final presets = [5, 15, 25, 30, 45, 60];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'New Focus Session',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Duration',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((m) {
                final selected = _selectedMinutes == m;
                return ChoiceChip(
                  label: Text('${m}min'),
                  selected: selected,
                  onSelected: (v) => setState(() => _selectedMinutes = m),
                );
              }).toList(),
            ),
            if (bp.isTablet) ...[
              const SizedBox(height: 8),
              Slider(
                value: _selectedMinutes.toDouble(),
                min: 1,
                max: 180,
                divisions: 179,
                label: '$_selectedMinutes min',
                onChanged: (v) => setState(() => _selectedMinutes = v.round()),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _startFocus,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  'Focus for $_selectedMinutes minutes',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
