import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/data/models/lesson_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/responsive.dart';
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = _elapsed + const Duration(seconds: 1));
      }
    });
  }

  Future<void> _retryLoadLesson() => _loadLesson();

  Future<void> _loadLesson() async {
    try {
      final repo = ref.read(lessonRepositoryProvider);
      final lesson = await repo.get(widget.args.lessonId);
      if (mounted) {
        setState(() {
          _lesson = lesson;
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loadError) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_lesson == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final lesson = _lesson!;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        actions: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: Semantics(
              button: true,
              label: l10n.teachingMode,
              child: IconButton(
                icon: const Icon(Icons.smart_toy_outlined),
                tooltip: l10n.teachingMode,
                onPressed: _openTutorMode,
              ),
            ),
          ),
        ],
      ),
      body: FocusTraversalGroup(
        child: ListView.builder(
          padding: ResponsiveUtils.listPadding(context),
          itemCount: lesson.blocks.length,
          itemBuilder: (context, i) {
            return FocusTraversalOrder(
              order: NumericFocusOrder(i.toDouble() + 1),
              child: Semantics(
                label: lesson.blocks[i].content,
                child: LessonBlockCard(block: lesson.blocks[i]),
              ),
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
                  '${_elapsed.inMinutes}:${_elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                ),
                const Spacer(),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: Semantics(
                    button: true,
                    label: l10n.teachingMode,
                    child: ElevatedButton.icon(
                      onPressed: _openTutorMode,
                      icon: const Icon(Icons.smart_toy, size: 18),
                      label: Text(l10n.teachingMode),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
