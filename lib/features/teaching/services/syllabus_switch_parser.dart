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
    //   • Explicit verbs: switch / change / select / use / open / go to
    //   • Command-style:  "to [title]", "with [title]", "[title] syllabus"
    //
    // Verbs must match as whole words: raw substring matching would turn
    // "because" into "use", "reopened" into "open", and "exchange" into
    // "change", none of which express switch intent.
    final hasExplicitVerb =
        _switchKeywords.any((k) => _matchesWholeWord(normalized, k));

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
    final titleToken = _tokenPattern(normalizedTitle);
    final patterns = [
      RegExp('\\b(to|with|for|about)\\s+$titleToken'),
      RegExp('$titleToken\\s+(syllabus|subject|topic)'),
      RegExp('$titleToken\\s+(please|now|thanks)'),
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

  /// Regex fragment matching [title] as a standalone token sequence: it
  /// must not be preceded or followed by an ASCII letter or digit. This
  /// keeps "Math" from matching inside "Mathew" or "MathAdvanced", while
  /// titles containing punctuation (e.g. "C++", "Math 101 (Honors)")
  /// still match.
  static String _tokenPattern(String title) {
    return '(?<![a-z0-9])${_escapedMatchPattern(title)}(?![a-z0-9])';
  }

  /// Whether [keyword] occurs in [text] as a whole word or phrase, not as
  /// a substring of a longer word (e.g. "use" inside "because").
  static bool _matchesWholeWord(String text, String keyword) {
    return RegExp('\\b${_escapedMatchPattern(keyword)}\\b').hasMatch(text);
  }

  static String? _matchTitle(String text, List<String> availableTitles) {
    // Match titles as standalone tokens (not inside longer words) and
    // prefer the longest match so "Math Advanced" wins over "Math" when
    // both are available syllabi and the student names the longer one.
    String? bestMatch;
    var bestLength = -1;
    for (final title in availableTitles) {
      final normalizedTitle = title.normalized;
      if (normalizedTitle.isEmpty) continue;
      if (!RegExp(_tokenPattern(normalizedTitle)).hasMatch(text)) continue;
      if (normalizedTitle.length > bestLength) {
        bestMatch = title;
        bestLength = normalizedTitle.length;
      }
    }
    return bestMatch;
  }
}
