import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/errors/handlers.dart';
import '../../lessons/providers/lesson_providers.dart';
import '../../teaching/providers/teaching_providers.dart';
import '../../teaching/data/models/lesson_recap_model.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/utils/logger.dart';
import 'widgets/lesson_block_card.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  final LessonDetailArgs args;

  const LessonDetailScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() =>
      _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  static final Logger _logger = const Logger('LessonDetailScreen');
  Lesson? _lesson;
  LessonRecapModel? _recap;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  void _startTimer() {
    _timer = Timer.periodic(Timeouts.second, (_) {
      if (mounted) {
        setState(() => _elapsed = _elapsed + Timeouts.second);
      }
    });
  }

  Future<void> _retryLoadLesson() => _loadLesson();

  Future<void> _loadRecap(String? lessonId) async {
    if (lessonId == null) return;
    try {
      final service = ref.read(lessonRecapServiceProvider);
      final result = await service.getRecapForLesson(lessonId);
      if (mounted && result.isSuccess && result.data != null) {
        setState(() => _recap = result.data);
      }
    } catch (e) {
      _logger.w('Failed to load lesson recap', e);
    }
  }

  Future<void> _loadLesson() async {
    try {
      final repo = ref.read(lessonRepositoryProvider);
      final lessonResult = await repo.get(widget.args.lessonId);
      if (mounted) {
        setState(() {
          _lesson = lessonResult.data;
          _recap = null;
          _loadError = false;
        });
        _loadRecap(lessonResult.data?.id);
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = true);
        AppErrorHandler.handleError(
          context,
          e,
          'Lesson Detail Load',
          retry: true,
          retryCallback: _retryLoadLesson,
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const int _defaultDurationMinutes = Timeouts.defaultLessonDurationMinutes;

  void _openTutorMode() {
    if (!mounted) return;
    final argsSubjectId = widget.args.subjectId ?? '';
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: widget.args.topicId,
        topicTitle: widget.args.topicTitle,
        subjectId: argsSubjectId.isNotEmpty
            ? argsSubjectId
            : _lesson?.subjectId ?? '',
        durationMinutes: _defaultDurationMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loadError) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.args.topicTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.failedToLoadLesson,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.arrow_forward : Icons.arrow_back),
                      label: Text(l10n.goBack),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _retryLoadLesson,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_lesson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.args.topicTitle)),
        body: const LoadingIndicator(),
      );
    }
    final lesson = _lesson!;

    if (lesson.blocks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(lesson.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(l10n.generating, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                l10n.inProgress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadLesson,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: _elapsed == Duration.zero,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final l10n = AppLocalizations.of(context)!;
        final navigator = Navigator.of(context);
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.activeLessonTimer),
            content: Text(l10n.leaveAnyway),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.leaveAnyway),
              ),
            ],
          ),
        );
        if (shouldPop == true && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        actions: [
          Semantics(
            button: true,
            label: l10n.aiTutor,
            child: IconButton(
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: l10n.aiTutor,
              onPressed: _openTutorMode,
            ),
          ),
        ],
      ),
      body: FocusTraversalGroup(
        child: ListView.builder(
          padding: ResponsiveUtils.listPadding(context),
          itemCount: lesson.blocks.length + (_recap != null ? 1 : 0),
          itemBuilder: (context, i) {
            if (i < lesson.blocks.length) {
              return Semantics(
                label: lesson.blocks[i].content,
                child: LessonBlockCard(block: lesson.blocks[i]),
              );
            }
            return _LessonRecapCard(recap: _recap!);
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: FocusTraversalGroup(
          child: Padding(
            padding: ResponsiveUtils.screenPadding(context),
            child: Row(
              children: [
                Text(
                  formatTimer(_elapsed, l10n: l10n),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: l10n.aiTutor,
                  child: FilledButton.icon(
                    onPressed: _openTutorMode,
                    icon: const Icon(Icons.smart_toy, size: 18),
                    label: Text(l10n.aiTutor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _LessonRecapCard extends StatelessWidget {
  final LessonRecapModel recap;

  const _LessonRecapCard({required this.recap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = l10n.localeName;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.lessonRecapTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RecapMetric(
                  label: l10n.recapAccuracy,
                  value: formatPercent(recap.accuracyPercent, localeName),
                ),
                _RecapMetric(
                  label: l10n.recapParticipation,
                  value: recap.participationMessages.toString(),
                ),
                _RecapMetric(
                  label: l10n.recapConfidence,
                  value: formatDecimal(
                    recap.confidenceRating / 5.0,
                    localeName,
                    minFractionDigits: 1,
                    maxFractionDigits: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recap.summary.isNotEmpty) ...[
              Text(l10n.recapSummary,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(recap.summary, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            if (recap.topicsCovered.isNotEmpty) ...[
              _RecapList(label: l10n.recapTopicsCovered, items: recap.topicsCovered),
              const SizedBox(height: 12),
            ],
            if (recap.struggles.isNotEmpty) ...[
              _RecapList(label: l10n.recapStruggles, items: recap.struggles),
              const SizedBox(height: 12),
            ],
            if (recap.homework.isNotEmpty) ...[
              _RecapList(label: l10n.recapHomework, items: recap.homework),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecapMetric extends StatelessWidget {
  final String label;
  final String value;

  const _RecapMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _RecapList extends StatelessWidget {
  final String label;
  final List<String> items;

  const _RecapList({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
