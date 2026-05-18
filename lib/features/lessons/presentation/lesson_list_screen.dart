import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import '../../../core/data/models/session_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/services/student_id_service.dart' show studentIdValueProvider;
import '../../../core/utils/logger.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/errors/handlers.dart';
import '../../lessons/providers/lesson_providers.dart';
import 'widgets/lesson_list_item.dart';

class LessonListScreen extends ConsumerStatefulWidget {
  final LessonListArgs args;

  const LessonListScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends ConsumerState<LessonListScreen> {
  final _logger = const Logger('LessonListScreen');
  List<Lesson> _lessons = [];
  final Map<String, LessonStatusDisplay> _statusCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _loadTutorSessionStatuses();
  }

  Future<void> _loadLessons() async {
    try {
      final repo = ref.read(lessonRepositoryProvider);
      final allResult = await repo.getAll();
      final all = allResult.data ?? [];
      if (!mounted) return;
      setState(() {
        _lessons =
            all.where((l) => l.topicId == widget.args.topicId).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppErrorHandler.handleError(
          context,
          e,
          'Lesson Load',
          retry: true,
          retryCallback: _retryLoadLessons,
        );
      }
    }
  }

  Future<void> _retryLoadLessons() => _loadLessons();

  Future<void> _loadTutorSessionStatuses() async {
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final studentId = ref.read(studentIdValueProvider);
      final result = await repo.getByStudent(studentId);
      final sessions = result.data ?? [];
      for (final session in sessions) {
        final lessonId = session.topicId ?? '';
        if (session.completed) {
          _statusCache[lessonId] = LessonStatusDisplay.completed;
        } else if (session.type == SessionType.tutoring && !session.completed && session.endTime == null) {
          _statusCache[lessonId] = LessonStatusDisplay.inProgress;
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      _logger.w('Failed to load tutor session statuses', e);
    }
  }

  static const int _defaultDurationMinutes = 45;

  void _openTutorMode() {
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: widget.args.topicId,
        topicTitle: widget.args.topicTitle,
        subjectId: widget.args.subjectId,
        durationMinutes: _defaultDurationMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_lessons.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.args.topicTitle)),
        body: Center(
          child: FocusTraversalGroup(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noLessonsUsePlanner,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  label: l10n.startAiTutoring,
                  child: ElevatedButton.icon(
                    onPressed: _openTutorMode,
                    icon: const Icon(Icons.smart_toy),
                    label: Text(l10n.startAiTutoring),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.topicTitle),
        actions: [
          Semantics(
            button: true,
            label: l10n.startAiTutoring,
            child: IconButton(
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: l10n.startAiTutoring,
              onPressed: _openTutorMode,
            ),
          ),
        ],
      ),
      body: FocusTraversalGroup(
        child: ListView.builder(
          padding: ResponsiveUtils.listPadding(context),
          itemCount: _lessons.length,
          itemBuilder: (context, index) {
            final l = _lessons[index];
            final status = _statusCache[l.id];
            return Semantics(
              label: l.title,
              child: LessonListItem(
                lesson: l,
                topicTitle: widget.args.topicTitle,
                subjectId: widget.args.subjectId,
                topicId: widget.args.topicId,
                status: status,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.lessonDetail,
                  arguments: LessonDetailArgs(
                    lessonId: l.id,
                    topicId: widget.args.topicId,
                    topicTitle: widget.args.topicTitle,
                    subjectId: widget.args.subjectId,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
