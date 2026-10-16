import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';

/// Builds a concise, LLM-facing context note describing a student's weak topics
/// and recent lesson history so the live tutor can adapt to the learner's actual
/// progress rather than only the current topic.
///
/// Per AGENTS.md, LLM-facing prompt strings may remain in invariant English
/// (agent_must_read.md §32-45: "adapt explanations to student understanding";
/// §86-96: progress feeds teaching).
///
/// This is a small, pure-logic (no I/O) builder with no constructor
/// dependencies, mirroring the FeedbackAnalyzer pattern of a dedicated,
/// independently-testable analysis class.
class MasteryContextBuilder {
  /// Builds a context note from already-fetched mastery + history data.
  /// Returns `null` when there is nothing notable to surface, so callers can
  /// skip injecting an empty note.
  String? build({
    required List<MasteryState> weakTopics,
    required List<TutorSession> recentSessions,
  }) {
    final buffer = StringBuffer();

    if (weakTopics.isNotEmpty) {
      buffer.writeln('Student mastery context (weak areas to watch):');
      for (final w in weakTopics.take(3)) {
        buffer.writeln('- ${_describeWeakTopic(w)}');
      }
      buffer.writeln();
    }

    // The just-started session is saved with questionsAsked == 0; exclude it so
    // the in-progress lesson never appears as "0/0" history for itself.
    final recent =
        recentSessions.where((s) => s.questionsAsked > 0).take(3).toList();
    if (recent.isNotEmpty) {
      buffer.writeln('Recent lesson history:');
      for (final s in recent) {
        final pct = _percent(s.accuracy);
        buffer.writeln(
          '- ${s.topicTitle}: ${s.questionsCorrect}/${s.questionsAsked} correct ($pct% accuracy), confidence ${s.confidenceRating}/5',
        );
      }
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  String _describeWeakTopic(MasteryState w) {
    final parts = <String>['accuracy ${_percent(w.accuracy)}%'];
    if (w.totalAttempts > 0) parts.add('${w.totalAttempts} attempts');
    if (w.weakSubtopics.isNotEmpty) {
      parts.add('weak in ${w.weakSubtopics.take(2).join(', ')}');
    }
    return '${w.topicId}: ${parts.join(', ')}';
  }

  int _percent(double ratio) => (ratio * 100).round().clamp(0, 100);
}
