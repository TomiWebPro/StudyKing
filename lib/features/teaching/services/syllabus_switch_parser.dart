import 'package:studyking/core/utils/string_extensions.dart';

/// Result of attempting to parse a syllabus-switch intent from a user message.
class SyllabusSwitchResult {
  final bool matched;
  /// The requested syllabus title, or `null` when the student asked to view
  /// all syllabi (e.g. `/syllabus all`).
  final String? syllabusTitle;

  const SyllabusSwitchResult({required this.matched, this.syllabusTitle});
}

/// Parses tutor messages for an explicit intent to switch the active syllabus.
///
/// Supports two forms:
///  * A command: `/syllabus <title>`, `/switchsyllabus <title>`,
///    `/syllabus all` (or empty) to clear the selection.
///  * Natural language: "switch to Math syllabus", "change syllabus to
///    Algebra", "use Science syllabus", etc.
class SyllabusSwitchParser {
  static const List<String> _switchKeywords = [
    'switch',
    'change',
    'use',
    'select',
    'open',
    'go to',
  ];

  SyllabusSwitchParser._();

  static SyllabusSwitchResult parse(
    String message, {
    required List<String> availableTitles,
  }) {
    final normalized = message.normalized.trim();

    final commandResult = _parseCommand(normalized, availableTitles);
    if (commandResult.matched) return commandResult;

    return _parseNaturalLanguage(normalized, availableTitles);
  }

  static SyllabusSwitchResult _parseCommand(
    String normalized,
    List<String> availableTitles,
  ) {
    String rest = normalized;
    if (rest.startsWith('/switchsyllabus')) {
      rest = rest.substring('/switchsyllabus'.length);
    } else if (rest.startsWith('/syllabus')) {
      rest = rest.substring('/syllabus'.length);
    } else {
      return const SyllabusSwitchResult(matched: false);
    }

    rest = rest.replaceFirst(RegExp(r'^[\s:]+'), '');
    if (rest.isEmpty ||
        rest == 'all' ||
        rest == 'all syllabi' ||
        rest == '*') {
      return const SyllabusSwitchResult(matched: true, syllabusTitle: null);
    }

    final matchedTitle = _matchTitle(rest, availableTitles);
    if (matchedTitle != null) {
      return SyllabusSwitchResult(matched: true, syllabusTitle: matchedTitle);
    }
    // Command form but the title was not recognized.
    return const SyllabusSwitchResult(matched: false);
  }

  static SyllabusSwitchResult _parseNaturalLanguage(
    String normalized,
    List<String> availableTitles,
  ) {
    // Natural-language switches always require a known syllabus title to be
    // explicitly mentioned. This eliminates false positives such as:
    //   "this syllabus is hard, but let's continue" (mentions syllabus, no target)
    //   "I love science" (no switch intent, no title)
    //   "Can you open the Math syllabus for review?" (matches 'open' + syllabus;
    //     may be a viewing request rather than a switch — still matched when
    //     a known title is present.)

    final matchedTitle = _matchTitle(normalized, availableTitles);
    if (matchedTitle == null) {
      return const SyllabusSwitchResult(matched: false);
    }

    // There is a known title mentioned.  Confirm switch intent via one of:
    //   • Command-style:  "to [title]", "with [title]", "[title] syllabus"
    //   • Explicit verbs: switch / change / select / use
    final hasExplicitVerb =
        _switchKeywords.any((k) => normalized.contains(k));

    if (hasExplicitVerb) {
      return SyllabusSwitchResult(matched: true, syllabusTitle: matchedTitle);
    }

    // Check for structured phrasing patterns:
    //   "to Math", "with Math", "Math syllabus", "[title] please"
    // NOTE: these are NOT raw strings — the ${...} interpolation must
    // execute to embed the (escaped) title into the pattern. The title
    // is escaped from its normalized form because the haystack
    // (`normalized`) is lowercased and RegExp is case-sensitive.
    final normalizedTitle = matchedTitle.normalized;
    final patterns = [
      RegExp('\\b(to|with|for|about)\\s+${_escapedMatchPattern(normalizedTitle)}\\b'),
      RegExp('${_escapedMatchPattern(normalizedTitle)}\\s+(syllabus|subject|topic)'),
      RegExp('${_escapedMatchPattern(normalizedTitle)}\\s+(please|now|thanks)'),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(normalized)) {
        return SyllabusSwitchResult(matched: true, syllabusTitle: matchedTitle);
      }
    }

    // Title mentioned but no clear switch intent → do not match
    return const SyllabusSwitchResult(matched: false);
  }

  static String _escapedMatchPattern(String title) {
    // Escape regex special characters so title substrings don't break matching
    return title.replaceAllMapped(
      RegExp(r'[.*+?^(){}\[\]\\|\-\$]'),
      (m) => '\\${m.group(0)}',
    );
  }

  static String? _matchTitle(String text, List<String> availableTitles) {
    for (final title in availableTitles) {
      final normalizedTitle = title.normalized;
      if (normalizedTitle.isNotEmpty && text.contains(normalizedTitle)) {
        return title;
      }
    }
    return null;
  }
}
