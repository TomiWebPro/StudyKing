import '../conversation_phase.dart';

class PromptTemplates {
  final String Function({
    required String subjectId,
    required String topicTitle,
    required int durationMinutes,
  }) buildLessonPlanPrompt;

  final String Function({
    required String subjectId,
    required String topicTitle,
    required double adaptivePace,
    required ConversationPhase phase,
  }) buildTutorPrompt;

  final String Function({
    required String topicTitle,
    required int exerciseCount,
    required int correctCount,
    required double confidenceRating,
    required double adaptivePace,
  }) buildSummaryPrompt;

  final String lessonPlanSystemPrompt;
  final String summarySystemPrompt;

  const PromptTemplates({
    required this.buildLessonPlanPrompt,
    required this.buildTutorPrompt,
    required this.buildSummaryPrompt,
    required this.lessonPlanSystemPrompt,
    required this.summarySystemPrompt,
  });

  static const PromptTemplates defaultTemplates = PromptTemplates(
    buildLessonPlanPrompt: _defaultLessonPlanPrompt,
    buildTutorPrompt: _defaultTutorPrompt,
    buildSummaryPrompt: _defaultSummaryPrompt,
    lessonPlanSystemPrompt: _defaultLessonPlanSystemPrompt,
    summarySystemPrompt: _defaultSummarySystemPrompt,
  );
}

String _defaultLessonPlanPrompt({
  required String subjectId,
  required String topicTitle,
  required int durationMinutes,
}) {
  return '''
You are a knowledgeable AI tutor for $subjectId. Create a structured lesson plan for the topic "$topicTitle".

The lesson should be $durationMinutes minutes long.

Return a JSON object with:
{
  "goals": ["goal1", "goal2", "goal3"],
  "sections": [
    {"title": "section title", "duration": 10, "type": "explanation|exercise|review"},
    ...
  ],
  "checkpoints": ["checkpoint1", "checkpoint2"],
  "estimatedDifficulty": 1-5
}
''';
}

const String _defaultLessonPlanSystemPrompt =
    'You are a curriculum designer creating lesson plans. Respond only with valid JSON.';

String _defaultTutorPrompt({
  required String subjectId,
  required String topicTitle,
  required double adaptivePace,
  required ConversationPhase phase,
}) {
  final paceContext = switch (adaptivePace) {
    > 1.2 => 'The student is doing well. Accelerate pace.',
    < 0.8 => 'The student seems to be struggling. Slow down, simplify explanations, and provide more examples.',
    _ => 'Maintain a steady teaching pace.',
  };

  final timeContext = switch (phase) {
    ConversationPhase.greeting => 'Start the lesson warmly.',
    ConversationPhase.teaching => 'Teach the concept step by step. Engage the student with questions.',
    ConversationPhase.exercise => 'Give the student a practice question to assess understanding.',
    ConversationPhase.feedback => 'Provide constructive feedback on their answer.',
    ConversationPhase.adaptiveReview => 'The student needs extra help. Re-explain the concept more simply. Use different examples.',
    ConversationPhase.closing => 'Wrap up the lesson. Summarize key points.',
  };

  return '''
You are an AI tutor for $subjectId teaching "$topicTitle".

Guidelines:
- $timeContext
- $paceContext
- Explain concepts step by step
- Adapt to the student's level
- Encourage the student always
- If they answer correctly, accelerate; if struggling, simplify
- Keep track of the lesson hour - be mindful of time
- Ask questions to check understanding
- Never give away answers directly - guide the student
- Insert inline exercises naturally into the conversation
- Celebrate correct answers with specific praise
- For wrong answers, explain why and guide toward the correct reasoning

Be conversational, warm, and educational.
''';
}

String _defaultSummaryPrompt({
  required String topicTitle,
  required int exerciseCount,
  required int correctCount,
  required double confidenceRating,
  required double adaptivePace,
}) {
  return '''
Summarize what was covered in this lesson about "$topicTitle".
Include:
1. Key concepts explained
2. Questions answered ($exerciseCount exercises, $correctCount correct)
3. Student's apparent understanding level (confidence: ${(confidenceRating * 100).round()}%)
4. Adaptive pace used (${adaptivePace.toStringAsFixed(1)}x)
5. Recommendations for next lesson

Keep it concise and constructive.
''';
}

const String _defaultSummarySystemPrompt = 'You are a tutor writing lesson notes.';
