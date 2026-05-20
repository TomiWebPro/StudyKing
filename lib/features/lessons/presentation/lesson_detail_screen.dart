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
  Lesson? _lesson;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Timeouts.second, (_) {
      if (mounted) {
        setState(() => _elapsed = _elapsed + Timeouts.second);
      }
    });
  }

  Future<void> _retryLoadLesson() => _loadLesson();

  Future<void> _loadLesson() async {
    try {
      final repo = ref.read(lessonRepositoryProvider);
      final lessonResult = await repo.get(widget.args.lessonId);
      if (mounted) {
        setState(() {
          _lesson = lessonResult.data;
          _loadError = false;
        });
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
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: widget.args.topicId,
        topicTitle: widget.args.topicTitle,
        subjectId: (widget.args.subjectId ?? '').isNotEmpty
            ? (widget.args.subjectId ?? '')
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
      return const Scaffold(
        body: LoadingIndicator(),
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
          itemCount: lesson.blocks.length,
          itemBuilder: (context, i) {
            return Semantics(
              label: lesson.blocks[i].content,
              child: LessonBlockCard(block: lesson.blocks[i]),
            );
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
