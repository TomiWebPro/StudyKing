/// Prompts used to drive LLM-based question variant generation.
///
/// A "variant" is a question that preserves the underlying concept/learning
/// objective of the source question but varies the specific numbers, values,
/// names, or wording so the student must demonstrate genuine understanding
/// rather than memorising a fixed answer. These prompts are LLM-facing and
/// intentionally kept in invariant `en` format (see AGENTS.md i18n rules).
library;

import 'package:studyking/core/data/models/question_model.dart';

/// Builds the generation prompt for [count] concept-preserving, value-varying
/// variants of [source].
///
/// The model is instructed to emit ONLY a JSON array. Each element must contain
/// the fields the variant service needs to reconstruct a [Question]:
///   - `text`: the varied question stem.
///   - `options`: a list of answer choices (empty list for non-choice types).
///   - `correctAnswer`: the answer that matches the varied stem.
///   - `explanation`: a short worked explanation for the variant.
String buildVariantGenerationPrompt({
  required Question source,
  required int count,
}) {
  final buffer = StringBuffer();
  buffer.writeln(
    'You are an expert educator and assessment designer. Your task is to '
    'generate practice VARIANTS of a single question.',
  );
  buffer.writeln();
  buffer.writeln('## Goal');
  buffer.writeln(
    'Produce $count new versions of the question below. Each variant must test '
    'the SAME underlying concept and skill, but must vary the specific numbers, '
    'values, quantities, names, entities, or surface wording so that a student '
    'who merely memorised the original answer cannot answer correctly. Vary the '
    'parameters while keeping the difficulty and learning objective identical.',
  );
  buffer.writeln();
  buffer.writeln('## Strict requirements');
  buffer.writeln('- Do NOT change the question type or the concept being tested.');
  buffer.writeln('- Do NOT reveal the answer inside the question stem.');
  buffer.writeln(
    '- For multiple-choice questions, provide a full `options` list, shuffle '
    'the position of the correct answer, and ensure distractors are plausible.',
  );
  buffer.writeln(
    '- For open-ended/numeric questions, `options` must be an empty list and '
    '`correctAnswer` must be the exact expected answer (use the same units/form '
    'as the source).',
  );
  buffer.writeln('- Keep each `explanation` concise but pedagogically correct.');
  buffer.writeln('- Return $count variants, no more and no fewer.');
  buffer.writeln();
  buffer.writeln('## Source question');
  buffer.writeln('- id: ${source.id}');
  buffer.writeln('- type: ${source.type.name}');
  buffer.writeln('- difficulty: ${source.difficulty}');
  buffer.writeln('- stem: ${source.text}');
  if (source.options.isNotEmpty) {
    buffer.writeln('- options: ${source.options.join(' | ')}');
  }
  if (source.markscheme?.correctAnswer.isNotEmpty == true) {
    buffer.writeln('- original correct answer: ${source.markscheme!.correctAnswer}');
  }
  if (source.explanation?.isNotEmpty == true) {
    buffer.writeln('- original explanation: ${source.explanation}');
  }
  if (source.tags.isNotEmpty) {
    buffer.writeln('- tags: ${source.tags.join(', ')}');
  }
  buffer.writeln();
  buffer.writeln('## Output format');
  buffer.writeln('Return ONLY a JSON array (no markdown, no code fences):');
  buffer.writeln('[');
  buffer.writeln('  {');
  buffer.writeln('    "text": "varied question stem",');
  buffer.writeln('    "options": ["choice A", "choice B", "choice C", "choice D"],');
  buffer.writeln('    "correctAnswer": "the correct choice or value",');
  buffer.writeln('    "explanation": "short worked explanation"');
  buffer.writeln('  }');
  buffer.writeln(']');
  return buffer.toString();
}
