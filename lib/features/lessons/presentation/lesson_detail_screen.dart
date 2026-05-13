import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/data/models/lesson_model.dart';
import '../../../core/data/enums.dart';
import '../../../../main.dart' show database;
import '../../../l10n/generated/app_localizations.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;
  final String topicId;
  final String topicTitle;
  
  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  Lesson? _lesson;
  final Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await database.lessonRepository.get(widget.lessonId);
      if (mounted && lesson != null) setState(() => _lesson = lesson);
    } catch (e) {
      debugPrint('Error loading lesson: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lesson.blocks.length,
        itemBuilder: (context, i) {
          final b = lesson.blocks[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(_getBlockIcon(b.type)),
                  title: Text(_getBlockTitle(b.type, l10n)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(b.content),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('${_elapsed.inMinutes}:${_elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}'),
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
