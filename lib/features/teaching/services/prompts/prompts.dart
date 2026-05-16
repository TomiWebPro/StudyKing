import '../conversation_phase.dart';

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

  const ConversationPromptSet({this.version = 1});

  static const ConversationPromptSet defaultTemplates = ConversationPromptSet();

  PromptEntry lessonPlan({
    required String subjectId,
    required String topicTitle,
    required int durationMinutes,
  }) {
    return PromptEntry(
      systemPrompt: lessonPlanSystemPrompt,
      userPrompt: _buildLessonPlanPrompt(
        subjectId: subjectId,
        topicTitle: topicTitle,
        durationMinutes: durationMinutes,
      ),
    );
  }

  PromptEntry tutorMessage({
    required String subjectId,
    required String topicTitle,
    required double adaptivePace,
    required ConversationPhase phase,
  }) {
    return PromptEntry(
      systemPrompt: _buildTutorSystemPrompt(subjectId, topicTitle),
      userPrompt: _buildTutorPrompt(
        subjectId: subjectId,
        topicTitle: topicTitle,
        adaptivePace: adaptivePace,
        phase: phase,
      ),
    );
  }

  PromptEntry summary({
    required String topicTitle,
    required int exerciseCount,
    required int correctCount,
    required double confidenceRating,
    required double adaptivePace,
  }) {
    return PromptEntry(
      systemPrompt: summarySystemPrompt,
      userPrompt: _buildSummaryPrompt(
        topicTitle: topicTitle,
        exerciseCount: exerciseCount,
        correctCount: correctCount,
        confidenceRating: confidenceRating,
        adaptivePace: adaptivePace,
      ),
    );
  }

  PromptEntry evaluateExercise({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
  }) {
    return PromptEntry(
      systemPrompt: evaluationSystemPrompt,
      userPrompt: _buildEvaluationPrompt(
        question: question,
        studentAnswer: studentAnswer,
        subjectId: subjectId,
        topicTitle: topicTitle,
      ),
    );
  }
}

String _buildLessonPlanPrompt({
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
    {"title": "section title", "duration": 10, "type": "explanation|exercise|review|summary|quiz"},
    ...
  ],
  "checkpoints": ["checkpoint1", "checkpoint2"],
  "estimatedDifficulty": 1-5
}
''';
}

const String lessonPlanSystemPrompt =
    'You are a curriculum designer creating lesson plans. Respond only with valid JSON.';

String _buildTutorSystemPrompt(String subjectId, String topicTitle) {
  return 'You are an AI tutor for $subjectId teaching "$topicTitle". Be conversational, warm, and educational.';
}

String _buildTutorPrompt({
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
''';
}

String _buildSummaryPrompt({
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

const String summarySystemPrompt = 'You are a tutor writing lesson notes.';

String _buildEvaluationPrompt({
  required String question,
  required String studentAnswer,
  required String subjectId,
  required String topicTitle,
}) {
  return '''
Evaluate this student answer for the subject "$subjectId" on topic "$topicTitle".

Question: $question

Student Answer: $studentAnswer

Return a JSON object with:
{
  "score": <0.0 to 1.0>,
  "explanation": "<detailed feedback>",
  "partialCredit": <optional 0.0-1.0>,
  "conceptBreakdown": {<optional map of concept name to mastery score 0.0-1.0>}
}
''';
}

const String evaluationSystemPrompt =
    'You are an expert academic evaluator. Return only valid JSON.';

/// Backward-compatible alias for existing references.
typedef PromptTemplates = ConversationPromptSet;
