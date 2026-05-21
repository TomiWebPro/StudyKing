import '../conversation_phase.dart';
import 'package:flutter/material.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

import 'package:studyking/core/constants/llm_defaults.dart' show evaluationPromptTemplate;

class PromptEntry {
  final String systemPrompt;
  final String userPrompt;

  const PromptEntry({
    required this.systemPrompt,
    required this.userPrompt,
  });
}

class ConversationPromptSet {
  static final Logger _logger = const Logger('ConversationPromptSet');

  final int version;
  final String localeName;

  const ConversationPromptSet({this.version = 1, required this.localeName});

  static const ConversationPromptSet defaultTemplates = ConversationPromptSet(localeName: 'en');

  String _languageInstruction(AppLocalizations l10n) {
    try {
      final instruction = l10n.languageInstruction(localeName);
      return '\n$instruction';
    } catch (e) {
      _logger.w('Failed to get language instruction for locale $localeName', e);
      return '';
    }
  }

  PromptEntry lessonPlan({
    required String subjectId,
    required String topicTitle,
    required int durationMinutes,
  }) {
    final l10n = lookupAppLocalizations(Locale(localeName));
    return PromptEntry(
      systemPrompt: '${l10n.lessonPlanSystemPrompt}${_languageInstruction(l10n)}',
      userPrompt: l10n.lessonPlanUserPrompt(subjectId, topicTitle, durationMinutes),
    );
  }

  PromptEntry tutorMessage({
    required String subjectId,
    required String topicTitle,
    required double adaptivePace,
    required ConversationPhase phase,
    String? scheduledSessionId,
  }) {
    final l10n = lookupAppLocalizations(Locale(localeName));
    final paceContext = switch (adaptivePace) {
      > 1.2 => l10n.acceleratePace,
      < 0.8 => l10n.slowDownPace,
      _ => l10n.maintainPace,
    };
    final timeContext = switch (phase) {
      ConversationPhase.greeting => l10n.greetingContext,
      ConversationPhase.teaching => l10n.teachingContext,
      ConversationPhase.exercise => l10n.exerciseContext,
      ConversationPhase.feedback => l10n.feedbackContext,
      ConversationPhase.adaptiveReview => l10n.adaptiveReviewContext,
      ConversationPhase.closing => l10n.closingContext,
    };
    var systemPrompt = '${l10n.tutorSystemPrompt(subjectId, topicTitle)}${_languageInstruction(l10n)}';
    if (scheduledSessionId != null) {
      systemPrompt = '$systemPrompt\n\n${l10n.scheduledLessonSystemContext}';
    }
    final userPrompt = l10n.tutorInstructionPrompt(timeContext, paceContext);
    return PromptEntry(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  PromptEntry summary({
    required String topicTitle,
    required int exerciseCount,
    required int correctCount,
    required double confidenceRating,
    required double adaptivePace,
  }) {
    final l10n = lookupAppLocalizations(Locale(localeName));
    return PromptEntry(
      systemPrompt: '${l10n.summarySystemPrompt}${_languageInstruction(l10n)}',
      userPrompt: l10n.summaryUserPrompt(
        topicTitle, 
        exerciseCount, 
        correctCount,
        (confidenceRating * 100).round(),
        adaptivePace.toStringAsFixed(1), // LLM-facing: invariant period format OK
      ),
    );
  }

  PromptEntry evaluateExercise({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
  }) {
    final l10n = lookupAppLocalizations(Locale(localeName));
    final userPrompt = evaluationPromptTemplate(
      l10n: l10n,
      subjectId: subjectId,
      topicTitle: topicTitle,
      question: question,
      studentAnswer: studentAnswer,
    );
    return PromptEntry(
      systemPrompt: '${l10n.evaluationSystemPrompt}${_languageInstruction(l10n)}',
      userPrompt: userPrompt,
    );
  }
}



