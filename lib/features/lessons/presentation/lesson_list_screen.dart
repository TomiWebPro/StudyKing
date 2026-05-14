import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/data/models/lesson_model.dart';
import '../../../core/data/models/tutor_session_model.dart';
import '../../../core/data/repositories/lesson_repository.dart';
import '../../../core/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/providers/app_providers.dart' show database;
import 'package:studyking/core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/services/student_id_service.dart';
import 'package:studyking/core/utils/responsive.dart';

enum LessonStatus { notStarted, inProgress, completed }

class LessonListScreen extends StatefulWidget {
  final LessonListArgs args;
  final LessonRepository? lessonRepository;
  final TutorSessionRepository? tutorSessionRepository;

  const LessonListScreen({
    super.key,
    required this.args,
    this.lessonRepository,
    this.tutorSessionRepository,
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  List<Lesson> _lessons = [];
  final Map<String, LessonStatus> _statusCache = {};
  bool _isLoading = true;
  StreamSubscription? _tutorSessionSubscription;

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _loadTutorSessionStatuses();
  }

  LessonRepository get _lessonRepo =>
      widget.lessonRepository ?? database.lessonRepository;
  TutorSessionRepository get _tutorSessionRepo =>
      widget.tutorSessionRepository ?? database.tutorSessionRepository;

  Future<void> _loadLessons() async {
    try {
      final all = await _lessonRepo.getAll();
      setState(() {
        _lessons = all.where((l) => l.topicId == widget.args.topicId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTutorSessionStatuses() async {
    try {
      final sessions = await _tutorSessionRepo
          .getStudentSessions(StudentIdService().getStudentId());
      for (final session in sessions) {
        final lessonId = session.topicId;
        if (session.status == SessionStatus.completed) {
          _statusCache[lessonId] = LessonStatus.completed;
        } else if (session.status == SessionStatus.inProgress) {
          _statusCache[lessonId] = LessonStatus.inProgress;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _tutorSessionSubscription?.cancel();
    super.dispose();
  }

  void _openTutorMode() {
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: widget.args.topicId,
        topicTitle: widget.args.topicTitle,
        subjectId: widget.args.subjectId,
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noLessonsUsePlanner,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: Semantics(
                    button: true,
                    label: l10n.startAiTutoring,
                    child: ElevatedButton.icon(
                      onPressed: _openTutorMode,
                      icon: const Icon(Icons.smart_toy),
                      label: Text(l10n.startAiTutoring),
                    ),
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
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: Semantics(
              button: true,
              label: l10n.startAiTutoring,
              child: IconButton(
                icon: const Icon(Icons.smart_toy_outlined),
                tooltip: l10n.startAiTutoring,
                onPressed: _openTutorMode,
              ),
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
            return FocusTraversalOrder(
              order: NumericFocusOrder((index + 2).toDouble()),
              child: Semantics(
                label: l.title,
                child: Card(
                margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
                child: ListTile(
                  leading: _buildStatusIcon(status),
                  title: Text(l.title),
                  subtitle: Row(
                    children: [
                      Text(l10n.blocksCount(l.blocks.length)),
                      if (status != null) ...[
                        const SizedBox(width: 8),
                        _buildStatusChip(context, status, l10n),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.play_arrow),
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
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIcon(LessonStatus? status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case LessonStatus.completed:
        return Icon(Icons.check_circle, color: cs.primary);
      case LessonStatus.inProgress:
        return Icon(Icons.play_circle_filled, color: cs.tertiary);
      case LessonStatus.notStarted:
      case null:
        return const Icon(Icons.book);
    }
  }

  Widget _buildStatusChip(BuildContext context, LessonStatus status, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      LessonStatus.completed => (l10n.completed, cs.primary),
      LessonStatus.inProgress => (l10n.inProgress, cs.tertiary),
      LessonStatus.notStarted => (l10n.notStarted, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
