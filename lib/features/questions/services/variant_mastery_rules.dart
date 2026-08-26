import 'package:studyking/core/data/models/question_mastery_state_model.dart';

/// Pure rules for aggregating per-variant mastery into a single, concept-level
/// ("base question") mastery verdict.
///
/// Variants are meant to be inter-changeable re-tests of the same concept. The
/// adaptive-practice vision requires a student to prove understanding across
/// *multiple* surface forms before a concept is considered mastered — answering
/// the same fixed question correctly once is not enough. These rules enforce
/// that threshold so spaced repetition and the readiness scorer can treat a
/// variant family as a unit.
///
/// All methods are static and side-effect free so they can be unit tested
/// without Hive or an LLM.
class VariantMasteryRules {
  const VariantMasteryRules._();

  /// Minimum number of *distinct* variant questions a student must have
  /// attempted before a concept can be considered mastered.
  static const int defaultRequiredVariantAttempts = 2;

  /// A variant counts as "passed" when it has at least this many correct
  /// answers recorded.
  static const int defaultRequiredCorrectPerVariant = 1;

  /// A variant counts as attempted when it has at least this many total answers
  /// (correct + incorrect) recorded.
  static const int defaultMinAttemptsPerVariant = 1;

  /// Returns true when the student has demonstrated understanding across enough
  /// distinct variants of the concept.
  ///
  /// [variantMasteries] are the per-variant [QuestionMasteryState]s for one
  /// variant family (the base question and its generated variants).
  static bool isConceptMastered(
    List<QuestionMasteryState> variantMasteries, {
    int requiredVariantAttempts = defaultRequiredVariantAttempts,
    int requiredCorrectPerVariant = defaultRequiredCorrectPerVariant,
    int minAttemptsPerVariant = defaultMinAttemptsPerVariant,
  }) {
    if (variantMasteries.isEmpty) return false;

    final attempted = variantMasteries.where(
      (m) => (m.correctCount + m.incorrectCount) >= minAttemptsPerVariant,
    );
    final passed = attempted.where((m) => m.correctCount >= requiredCorrectPerVariant);

    return attempted.length >= requiredVariantAttempts && passed.isNotEmpty;
  }

  /// Computes a concept-level mastery score in the range [0, 1] by combining the
  /// per-variant [QuestionMasteryState.masteryLevel] values.
  ///
  /// Variants that have never been attempted (masteryLevel 0 and no attempts)
  /// are excluded so a brand-new family is not unfairly averaged down by
  /// variants the student has not seen yet.
  static double conceptMasteryLevel(
    List<QuestionMasteryState> variantMasteries,
  ) {
    final attempted = variantMasteries
        .where((m) => (m.correctCount + m.incorrectCount) > 0)
        .toList();
    if (attempted.isEmpty) return 0.0;
    final sum = attempted.fold<double>(
      0.0,
      (acc, m) => acc + m.masteryLevel,
    );
    return (sum / attempted.length).clamp(0.0, 1.0);
  }

  /// The number of distinct variant questions the student has attempted.
  static int attemptedVariantCount(
    List<QuestionMasteryState> variantMasteries,
  ) {
    return variantMasteries
        .where((m) => (m.correctCount + m.incorrectCount) > 0)
        .length;
  }
}
