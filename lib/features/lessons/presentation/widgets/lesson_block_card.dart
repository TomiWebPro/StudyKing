import 'package:flutter/material.dart';
import '../../../../core/data/enums.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import '../../../../l10n/generated/app_localizations.dart';

class LessonBlockCard extends StatelessWidget {
  final LessonBlock block;

  const LessonBlockCard({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardMargin = Theme.of(context).cardTheme.margin;
    final resolvedMargin = cardMargin?.resolve(Directionality.of(context));
    return Card(
      margin: EdgeInsets.only(
        bottom: resolvedMargin?.bottom ?? 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(_iconForType(block.type)),
            title: Text(_titleForType(block.type, l10n)),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(block.content),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(LessonBlockType type) {
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

  String _titleForType(LessonBlockType type, AppLocalizations l10n) {
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
