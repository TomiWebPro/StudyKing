import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/data/models/lesson_model.dart';
import '../../../core/data/models/tutor_session_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show database;
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/services/student_id_service.dart';
import 'lesson_detail_screen.dart';
import '../../teaching/presentation/tutor_screen.dart';
import 'package:studyking/core/utils/responsive.dart';

enum LessonStatus { notStarted, inProgress, completed }

class LessonListScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final String subjectId;

  const LessonListScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    this.subjectId = '',
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

  Future<void> _loadLessons() async {
    try {
      final all = await database.lessonRepository.getAll();
      setState(() {
        _lessons = all.where((l) => l.topicId == widget.topicId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTutorSessionStatuses() async {
    try {
      final sessions = await database.tutorSessionRepository
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TutorScreen(
          topicId: widget.topicId,
          topicTitle: widget.topicTitle,
          subjectId: widget.subjectId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_lessons.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicTitle)),
        body: Center(
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
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle),
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
      body: ListView.builder(
        padding: ResponsiveUtils.listPadding(context),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final l = _lessons[index];
          final status = _statusCache[l.id];
          return Semantics(
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
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LessonDetailScreen(
                  lessonId: l.id,
                  topicId: widget.topicId,
                  topicTitle: widget.topicTitle,
                  subjectId: widget.subjectId,
                ),
              )),
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(LessonStatus? status) {
    switch (status) {
      case LessonStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case LessonStatus.inProgress:
        return const Icon(Icons.play_circle_filled, color: Colors.orange);
      case LessonStatus.notStarted:
      case null:
        return const Icon(Icons.book);
    }
  }

  Widget _buildStatusChip(BuildContext context, LessonStatus status, AppLocalizations l10n) {
    final (label, color) = switch (status) {
      LessonStatus.completed => (l10n.completed, Colors.green),
      LessonStatus.inProgress => (l10n.inProgress, Colors.orange),
      LessonStatus.notStarted => (l10n.notStarted, Colors.grey),
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
