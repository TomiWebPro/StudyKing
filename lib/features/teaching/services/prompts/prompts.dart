import '../conversation_phase.dart';
import 'package:flutter/material.dart';
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
  final int version;
  final String localeName;

  const ConversationPromptSet({this.version = 1, this.localeName = 'en'});

  static const ConversationPromptSet defaultTemplates = ConversationPromptSet();

  String get _languageInstruction {
    if (localeName == 'en') return '';
    return '\nIMPORTANT: Respond in the same language as the student (locale: $localeName). Do not use English unless the student does.';
  }

  PromptEntry lessonPlan({
    required String subjectId,
    required String topicTitle,
    required int durationMinutes,
  }) {
    final l10n = lookupAppLocalizations(Locale(localeName));
    return PromptEntry(
      systemPrompt: '${l10n.lessonPlanSystemPrompt}$_languageInstruction',
      userPrompt: l10n.lessonPlanUserPrompt(subjectId, topicTitle, durationMinutes),
    );
  }

  PromptEntry tutorMessage({
    required String subjectId,
    required String topicTitle,
    required double adaptivePace,
    required ConversationPhase phase,
  }) {
    final l10n = lookupAppLocalizations(Locale(localeName));
    // LLM-facing: invariant English format OK per AGENTS.md
    final paceContext = switch (adaptivePace) {
      > 1.2 => 'The student is doing well. Accelerate pace.',
      < 0.8 => 'The student seems to be struggling. Slow down, simplify explanations, and provide more examples.',
      _ => 'Maintain a steady teaching pace.',
    };
    // LLM-facing: invariant English format OK per AGENTS.md
    final timeContext = switch (phase) {
      ConversationPhase.greeting => 'Start the lesson warmly.',
      ConversationPhase.teaching => 'Teach the concept step by step. Engage the student with questions.',
      ConversationPhase.exercise => 'Give the student a practice question to assess understanding.',
      ConversationPhase.feedback => 'Provide constructive feedback on their answer.',
      ConversationPhase.adaptiveReview => 'The student needs extra help. Re-explain the concept more simply. Use different examples.',
      ConversationPhase.closing => 'Wrap up the lesson. Summarize key points.',
    };
    final systemPrompt = '${l10n.tutorSystemPrompt(subjectId, topicTitle)}$_languageInstruction';
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
      systemPrompt: '${l10n.summarySystemPrompt}$_languageInstruction',
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
    // User prompt kept as Dart constant (invariant format with JSON templates)
    final userPrompt = evaluationPromptTemplate(
      subjectId: subjectId,
      topicTitle: topicTitle,
      question: question,
      studentAnswer: studentAnswer,
    );
    return PromptEntry(
      systemPrompt: '${l10n.evaluationSystemPrompt}$_languageInstruction',
      userPrompt: userPrompt,
    );
  }
}



/// English default system prompt for lesson planning.
String get lessonPlanSystemPrompt =>
    lookupAppLocalizations(const Locale('en')).lessonPlanSystemPrompt;

/// English default system prompt for summaries.
String get summarySystemPrompt =>
    lookupAppLocalizations(const Locale('en')).summarySystemPrompt;

/// English default system prompt for evaluation.
String get evaluationSystemPrompt =>
    lookupAppLocalizations(const Locale('en')).evaluationSystemPrompt;

/// Backward-compatible alias for existing references.
typedef PromptTemplates = ConversationPromptSet;
