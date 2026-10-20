import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';

/// Builds a concise, LLM-facing "Current lesson plan" context note from the
/// active pre-built lesson blocks so the live tutor reads prepared artefacts
/// (examples, exercises, analogies, …) instead of synthesising the course from
/// scratch on every turn (docs/vision_next_term.md §4.3:
/// "Live lessons consume pre-built plans, blocks, variants, and knowledge —
/// not raw reasoning from scratch").
///
/// Pure logic, no constructor dependencies — mirrors [MasteryContextBuilder]
/// (`mentor_context_builder.dart`), which is independently unit-tested. Returns
/// `null` when there are no blocks so callers can skip injecting an empty note,
/// exactly like `masteryContext`.
///
/// Per AGENTS.md, the framing here is LLM-facing and invariant English
/// (prompts/tutor notes may remain in `en`).
class LessonPlanContextBuilder {
  /// Upper bound on the number of lesson blocks serialised into the prompt.
  /// Re-uses the `_maxRecentMistakes`-style cap pattern
  /// (mentor_context_builder.dart:128, `.take(...)`) to bound prompt length
  /// and stop the live tutor from drowning in pre-built content
  /// (Vision Next-Term §4.3 "capped to avoid prompt bloat").
  static const int maxBlocks = 5;

  /// Maximum characters of block content surfaced per block. A short snippet is
  /// enough for the tutor to cite pre-built material ("show me the example
  /// from my lesson") without consuming the token budget off-period prep was
  /// meant to save (§4.3 "preparation dominates tokens").
  static const int maxContentChars = 200;

  /// Builds the context note from already-fetched lesson blocks.
  ///
  /// [blocks] is the active lesson's blocks as adopted by [TutorService] —
  /// either the persisted pre-generated blocks (preparation path) or the
  /// freshly converted live plan blocks (§4.3). Returns `null` when there is
  /// nothing to surface.
  String? build({required List<LessonBlock> blocks}) {
    if (blocks.isEmpty) return null;

    final buffer = StringBuffer();
    buffer.writeln(
      'Current lesson plan (consume these pre-built artefacts this lesson):',
    );
    final bounded = blocks.take(maxBlocks).toList();
    for (final b in bounded) {
      final type = b.type.name;
      final section = b.sectionTitle ?? b.chapterTitle;
      buffer.writeln('- Type: $type');
      if (section != null && section.isNotEmpty) {
        buffer.writeln('  Section: $section');
      }
      final snippet = _truncate(b.content, maxContentChars);
      if (snippet.isNotEmpty) {
        buffer.writeln('  Content: $snippet');
      }
    }
    if (blocks.length > maxBlocks) {
      buffer.writeln('- ... and ${blocks.length - maxBlocks} more blocks');
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  String _truncate(String text, int maxLen) {
    final trimmed = text.trim();
    if (trimmed.length <= maxLen) return trimmed;
    return '${trimmed.substring(0, maxLen - 1).trimRight()}\u2026';
  }
}
