import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/data/models/lesson_model.dart';
import '../../../core/data/enums.dart';
import '../../../core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/providers/app_providers.dart' show database;
import 'package:studyking/core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final LessonRepository? lessonRepository;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicTitle,
    this.subjectId = '',
    this.lessonRepository,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final Logger _logger = const Logger('LessonDetailScreen');
  Lesson? _lesson;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _startTimer();
  }

  LessonRepository get _lessonRepo =>
      widget.lessonRepository ?? database.lessonRepository;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = _elapsed + const Duration(seconds: 1));
      }
    });
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await _lessonRepo.get(widget.lessonId);
      if (mounted && lesson != null) setState(() => _lesson = lesson);
    } catch (e) {
      _logger.e('Error loading lesson', e);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openTutorMode() {
    Navigator.pushNamed(
      context,
      AppRoutes.tutor,
      arguments: TutorArgs(
        topicId: widget.topicId,
        topicTitle: widget.topicTitle,
        subjectId: widget.subjectId.isNotEmpty
            ? widget.subjectId
            : _lesson?.subjectId ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Semantics(
            button: true,
            label: l10n.teachingMode,
            child: IconButton(
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: l10n.teachingMode,
              onPressed: _openTutorMode,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: ResponsiveUtils.listPadding(context),
        itemCount: lesson.blocks.length,
        itemBuilder: (context, i) {
          final b = lesson.blocks[i];
          return Semantics(
            label: _getBlockTitle(b.type, l10n),
            child: Card(
            margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(_getBlockIcon(b.type)),
                  title: Text(_getBlockTitle(b.type, l10n)),
                ),
                Padding(
                  padding: ResponsiveUtils.cardPadding(context),
                  child: Text(b.content),
                ),
              ],
            ),
          ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: ResponsiveUtils.screenPadding(context),
          child: Row(
            children: [
              Text('${_elapsed.inMinutes}:${_elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}'),
              const Spacer(),
              Semantics(
                button: true,
                label: l10n.teachingMode,
                child: ElevatedButton.icon(
                  onPressed: _openTutorMode,
                  icon: const Icon(Icons.smart_toy, size: 18),
                  label: Text(l10n.teachingMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBlockIcon(LessonBlockType type) {
    switch (type) {
      case LessonBlockType.text:
        return Icons.description;
      case LessonBlockType.example:
        return Icons.play_circle;
      case LessonBlockType.exercise:
        return Icons.note_add;
      case LessonBlockType.slide:
        return Icons.slideshow;
      case LessonBlockType.quiz:
        return Icons.question_answer;
      case LessonBlockType.summary:
        return Icons.check_circle;
    }
  }

  String _getBlockTitle(LessonBlockType type, AppLocalizations l10n) {
    switch (type) {
      case LessonBlockType.text:
        return l10n.blockTypeExplanation;
      case LessonBlockType.example:
        return l10n.blockTypeExample;
      case LessonBlockType.exercise:
        return l10n.blockTypeExercise;
      case LessonBlockType.slide:
        return l10n.blockTypeSlide;
      case LessonBlockType.quiz:
        return l10n.blockTypeQuiz;
      case LessonBlockType.summary:
        return l10n.blockTypeSummary;
    }
  }
}
