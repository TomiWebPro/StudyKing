import 'package:studyking/core/utils/logger.dart';

/// Holds the student's explicitly-set active syllabus focus so that the
/// mentor agent can remember which syllabus the student last asked to
/// focus on — overriding the implicit resolution in
/// [MentorContextBuilder._buildSyllabusContext].
///
/// Vision Next-Term §3.1 (`scenario_multisubject_juggling` Step 3):
/// > "Student says 'Switch my focus to Math for the next 2 weeks' — the
/// > mentor should adjust the plan's pacing for Math."
///
/// The [SwitchSyllabusFocusTool] writes to this service; the
/// [MentorContextBuilder] reads it. Both receive the same instance via the
/// Riverpod [syllabusFocusServiceProvider], so a focus set mid-conversation
/// is visible to the next `buildContextPrompt()` call.
class SyllabusFocusService {
  static final Logger _logger = const Logger('SyllabusFocusService');

  String? _subjectId;
  String? _subjectTitle;
  int? _days;

  /// The currently focused subjectId, or null when none has been set.
  String? get subjectId => _subjectId;

  /// The human-readable title of the focused subject, if provided.
  String? get subjectTitle => _subjectTitle;

  /// Optional focus duration in days (e.g. 14 for "next 2 weeks").
  /// Null means indefinite until the student changes it.
  int? get days => _days;

  /// Whether a focus has been explicitly set.
  bool get hasFocus => _subjectId != null && _subjectId!.isNotEmpty;

  /// Set the active syllabus focus.
  ///
  /// [subjectId] must match a [SyllabusGoal.subjectId] from the student's
  /// plan so that [MentorContextBuilder] can resolve the matching goal.
  void setFocus(String subjectId, {String? subjectTitle, int? days}) {
    if (subjectId.isEmpty) {
      _logger.w('setFocus called with empty subjectId');
      return;
    }
    _subjectId = subjectId;
    _subjectTitle = subjectTitle;
    _days = days;
  }

  /// Clear the explicit focus, returning to implicit resolution.
  void clearFocus() {
    _subjectId = null;
    _subjectTitle = null;
    _days = null;
  }
}
