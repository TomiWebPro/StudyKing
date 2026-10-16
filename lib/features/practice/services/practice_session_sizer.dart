import 'dart:math' as math;

/// Sizing rules that prevent a practice session from becoming an unbounded
/// marathon when a student has a large backlog of due or banked questions.
///
/// Vision (`agent_must_read.md`):
/// - §87: optimise for retention and mastery, not simple completion.
/// - §100: nudge students to keep learning whilst preventing overwork/stress.
///
/// Without these caps every UI entry into [PracticeSessionScreen] passed
/// `questionCount = <all>.length`, so an accumulated backlog became a single
/// multi-thousand-question session. The first chunk is loaded here; the
/// remainder stays queued (for spaced repetition it simply stays due until
/// answered) and resurfaces on the next session or a load-more continuation.
class PracticeSessionSizer {
  PracticeSessionSizer._();

  /// Default number of questions loaded into a single practice session.
  ///
  /// A sane ceiling that keeps a session bounded while still giving a
  /// meaningful block of practice. The remainder is never lost: it stays
  /// queued for the next session or a load-more continuation.
  static const int defaultSessionQuestionCap = 20;

  /// The number of questions a session should load.
  ///
  /// - Caps at [defaultSessionQuestionCap] (or [cap] when provided) so a
  ///   backlog never becomes a marathon in one sitting.
  /// - [preferredCount] (e.g. from a future count-picker) is honoured when it
  ///   lies below the cap.
  /// - The result is always in the range `[0, total]`.
  static int cappedCount(int total, {int? preferredCount, int? cap}) {
    if (total <= 0) return 0;
    final effectiveCap = cap ?? defaultSessionQuestionCap;
    final desired = preferredCount ?? total;
    return math.min(desired, effectiveCap).clamp(0, total);
  }

  /// The questions left over after the capped chunk — the queued remainder
  /// that stays for the next session rather than being forced into one
  /// sitting. Never negative.
  static int overflowCount(int total, int sessionSize) {
    if (total < 0) return 0;
    final overflow = total - sessionSize;
    return overflow.clamp(0, total);
  }
}
